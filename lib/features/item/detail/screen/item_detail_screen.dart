import 'dart:async';

import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:bidbird/features/item/price_Input/screen/price_input_screen.dart';
import 'package:bidbird/features/item/price_Input/viewmodel/price_input_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../report/ui/report_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late final SupabaseClient _supabase;
  RealtimeChannel? _bidStatusChannel;
  RealtimeChannel? _itemsChannel;
  RealtimeChannel? _bidLogChannel;

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseManager.shared.supabase;
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    if (_bidStatusChannel != null) _supabase.removeChannel(_bidStatusChannel!);
    if (_itemsChannel != null) _supabase.removeChannel(_itemsChannel!);
    if (_bidLogChannel != null) _supabase.removeChannel(_bidLogChannel!);
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    // bid_status 테이블 실시간 구독
    _bidStatusChannel = _supabase.channel('bid_status_${widget.itemId}');
    _bidStatusChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bid_status',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'item_id',
            value: widget.itemId,
          ),
          callback: (payload) {
            if (mounted) setState(() {});
          },
        )
        .subscribe();

    // items 테이블 실시간 구독 (현재가 변경 감지)
    _itemsChannel = _supabase.channel('items_${widget.itemId}');
    _itemsChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'items',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.itemId,
          ),
          callback: (payload) {
            if (mounted) setState(() {});
          },
        )
        .subscribe();

    // bid_log 테이블 실시간 구독 (참여 입찰 수 변경 감지)
    _bidLogChannel = _supabase.channel('bid_log_${widget.itemId}');
    _bidLogChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert, // 입찰은 insert만 발생
          schema: 'public',
          table: 'bid_log',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'item_id',
            value: widget.itemId,
          ),
          callback: (payload) {
            if (mounted) setState(() {});
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ItemDetail?>(
      future: _loadItemDetail(widget.itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text('매물 정보를 불러올 수 없습니다.', style: TextStyle(fontSize: 14)),
            ),
          );
        }

        final ItemDetail item = snapshot.data!;

        // 현재 로그인 유저와 판매자 비교해서 내 매물 여부 판단
        final supabase = SupabaseManager.shared.supabase;
        final currentUser = supabase.auth.currentUser;
        final bool isMyItem =
            currentUser != null && currentUser.id == item.sellerId;

        return Scaffold(
          backgroundColor: itemDetailBackgroundColor,
          appBar: AppBar(title: const Text('상세 보기')),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ItemImageSection(item: item),
                      const SizedBox(height: 8),
                      _ItemMainInfoSection(item: item),
                      const SizedBox(height: 16),
                      _ItemDescriptionSection(item: item),
                    ],
                  ),
                ),
              ),
              _BottomActionBar(item: item, isMyItem: isMyItem),
            ],
          ),
        );
      },
    );
  }
}

Future<ItemDetail?> _loadItemDetail(String itemId) async {
  final supabase = SupabaseManager.shared.supabase;

  final List<dynamic> result = await supabase
      .from('items')
      .select()
      .eq('id', itemId)
      .limit(1);

  if (result.isEmpty) {
    return null;
  }

  final row = result.first;

  // created_at + auction_duration_hours 로 종료 시각 계산
  final createdAtRaw = row['created_at']?.toString();
  final createdAt = createdAtRaw != null
      ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
      : DateTime.now();

  final durationHours = (row['auction_duration_hours'] as int?) ?? 24;
  final finishTime = createdAt.add(Duration(hours: durationHours));

  final String sellerId = row['seller_id']?.toString() ?? '';
  String sellerTitle = '';

  if (sellerId.isNotEmpty) {
    try {
      // users 테이블에서 모든 필드 조회
      final userResponse = await supabase
          .from('users')
          .select()
          .eq('id', sellerId)
          .single();

      // 닉네임 필드 확인
      String? nickname = userResponse['nick_name']?.toString().trim();

      if (nickname != null && nickname.isNotEmpty) {
        sellerTitle = nickname;
      } else {
        sellerTitle = '미지정 사용자';
      }

      // items 테이블 업데이트
      try {
        await supabase
            .from('items')
            .update({'seller_name': sellerTitle})
            .eq('id', itemId);
      } catch (e) {
        debugPrint('Failed to update seller_name for itemId=$itemId: $e');
      }
    } catch (e) {
      // users 테이블 조회 실패 시 items 테이블의 seller_name 사용
      sellerTitle = row['seller_name']?.toString() ?? '미지정 사용자';
    }
  } else {
    sellerTitle = '알 수 없는 판매자';
  }

  // item_images 테이블에서 이미지 URL 가져오기 (썸네일 제외)
  final List<String> images = [];

  try {
    final imageRows = await supabase
        .from('item_images')
        .select('image_url')
        .eq('item_id', itemId)
        .order('sort_order', ascending: true);

    for (final Map<String, dynamic> row in imageRows) {
      final imageUrl = row['image_url']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        images.add(imageUrl);
      }
    }
  } catch (e) {
    debugPrint('Failed to load item images for itemId=$itemId: $e');
  }

  // bid_log 테이블에서 참여 입찰 수 조회
  int biddingCount = 0;
  try {
    final countResponse = await supabase
        .from('bid_log')
        .select('id')
        .eq('item_id', itemId)
        .count(CountOption.exact);

    biddingCount = countResponse.count;
  } catch (e) {
    // count 쿼리가 실패하면 기존 방식(items 테이블의 bidding_count) 사용하거나 0으로 설정
    biddingCount = (row['bidding_count'] as int?) ?? 0;
  }

  // 입찰 최소 호가 규칙 적용
  final currentPrice = (row['current_price'] as int?) ?? 0;
  int minBidStep;

  if (currentPrice <= 100000) {
    // 100,000원 이하일 경우 최소 호가는 1,000원으로 고정
    minBidStep = 1000;
  } else {
    // 100,001원 이상일 경우 마지막 두 자리 제거
    final priceStr = currentPrice.toString();
    if (priceStr.length >= 3) {
      minBidStep = int.parse(priceStr.substring(0, priceStr.length - 2));
    } else {
      minBidStep = 1000; // 최소값 보장
    }
  }


  return ItemDetail(
    itemId: row['id']?.toString() ?? itemId,
    sellerId: sellerId,
    itemTitle: row['title']?.toString() ?? '',
    itemImages: images,
    finishTime: finishTime,
    sellerTitle: sellerTitle,
    buyNowPrice: (row['buy_now_price'] as int?) ?? 0,
    biddingCount: biddingCount,
    itemContent: row['description']?.toString() ?? '',
    currentPrice: currentPrice,
    bidPrice: minBidStep, // 계산된 최소 호가 사용
    sellerRating: (row['seller_rating'] as num?)?.toDouble() ?? 0.0,
    sellerReviewCount: (row['seller_review_count'] as int?) ?? 0,
  );
}

class _ItemImageSection extends StatefulWidget {
  const _ItemImageSection({required this.item});

  final ItemDetail item;

  @override
  State<_ItemImageSection> createState() => _ItemImageSectionState();
}

class _ItemImageSectionState extends State<_ItemImageSection> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = widget.item.itemImages.isNotEmpty;
    final images = hasImages ? widget.item.itemImages : <String>[];

    return SizedBox(
      height: 280,
      child: Stack(
        children: [
          if (hasImages && images.isNotEmpty)
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: double.infinity,
                  color: itemDetailImageBackgroundColor,
                  child: Image.network(
                    images[index],
                    width: double.infinity,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text(
                          '상품 사진',
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    },
                  ),
                );
              },
            )
          else
            Container(
              width: double.infinity,
              color: itemDetailImageBackgroundColor,
              child: const Center(
                child: Text(
                  '상품 사진',
                  style: TextStyle(color: itemDetailSecondaryTextColor),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: itemDetailAccentRedColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '잔여 시간 ${_formatRemainingTime(widget.item.finishTime)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (hasImages && images.length > 1)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  images.length,
                  (index) => _buildDot(isActive: index == _currentPage),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDot({required bool isActive}) {
    return Container(
      width: 6,
      height: 6,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isActive ? itemDetailDotActiveColor : itemDetailDotInactiveColor,
      ),
    );
  }
}

class _ItemMainInfoSection extends StatelessWidget {
  const _ItemMainInfoSection({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: itemDetailBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.buyNowPrice > 0
                          ? '즉시 구매가 ${_formatPrice(item.buyNowPrice)}원'
                          : '즉시 구매 없음',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.buyNowPrice > 0
                            ? itemDetailBuyNowPriceColor
                            : itemDetailSecondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReportScreen(), // 신고 UI 이동
                    ),
                  );
                },
                child: Text(
                  '신고',
                  style: TextStyle(
                    fontSize: 12,
                    color: itemDetailReportTextColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: itemDetailBackgroundColor,
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: [
                BoxShadow(
                  color: itemDetailShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '현재 입찰가',
                        style: TextStyle(
                          fontSize: 12,
                          color: itemDetailSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatPrice(item.currentPrice)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        '참여 입찰',
                        style: TextStyle(
                          fontSize: 12,
                          color: itemDetailSecondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.biddingCount}건',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: itemDetailBackgroundColor,
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: [
                BoxShadow(
                  color: itemDetailShadowColor,
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: itemDetailSellerAvatarBackgroundColor,
                  child: Icon(Icons.person, color: itemDetailSellerAvatarIconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.sellerTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: itemDetailSellerRatingStarColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.sellerRating.toStringAsFixed(1)} (${item.sellerReviewCount})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: itemDetailSecondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    if (item.sellerId.isEmpty) return;
                    context.push('/user/${item.sellerId}');
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: itemDetailSellerProfileBorderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    minimumSize: const Size(0, 0),
                  ),
                  child: const Text(
                    '프로필 보기',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: itemDetailSellerProfileTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDescriptionSection extends StatelessWidget {
  const _ItemDescriptionSection({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      color: itemDetailBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 설명',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            item.itemContent,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatefulWidget {
  const _BottomActionBar({required this.item, required this.isMyItem});

  final ItemDetail item;
  final bool isMyItem;

  @override
  State<_BottomActionBar> createState() => _BottomActionBarState();
}

class _BottomActionBarState extends State<_BottomActionBar> {
  bool _isFavorite = false;
  bool _isTopBidder = false;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
    _checkTopBidder();
  }

  Future<void> _loadFavoriteState() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final List<dynamic> rows = await supabase
          .from('favorites')
          .select('id')
          .eq('item_id', widget.item.itemId)
          .eq('user_id', user.id)
          .limit(1);

      if (!mounted) return;
      setState(() {
        _isFavorite = rows.isNotEmpty;
      });
    } catch (e) {
      debugPrint(
        'Failed to load favorite state for itemId=${widget.item.itemId}: $e',
      );
    }
  }

  Future<void> _checkTopBidder() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 해당 아이템의 최고 입찰 기록 조회
      final List<dynamic> rows = await supabase
          .from('bid_log')
          .select('bid_user, bid_price')
          .eq('item_id', widget.item.itemId)
          .order('bid_price', ascending: false)
          .limit(1);

      if (!mounted) return;
      if (rows.isNotEmpty) {
        final topBidUserId = rows[0]['bid_user']?.toString() ?? '';
        setState(() {
          _isTopBidder = topBidUserId == user.id;
        });
      }
    } catch (e) {
      debugPrint(
        'Failed to check top bidder for itemId=${widget.item.itemId}: $e',
      );
    }
  }

  Future<void> _toggleFavorite() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (_isFavorite) {
        await supabase
            .from('favorites')
            .delete()
            .eq('item_id', widget.item.itemId)
            .eq('user_id', user.id);
      } else {
        await supabase.from('favorites').insert(<String, dynamic>{
          'item_id': widget.item.itemId,
          'user_id': user.id,
        });
      }

      if (!mounted) return;
      setState(() {
        _isFavorite = !_isFavorite;
      });
    } catch (e) {
      debugPrint(
        'Failed to toggle favorite for itemId=${widget.item.itemId}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: itemDetailBackgroundColor,
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (!widget.isMyItem) ...[
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: _toggleFavorite,
                        padding: EdgeInsets.zero,
                        splashRadius: 24,
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 24,
                          color: itemDetailAccentRedColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 입찰하기 버튼 또는 최고 입찰자 표시
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: _isTopBidder
                            ? Container(
                                decoration: BoxDecoration(
                                  color: itemDetailTopBidderBackgroundColor,
                                  borderRadius: BorderRadius.circular(8.7),
                                  border: Border.all(
                                    color: itemDetailTopBidderBorderColor,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    '최고 입찰자입니다',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: itemDetailTopBidderTextColor,
                                    ),
                                  ),
                                ),
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.white,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(defaultRadius),
                                      ),
                                    ),
                                    builder: (context) {
                                      return ChangeNotifierProvider<
                                        PriceInputViewModel
                                      >(
                                        create: (_) => PriceInputViewModel(),
                                        child: BidBottomSheet(
                                          itemId: widget.item.itemId,
                                          currentPrice:
                                              widget.item.currentPrice,
                                          bidUnit: widget.item.bidPrice,
                                          buyNowPrice: widget.item.buyNowPrice,
                                        ),
                                      );
                                    },
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: blueColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.7),
                                  ),
                                ),
                                child: Text(
                                  '입찰하기',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: blueColor,
                                  ),
                                ),
                              ),
                      ),
                    ),

                    if (widget.item.buyNowPrice > 0) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: 즉시 구매 플로우 연결
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: blueColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.7),
                              ),
                            ),
                            child: const Text(
                              '즉시 구매',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRemainingTime(DateTime finishTime) {
  final diff = finishTime.difference(DateTime.now());
  if (diff.isNegative) {
    return '00:00';
  }
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String _formatPrice(int price) {
  // 콤마 포맷팅
  final buffer = StringBuffer();
  final text = price.toString();
  for (int i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}
