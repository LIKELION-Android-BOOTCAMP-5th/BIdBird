import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/bid/presentation/widgets/item_detail_bid_history_entry.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_description_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_image_gallery.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_seller_row.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_summary_section.dart';
import 'package:bidbird/features/item_detail/detail/presentation/widgets/tabs/item_detail_document_tab.dart';

class ItemDetailBody extends StatefulWidget {
  const ItemDetailBody({
    super.key,
    required this.item,
    required this.isMyItem,
    required this.bottomActionBar,
    this.appBar,
    this.scrollController,
    this.onRefresh,
    this.isPreview = false,
  });

  final ItemDetail item;
  final bool isMyItem;
  final Widget bottomActionBar;
  final PreferredSizeWidget? appBar;
  final ScrollController? scrollController;
  final Future<void> Function()? onRefresh;
  final bool isPreview;

  @override
  State<ItemDetailBody> createState() => _ItemDetailBodyState();
}

class _ItemDetailBodyState extends State<ItemDetailBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  // 주입받은 컨트롤러가 없으면 자체적으로 생성
  late final ScrollController _scrollController;
  bool _isSelfControlledScroll = false;

  @override
  void initState() {
    super.initState();
    // 미리보기면 탭 2개 (설명, 보증서), 아니면 4개
    final tabLength = widget.isPreview ? 2 : 4;
    _tabController = TabController(length: tabLength, vsync: this);
    if (widget.scrollController != null) {
      _scrollController = widget.scrollController!;
    } else {
      _scrollController = ScrollController();
      _isSelfControlledScroll = true;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    if (_isSelfControlledScroll) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 구조는 여기서 잡지 않고 호출부에서 처리할 수도 있지만,
    // 기존 로직(extendBodyBehindAppBar 등)을 보존하기 위해 여기서 Scaffold 사용
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      body: Column(
        children: [
          Expanded(
            child: widget.onRefresh != null
                ? RefreshIndicator(
                    onRefresh: widget.onRefresh!,
                    color: blueColor,
                    backgroundColor: Colors.white,
                    child: _buildScrollView(context),
                  )
                : _buildScrollView(context),
          ),
          widget.bottomActionBar,
        ],
      ),
    );
  }

  Widget _buildScrollView(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
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
                                    tabs: [
                                      const Tab(text: '상품 설명'),
                                      const Tab(text: '보증서'),
                                      if (!widget.isPreview) ...const [
                                        Tab(text: '입찰 내역'),
                                        Tab(text: '판매자'),
                                      ],
                                    ],
                                    overlayColor:
                                        WidgetStateProperty.all(Colors.transparent),
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
                            if (widget.isPreview) return const SizedBox();
                            return _buildBidHistoryTab();
                          case 3:
                            if (widget.isPreview) return const SizedBox();
                            return _buildSellerTab();
                          default:
                            return const SizedBox();
                        }
                      },
                    ),
                  ),
                ),
              ],
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
