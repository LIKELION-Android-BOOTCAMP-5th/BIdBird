import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/features/item_detail/data/item_detail_data.dart';
import 'package:bidbird/features/item_detail/viewmodel/item_detail_viewmodel.dart';
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
    return ChangeNotifierProvider(
      create: (_) => ItemDetailViewModel(itemId: itemId)
        ..loadItemDetail()
        ..setupRealtimeSubscription(),
      child: const _ItemDetailView(),
    );
  }
}

class _ItemDetailView extends StatelessWidget {
  const _ItemDetailView();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItemDetailViewModel>();

    if (viewModel.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xffF5F6FA),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(blueColor),
          ),
        ),
      );
    }

    if (viewModel.error != null || viewModel.itemDetail == null) {
      return Scaffold(
        backgroundColor: const Color(0xffF5F6FA),
        appBar: AppBar(title: const Text('상세 보기')),
        body: Center(
          child: Text(
            viewModel.error ?? '매물 정보를 불러올 수 없습니다.',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }

    final item = viewModel.itemDetail!;
    final currentUser = SupabaseManager.shared.supabase.auth.currentUser;
    final isMyItem = currentUser != null && currentUser.id == item.sellerId;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
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
  }
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
                      item.buyNowPrice > 0
                          ? '즉시 구매가 ₩${_formatPrice(item.buyNowPrice)}'
                          : '즉시 구매 없음',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: item.buyNowPrice > 0 ? blueColor : Colors.grey,
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
                    GoRouter.of(context).push('/user/${item.sellerId}');
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

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.item, required this.isMyItem});

  final ItemDetail item;
  final bool isMyItem;

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ItemDetailViewModel>();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: const Color(0xffF5F6FA),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  if (!isMyItem) ...[
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton(
                        onPressed: () => viewModel.toggleFavorite(),
                        padding: EdgeInsets.zero,
                        splashRadius: 24,
                        icon: Icon(
                          viewModel.isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 24,
                          color: Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 입찰하기 버튼 또는 최고 입찰자 표시
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: viewModel.isTopBidder
                            ? Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8.7),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: Center(
                                  child: Text(
                                    '최고 입찰자입니다',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
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
                                      return ChangeNotifierProvider<PriceInputViewModel>(
                                        create: (_) => PriceInputViewModel(),
                                        child: BidBottomSheet(
                                          itemId: item.itemId,
                                          currentPrice: item.currentPrice,
                                          bidUnit: item.bidPrice,
                                          buyNowPrice: item.buyNowPrice,
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
                    
                    // 즉시 구매 버튼 (즉시 구매가가 있을 때만 표시)
                    if (item.buyNowPrice > 0) ...[
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

