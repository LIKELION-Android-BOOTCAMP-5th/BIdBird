import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:bidbird/features/report/presentation/screens/report_screen.dart';
import 'package:bidbird/core/widgets/components/loading_indicator.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_bottom_action_bar.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_image_gallery.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_summary_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_description_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_seller_row.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_entry.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemDetailViewModel>(
      create: (_) => ItemDetailViewModel(itemId: itemId)
        ..loadItemDetail(),
      child: const _ItemDetailScaffold(),
    );
  }
}

class _ItemDetailScaffold extends StatefulWidget {
  const _ItemDetailScaffold();

  @override
  State<_ItemDetailScaffold> createState() => _ItemDetailScaffoldState();
}

class _ItemDetailScaffoldState extends State<_ItemDetailScaffold> {
  @override
  Widget build(BuildContext context) {
    // 로딩 상태만 Selector로 분리
    return Selector<ItemDetailViewModel, bool>(
      selector: (_, vm) => vm.isLoading,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return const Scaffold(
            body: SafeArea(
              child: CenteredLoadingIndicator(),
            ),
          );
        }
        return const _ItemDetailContent();
      },
    );
  }
}

class _ItemDetailContent extends StatefulWidget {
  const _ItemDetailContent();

  @override
  State<_ItemDetailContent> createState() => _ItemDetailContentState();
}

class _ItemDetailContentState extends State<_ItemDetailContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    // 에러 상태와 itemDetail, isMyItem을 함께 Selector로 분리
    return Selector<ItemDetailViewModel, ({String? error, ItemDetail? itemDetail, bool isMyItem})>(
      selector: (_, vm) => (error: vm.error, itemDetail: vm.itemDetail, isMyItem: vm.isMyItem),
      builder: (context, data, _) {
        if (data.error != null || data.itemDetail == null) {
          return const Scaffold(
            body: SafeArea(
              child: Center(
                child: Text(
                  '매물 정보를 불러올 수 없습니다.',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          );
        }

        final ItemDetail item = data.itemDetail!;

        return Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,
          appBar: _ItemDetailAppBar(item: item),
          body: Column(
            children: [
              Expanded(
                child: TransparentRefreshIndicator(
                  onRefresh: () async {
                    await context.read<ItemDetailViewModel>().loadItemDetail(forceRefresh: true);
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Image Section - AppBar 아래까지 확장
                        ItemDetailImageGallery(item: item),
                        // Metric Section - 라운드 처리된 카드 (이미지 위로 올라가도록)
                        Transform.translate(
                          offset: const Offset(0, -30),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  ItemDetailSummarySection(item: item, isMyItem: data.isMyItem),
                                  ItemDetailSellerRow(item: item),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Info Section - padding 24 (라인 없이 바로 연결)
                        ItemDetailDescriptionSection(item: item),
                        // Divider
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                        ),
                        // Bid History Section - padding 0
                        ItemDetailBidHistoryEntry(item: item),
                        // Safe Area Spacer 48
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
              _ItemBottomActionBar(item: item),
            ],
          ),
        );
      },
    );
  }
}

class _ItemDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ItemDetailAppBar({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemDetailViewModel>(
      builder: (context, viewModel, _) {
        final isMyItem = viewModel.isMyItem;
        final sellerProfile = viewModel.sellerProfile;
        
        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 56,
          leading: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.all(8),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          title: const SizedBox.shrink(),
          centerTitle: false,
          actions: [
            // 공유 버튼
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // 공유 기능 구현
                  final shareText = '${item.itemTitle}\n현재 입찰가: ${item.currentPrice}원';
                  try {
                    await Share.share(shareText);
                  } catch (e) {
                    // share_plus가 작동하지 않으면 클립보드로 대체
                    await Clipboard.setData(ClipboardData(text: shareText));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('링크가 클립보드에 복사되었습니다'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(right: 4, top: 8, bottom: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
            // 신고 버튼
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (isMyItem) {
                    // 내 아이템이면 신고 불가 안내
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('본인의 상품은 신고할 수 없습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  if (item.sellerId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('판매자 정보를 불러올 수 없습니다'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReportScreen(
                        itemId: item.itemId,
                        itemTitle: item.itemTitle,
                        targetUserId: item.sellerId,
                        targetNickname: sellerProfile?['nick_name'] as String?,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.warning,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ItemBottomActionBar extends StatelessWidget {
  const _ItemBottomActionBar({required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    // isMyItem과 isFavorite를 함께 Selector로 분리
    return Selector<ItemDetailViewModel, ({bool isMyItem, bool isFavorite})>(
      selector: (_, vm) => (isMyItem: vm.isMyItem, isFavorite: vm.isFavorite),
      builder: (context, data, _) {
        // ItemBottomActionBar는 내부에서 context.watch를 사용하므로
        // ViewModel을 전달하지 않고 직접 사용하도록 함
        return ItemBottomActionBar(item: item, isMyItem: data.isMyItem);
      },
    );
  }
}
