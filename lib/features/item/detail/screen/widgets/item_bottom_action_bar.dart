import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../bottom_sheet_buy_now_input/screen/bottom_sheet_buy_now_input.dart';
import '../../../bottom_sheet_buy_now_input/viewmodel/buy_now_input_viewmodel.dart';
import '../../../bottom_sheet_price_Input/screen/price_input_screen.dart';
import '../../../bottom_sheet_price_Input/viewmodel/price_input_viewmodel.dart';
import '../../model/item_detail_entity.dart';

class ItemBottomActionBar extends StatefulWidget {
  const ItemBottomActionBar({
    required this.item,
    required this.isMyItem,
    super.key,
  });

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
          .from('auctions')
          .select('last_bid_user_id')
          .eq('item_id', widget.item.itemId)
          .eq('round', 1)
          .maybeSingle();

      if (!mounted || row == null) return;

      final String? lastBidUserId = row['last_bid_user_id']?.toString();

      setState(() {
        _isTopBidder = lastBidUserId != null && lastBidUserId == user.id;
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

    const disabledStatusesForBuyNow = {
      300,
      311,
      321,
      322,
      323,
    };
    final bool showBuyNow =
        widget.item.buyNowPrice > 0 &&
        !disabledStatusesForBuyNow.contains(_statusCode);

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
            Expanded(child: _buildBidButton()),
            if (showBuyNow) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildBuyNowButton()),
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
        statusCode == 321 || statusCode == 322 || statusCode == 323;

    final bool isAuctionPending = statusCode == 300;
    final bool isAuctionActive = statusCode == 310;
    final bool isBuyNowInProgress = statusCode == 311;
    final bool isBuyNowCompleted = statusCode == 322;

    final bool showBidButton =
        !isAuctionEnded &&
        isAuctionActive &&
        !isTopBidder &&
        !isBuyNowInProgress;

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

    // 즉시 구매 진행 중(1006)인 경우
    // - 즉시 구매를 건 사용자(현재 최고 입찰자)는 '결제하러 가기' 버튼 노출
    // - 그 외 사용자는 안내 문구만 노출
    if (isBuyNowInProgress && !isBuyNowCompleted) {
      if (isTopBidder) {
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

      // 다른 사용자는 결제 대기 안내 문구만 표시
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
            '즉시 구매 결제 대기중입니다',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TopBidderTextColor,
            ),
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
      reason = '최고 입찰자입니다';
    } else {
      // 2) 상태 코드별 상세 사유
      switch (statusCode) {
        case 300:
          reason = '경매가 아직 시작되지 않았습니다';
          break;
        case 321:
        case 323:
          reason = '경매가 종료되었습니다.';
          break;
        case 311:
          reason = '즉시 구매 결제 대기중입니다';
          break;
        case 322:
          reason = '즉시 구매되었습니다';
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.7)),
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
