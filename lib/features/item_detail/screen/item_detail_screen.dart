import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/features/item_detail/data/item_detail_data.dart';
import 'package:bidbird/features/price_Input/price_Input_screen/price_input_screen.dart';
import 'package:bidbird/features/price_Input/price_Input_viewmodel/price_input_viewmodel.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../report/ui/report_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    // TODO: 이후에는 실제 item 데이터를 인자로 받아서 사용
    debugPrint('[ItemDetailScreen] build 호출됨, itemId=$itemId');

    return FutureBuilder<ItemDetail?>(
      future: _loadItemDetail(itemId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(
              child: Text(
                '매물 정보를 불러올 수 없습니다.',
                style: TextStyle(fontSize: 14),
              ),
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
          backgroundColor: const Color(0xffF5F6FA),
          appBar: AppBar(
            // Todo: 나중에 공통 AppBar 컴포넌트로 교체 예정
            title: const Text('상세 보기'),
          ),
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
              _BottomActionBar(
                item: item,
                isMyItem: isMyItem,
              ),
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

  final Map<String, dynamic> row = result.first as Map<String, dynamic>;

  // created_at + auction_duration_hours 로 종료 시각 계산
  final createdAtRaw = row['created_at']?.toString();
  final createdAt = createdAtRaw != null
      ? DateTime.tryParse(createdAtRaw) ?? DateTime.now()
      : DateTime.now();

  final durationHours = (row['auction_duration_hours'] as int?) ?? 24;
  final finishTime = createdAt.add(Duration(hours: durationHours));

  final String sellerId = row['seller_id']?.toString() ?? '';
  String sellerTitle = row['seller_name']?.toString() ?? '';

  // seller_name 이 비어 있고 sellerId 가 있으면 users 테이블에서 이름을 한 번 더 조회
  if (sellerTitle.isEmpty && sellerId.isNotEmpty) {
    try {
      final userRow = await supabase
          .from('users')
          .select('nickname, name')
          .eq('id', sellerId)
          .maybeSingle();

      if (userRow is Map<String, dynamic>) {
        sellerTitle = (userRow['nickname']?.toString() ?? '')
            .isNotEmpty
            ? userRow['nickname'].toString()
            : (userRow['name']?.toString() ?? '');
      }
    } catch (e, st) {
      debugPrint('[ItemDetail] load seller name error: $e\n$st');
    }
  }

  // item_images 테이블에서 이미지 URL 가져오기 (썸네일 제외)
  final List<String> images = [];
  
  try {
    final imageRows = await supabase
        .from('item_images')
        .select('image_url')
        .eq('item_id', itemId)
        .order('sort_order', ascending: true);
    
    if (imageRows is List) {
      for (final raw in imageRows) {
        final row = raw as Map<String, dynamic>;
        final imageUrl = row['image_url']?.toString();
        if (imageUrl != null && imageUrl.isNotEmpty) {
          images.add(imageUrl);
        }
      }
    }
  } catch (e, st) {
    debugPrint('[ItemDetail] load images error: $e\n$st');
  }

  return ItemDetail(
    itemId: row['id']?.toString() ?? itemId,
    sellerId: sellerId,
    itemTitle: row['title']?.toString() ?? '',
    itemImages: images,
    finishTime: finishTime,
    sellerTitle: sellerTitle,
    buyNowPrice: (row['buy_now_price'] as int?) ?? 0,
    biddingCount: (row['bidding_count'] as int?) ?? 0,
    itemContent: row['description']?.toString() ?? '',
    currentPrice: (row['current_price'] as int?) ?? 0,
    bidPrice: (row['bid_price'] as int?) ?? 0,
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
                  color: Colors.grey[200],
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
              color: Colors.grey[200],
              child: const Center(
                child: Text(
                  '상품 사진',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
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
        color: isActive ? Colors.black : Colors.grey[400],
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
        color: Colors.white,
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
                      '즉시 구매가 ₩${_formatPrice(item.buyNowPrice)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: blueColor,
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
                    color: Colors.grey[600],
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
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
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₩${_formatPrice(item.currentPrice)}',
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
                          color: Colors.grey,
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(defaultRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.orange,
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                  ),
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
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item.sellerRating.toStringAsFixed(1)} (${item.sellerReviewCount})',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    // TODO: 실제 sellerId로 교체
                    if (item.sellerId.isEmpty) return;
                    context.push('/user/${item.sellerId}');
                  },
                  style: OutlinedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: BorderSide(color: Colors.grey[300]!),
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
                      color: Colors.black87,
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
      color: const Color(0xffF5F6FA),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 설명',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.itemContent,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
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

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
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
    } catch (e, st) {
      debugPrint('[Favorite] load error: $e\n$st');
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
    } catch (e, st) {
      debugPrint('[Favorite] toggle error: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xffF5F6FA),
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
                          _isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 24,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
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
                                return ChangeNotifierProvider<PriceInputViewModel>(
                                  create: (_) => PriceInputViewModel(),
                                  child: BidBottomSheet(
                                    itemId: widget.item.itemId,
                                    currentPrice: widget.item.currentPrice,
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
                            '바로 구매',
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

