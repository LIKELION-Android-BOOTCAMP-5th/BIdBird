import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/features/item/detail/data/datasource/item_detail_datasource.dart';
import 'package:flutter/material.dart';

class ItemDetailBidHistoryBottomSheet extends StatefulWidget {
  const ItemDetailBidHistoryBottomSheet({
    required this.itemId,
    super.key,
  });

  final String itemId;

  @override
  State<ItemDetailBidHistoryBottomSheet> createState() => _ItemDetailBidHistoryBottomSheetState();
}

enum _BidHistoryState {
  initial,
  loading,
  loaded,
  error,
  empty,
}

class _ItemDetailBidHistoryBottomSheetState extends State<ItemDetailBidHistoryBottomSheet> {
  _BidHistoryState _state = _BidHistoryState.initial;
  List<Map<String, dynamic>> _bidHistory = [];
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const int _pageSize = 20;
  final ItemDetailDatasource _datasource = ItemDetailDatasource();

  @override
  void initState() {
    super.initState();
    _loadBidHistory();
  }

  Future<void> _loadBidHistory() async {
    if (_state == _BidHistoryState.loading) return;

    setState(() {
      _state = _BidHistoryState.loading;
    });

    try {
      final bids = await _datasource.fetchBidHistory(widget.itemId);
      
      // 가격이 0원인 입찰은 필터링
      final filteredBids = bids.where((bid) {
        final dynamic rawPrice = bid['price'];
        if (rawPrice == null) return false;
        if (rawPrice is num) {
          return rawPrice != 0;
        }
        final parsed = int.tryParse(rawPrice.toString());
        return parsed != null && parsed != 0;
      }).toList();

      if (mounted) {
        setState(() {
          _bidHistory = filteredBids;
          _state = filteredBids.isEmpty
              ? _BidHistoryState.empty
              : _BidHistoryState.loaded;
          _hasMore = filteredBids.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = _BidHistoryState.error;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _isLoadingMore || _state != _BidHistoryState.loaded) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // 실제로는 페이지네이션을 지원하는 API가 필요하지만,
      // 현재는 전체 데이터를 한 번에 가져오므로 더보기 기능은 제한적
      // 추후 API가 페이지네이션을 지원하면 구현
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _getBidTypeText(int? code) {
    switch (code) {
      case 431:
        return '자동';
      case 410:
      case 411:
      case 430:
        return '일반';
      default:
        return '일반';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 28,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(height: 16),
            // Title
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '입찰 내역',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF191F28), // Primary Text
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Content
            Flexible(
              child: _buildContent(),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _BidHistoryState.initial:
      case _BidHistoryState.loading:
        return _buildSkeletonList();
      case _BidHistoryState.error:
        return _buildErrorState();
      case _BidHistoryState.empty:
        return _buildEmptyState();
      case _BidHistoryState.loaded:
        return _buildBidList();
    }
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6), // Subtle Gray Fill
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6), // Subtle Gray Fill
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 70,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6), // Subtle Gray Fill
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6), // Subtle Gray Fill
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Color(0xFF9CA3AF), // Tertiary
              ),
              const SizedBox(height: 16),
              const Text(
                '입찰 내역을 불러올 수 없습니다',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7684), // Secondary
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadBidHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3182F6), // Primary Blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('재시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Center(
          child: const Text(
            '입찰 내역이 없습니다',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF6B7684), // Secondary
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidList() {
    return ListView.builder(
      shrinkWrap: false,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _bidHistory.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _bidHistory.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final bid = _bidHistory[index];
        final price = bid['price']?.toString() ?? '0';
        final createdAtRaw = bid['created_at']?.toString();
        final relative = formatRelativeTime(createdAtRaw);
        final int code = (bid['auction_log_code'] as int?) ?? 0;
        final typeText = _getBidTypeText(code);
        final bidIndex = _bidHistory.length - index; // 역순으로 표시
        final userName = bid['user_name']?.toString() ?? '익명 참여자';

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4F6), // Subtle Gray Fill
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 순번 배지
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$bidIndex',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3182F6), // Primary Blue
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 금액과 참여자 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 금액
                      Text(
                        '${formatPrice(int.tryParse(price) ?? 0)}원',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF191F28), // Primary Text
                        ),
                      ),
                      const SizedBox(height: 4),
                      // 참여자 정보
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7684), // Secondary Text
                        ),
                      ),
                    ],
                  ),
                ),
                // 시간
                Text(
                  relative,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7684), // Secondary Text
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

