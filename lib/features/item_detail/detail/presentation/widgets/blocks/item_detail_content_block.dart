import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/item/components/others/transparent_refresh_indicator.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_entry.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_bottom_action_bar.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_description_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_image_gallery.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_seller_row.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_summary_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/tabs/item_detail_document_tab.dart';

class ItemDetailContentBlock extends StatefulWidget {
  const ItemDetailContentBlock({
    super.key,
    required this.item,
    required this.isMyItem,
    required this.onRefresh,
    required this.appBar,
  });

  final ItemDetail item;
  final bool isMyItem;
  final Future<void> Function() onRefresh;
  final PreferredSizeWidget appBar;

  @override
  State<ItemDetailContentBlock> createState() => _ItemDetailContentBlockState();
}

class _ItemDetailContentBlockState extends State<ItemDetailContentBlock>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      body: Column(
        children: [
          Expanded(
            child: TransparentRefreshIndicator(
              onRefresh: widget.onRefresh,
              child: CustomScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 이미지 갤러리
                  SliverToBoxAdapter(
                    child: ItemDetailImageGallery(item: widget.item),
                  ),

                  // 상품 요약 정보 및 탭 바 (하나의 카드 형태로 통합)
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(30),
                              topRight: Radius.circular(30),
                            ),
                          ),
                          child: Column(
                            children: [
                              ItemDetailSummarySection(
                                item: widget.item,
                                isMyItem: widget.isMyItem,
                              ),
                              Container(
                                color: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: context.screenPadding,
                                ),
                                child: Column(
                                  children: [
                                    TabBar(
                                      controller: _tabController,
                                      labelColor: blueColor,
                                      unselectedLabelColor: const Color(0xFF9CA3AF),
                                      indicatorColor: blueColor,
                                      indicatorWeight: 2,
                                      labelStyle: TextStyle(
                                        fontSize: context.fontSizeMedium,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                      unselectedLabelStyle: TextStyle(
                                        fontSize: context.fontSizeMedium,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.3,
                                      ),
                                      tabs: const [
                                        Tab(text: '상품 설명'),
                                        Tab(text: '보증서'),
                                        Tab(text: '입찰 내역'),
                                        Tab(text: '판매자'),
                                      ],
                                      overlayColor: WidgetStateProperty.all(Colors.transparent),
                                      splashFactory: NoSplash.splashFactory,
                                    ),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Color(0xFFE5E7EB),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 탭 뷰 컨텐츠
                  SliverToBoxAdapter(
                    child: Transform.translate(
                      offset: const Offset(0, -30),
                      child: AnimatedBuilder(
                        animation: _tabController,
                        builder: (context, child) {
                          switch (_tabController.index) {
                            case 0:
                              return _buildDescriptionTab();
                            case 1:
                              return ItemDetailDocumentTab(item: widget.item);
                            case 2:
                              return _buildBidHistoryTab();
                            case 3:
                              return _buildSellerTab();
                            default:
                              return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ItemBottomActionBar(item: widget.item, isMyItem: widget.isMyItem),
        ],
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return ItemDetailDescriptionSection(item: widget.item);
  }

  Widget _buildBidHistoryTab() {
    return ItemDetailBidHistoryEntry(item: widget.item);
  }

  Widget _buildSellerTab() {
    return Padding(
      padding: EdgeInsets.all(context.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemDetailSellerRow(item: widget.item),
          const SizedBox(height: 24),
          // 추가 판매자 정보가 필요하면 여기에 추가
        ],
      ),
    );
  }
}
