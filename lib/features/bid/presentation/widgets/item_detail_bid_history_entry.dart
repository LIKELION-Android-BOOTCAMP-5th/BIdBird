import 'dart:async';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_time_utils.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemDetailBidHistoryEntry extends StatefulWidget {
  const ItemDetailBidHistoryEntry({required this.item, super.key});

  final ItemDetail item;

  @override
  State<ItemDetailBidHistoryEntry> createState() =>
      _ItemDetailBidHistoryEntryState();
}

enum _BidHistoryState { initial, loading, loaded, error, empty }

class _ItemDetailBidHistoryEntryState
    extends State<ItemDetailBidHistoryEntry> {
  _BidHistoryState _state = _BidHistoryState.initial;
  List<BidHistoryItem> _bidHistory = [];
  final bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // build가 완료된 후 입찰 내역 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadBidHistory();
      }
    });
  }

  Future<void> _loadBidHistory() async {
    if (_state == _BidHistoryState.loading) return;

    if (!mounted) return;

    setState(() {
      _state = _BidHistoryState.loading;
    });

    try {
      // ViewModel에서 입찰 내역 가져오기 (ViewModel은 항상 제공됨)
      final viewModel = context.read<ItemDetailViewModel>();
      List<BidHistoryItem> bids = [];

      if (viewModel.bidHistory.isNotEmpty) {
        bids = viewModel.bidHistory;
      } else {
        // ViewModel에 없으면 ViewModel을 통해 로드
        await viewModel.loadBidHistory();
        bids = viewModel.bidHistory;
      }

      if (!mounted) return;

      // 가격이 0원인 입찰은 필터링
      final filteredBids = bids.where((bid) => bid.price != 0).toList();

      if (mounted) {
        setState(() {
          _bidHistory = filteredBids;
          _state = filteredBids.isEmpty
              ? _BidHistoryState.empty
              : _BidHistoryState.loaded;
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

  @override
  Widget build(BuildContext context) {
    return _buildContent();
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
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          key: ValueKey('skeleton_$index'),
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 70,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            const Text(
              '입찰 내역을 불러올 수 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7684),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadBidHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('재시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 80),
        child: Text(
          '입찰 내역이 없습니다',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF6B7684),
          ),
        ),
      ),
    );
  }

  Widget _buildBidList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _bidHistory.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _bidHistory.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final bid = _bidHistory[index];
        final price = bid.price.toString();
        final createdAtRaw = bid.createdAt;
        final relative = formatRelativeTime(createdAtRaw);
        final bidIndex = _bidHistory.length - index; // 역순으로 표시
        final userName = bid.userName;
        final isWinner = bid.auctionLogCode == 430; // 낙찰자 여부

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isWinner
                  ? const Color(0xFFFFF9E6) // 낙찰자: 연한 금색 배경
                  : const Color(0xFFF2F4F6), // 일반: Subtle Gray Fill
              borderRadius: BorderRadius.circular(12),
              border: isWinner
                  ? Border.all(
                      color: const Color(0xFFFFD700), // 금색 테두리
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 순번 배지 또는 낙찰자 아이콘
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isWinner
                        ? const Color(0xFFFFD700) // 낙찰자: 금색
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWinner
                          ? const Color(0xFFFFA500) // 낙찰자: 진한 금색 테두리
                          : const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: isWinner
                        ? const Icon(
                            Icons.emoji_events, // 트로피 아이콘
                            size: 18,
                            color: Colors.white,
                          )
                        : Text(
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
                      Row(
                        children: [
                          Text(
                            '${formatPrice(int.tryParse(price) ?? 0)}원',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isWinner
                                  ? const Color(0xFFF59E0B) // 낙찰자: 금색
                                  : const Color(0xFF191F28), // Primary Text
                            ),
                          ),
                          if (isWinner) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '낙찰',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      // 참여자 정보
                      Text(
                        userName.isNotEmpty ? userName : '닉네임 정보 없음',
                        style: TextStyle(
                          fontSize: 13,
                          color: userName.isNotEmpty
                              ? (isWinner
                                    ? const Color(0xFF92400E) // 낙찰자: 진한 금색
                                    : const Color(
                                        0xFF6B7684,
                                      )) // 일반: Secondary Text
                              : const Color(0xFFB0B8C0), // Light Gray (정보 없음)
                        ),
                      ),
                    ],
                  ),
                ),
                // 시간
                Text(
                  relative,
                  style: TextStyle(
                    fontSize: 13,
                    color: isWinner
                        ? const Color(0xFF92400E) // 낙찰자: 진한 금색
                        : const Color(0xFF6B7684), // Secondary Text
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

