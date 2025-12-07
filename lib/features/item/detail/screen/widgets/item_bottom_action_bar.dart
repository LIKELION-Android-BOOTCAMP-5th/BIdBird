import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/screen/bottom_sheet_buy_now_input.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/viewmodel/buy_now_input_viewmodel.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:bidbird/features/item/bottom_sheet_price_Input/screen/price_input_screen.dart';
import 'package:bidbird/features/item/bottom_sheet_price_Input/viewmodel/price_input_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemBottomActionBar extends StatefulWidget {
  const ItemBottomActionBar({required this.item, required this.isMyItem, super.key});

  final ItemDetail item;
  final bool isMyItem;

  @override
  State<ItemBottomActionBar> createState() => _ItemBottomActionBarState();
}

class _ItemBottomActionBarState extends State<ItemBottomActionBar> {
  bool _isFavorite = false;
  bool _isTopBidder = false;
  int? _statusCode;
  bool _isBidRestricted = false;

  @override
  void initState() {
    super.initState();
    _statusCode = widget.item.statusCode;
    _loadFavoriteState();
    _checkTopBidder();
    _checkBidRestriction();
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

  Future<void> _checkBidRestriction() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final row = await supabase
          .from('bid_restriction')
          .select('is_blocked')
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted || row == null) return;

      final bool isBlocked = row['is_blocked'] as bool? ?? false;

      setState(() {
        _isBidRestricted = isBlocked;
      });
    } catch (e) {
      debugPrint('Failed to check bid restriction: $e');
    }
  }

  Future<void> _checkTopBidder() async {
    final supabase = SupabaseManager.shared.supabase;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final row = await supabase
          .from('bid_status')
          .select('current_highest_bidder, int_code')
          .eq('item_id', widget.item.itemId)
          .maybeSingle();

      if (!mounted || row == null) return;

      final String? currentHighest =
          row['current_highest_bidder']?.toString();

      setState(() {
        _isTopBidder = currentHighest != null && currentHighest == user.id;
      });
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

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }
    } catch (e) {
      debugPrint(
        'Failed to toggle favorite for itemId=${widget.item.itemId}: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMyItem = widget.isMyItem;
    final isBidRestricted = _isBidRestricted;

    // 즉시 구매 버튼 노출 여부 (상태 + 가격 기준)
    // 1001: 경매 대기, 1006: 즉시 구매 진행 중, 1007: 즉시 구매 완료,
    // 1008/1009/1010: 경매 종료, 1011: 거래 정지
    const disabledStatusesForBuyNow = {1001, 1006, 1007, 1008, 1009, 1010, 1011};
    final bool showBuyNow =
        widget.item.buyNowPrice > 0 && !disabledStatusesForBuyNow.contains(_statusCode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(defaultRadius),
          topRight: Radius.circular(defaultRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // 결제 실패 3회 이상으로 입찰 제한된 경우: 안내 문구만 전체 폭으로 노출 (하트 없음)
          if (!isMyItem && isBidRestricted) ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: BackgroundColor,
                  borderRadius: BorderRadius.circular(8.7),
                  border: Border.all(color: BorderColor),
                ),
                child: const Center(
                  child: Text(
                    '결제 3회 이상 실패하여 입찰이 제한되었습니다.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ]

          // 일반 사용자: 하트 + 입찰/즉시구매 버튼
          else if (!isMyItem) ...[
            _buildFavoriteButton(),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBidButton(),
            ),
            if (showBuyNow) ...[
              const SizedBox(width: 8),
              Expanded(
                child: _buildBuyNowButton(),
              ),
            ],
          ] else ...[
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: BackgroundColor,
                  borderRadius: BorderRadius.circular(8.7),
                  border: Border.all(color: BorderColor),
                ),
                child: const Center(
                  child: Text(
                    '내 매물은 입찰이 불가능합니다',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: TopBidderTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFavoriteButton() {
    return InkWell(
      onTap: _toggleFavorite,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: BorderColor),
        ),
        child: Icon(
          _isFavorite ? Icons.favorite : Icons.favorite_border,
          color: _isFavorite ? Colors.red : iconColor,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildBidButton() {
    final bool isTopBidder = _isTopBidder;
    final int statusCode = _statusCode ?? 0;

    final bool isAuctionEnded =
        statusCode == 1008 || statusCode == 1009 || statusCode == 1010; // 경매 종료
    final bool isAuctionActive =
        statusCode == 1002 ||
        statusCode == 1003 ||
        statusCode == 1005;
    final bool isBuyNowInProgress = statusCode == 1006;
    final bool isBuyNowCompleted = statusCode == 1007;

    final bool showBidButton =
        !isAuctionEnded && isAuctionActive && !isTopBidder && !isBuyNowInProgress;

    if (isAuctionEnded) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(8.7),
          border: Border.all(color: BorderColor),
        ),
        child: const Center(
          child: Text(
            '경매가 종료되었습니다.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

    // 즉시 구매 진행 중(1006)인 경우에는 최고 입찰자 여부와 상관없이 결제 버튼을 우선 노출
    if (isBuyNowInProgress && !isBuyNowCompleted) {
      return ElevatedButton(
        onPressed: () {
          debugPrint('[ItemBottomActionBar] 결제하러 가기 버튼 탭');
          // TODO: 결제 화면으로 이동하는 로직 연동
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: blueColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.7),
          ),
        ),
        child: const Text(
          '결제하러 가기',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    }

    if (isBuyNowCompleted) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(8.7),
          border: Border.all(color: BorderColor),
        ),
        child: const Center(
          child: Text(
            '즉시 구매되었습니다',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
          ),
        ),
      );
    }

    if (showBidButton) {
      return OutlinedButton(
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
      );
    }

    // 입찰이 비활성화된 경우: 이유를 버튼 형태로 표시
    String reason;

    // 1) 이미 최고 입찰자인 경우
    if (isTopBidder) {
      reason = '이미 이 상품의 최고 입찰자입니다';
    } else {
      // 2) 상태 코드별 상세 사유
      switch (statusCode) {
        case 1001: // 경매 대기
          reason = '경매가 아직 시작되지 않았습니다';
          break;
        case 1008: // 경매 종료 - 즉시 구매 실패
        case 1009: // 경매 종료 - 낙찰
        case 1010: // 경매 종료 - 유찰
          reason = '경매가 종료되었습니다.';
          break;
        case 1006: // 즉시 구매 진행 중
          reason = '즉시 구매 중인 상품입니다';
          break;
        case 1007: // 즉시 구매 완료
          reason = '즉시 구매가 완료된 상품입니다';
          break;
        case 1011: // 거래 정지
          reason = '거래가 정지된 상품입니다';
          break;
        case 0: // 상태 코드 로딩 실패 등
          reason = '상품 상태 정보를 불러오지 못했습니다. 잠시 후 다시 시도해주세요';
          break;
        default:
          reason = '현재 입찰할 수 없습니다';
          break;
      }
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: BackgroundColor,
        borderRadius: BorderRadius.circular(8.7),
        border: Border.all(color: BorderColor),
      ),
      child: Center(
        child: Text(
          reason,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: TopBidderTextColor,
          ),
        ),
      ),
    );
  }

  Widget _buildBuyNowButton() {
    return ElevatedButton(
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
            return ChangeNotifierProvider<BuyNowInputViewModel>(
              create: (_) => BuyNowInputViewModel(),
              child: BuyNowInputBottomSheet(
                itemId: widget.item.itemId,
                buyNowPrice: widget.item.buyNowPrice,
              ),
            );
          },
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: blueColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.7),
        ),
      ),
      child: const Text(
        '즉시 구매하기',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
