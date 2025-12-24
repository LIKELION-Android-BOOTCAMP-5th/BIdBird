import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_check_cancel_popup.dart';
import 'package:bidbird/core/widgets/full_screen_video_viewer.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/dialogs/full_screen_image_gallery_viewer.dart';
import 'package:bidbird/features/item_enroll/registration/detail/presentation/viewmodels/item_registration_detail_viewmodel.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ItemRegistrationDetailScreen extends StatelessWidget {
  const ItemRegistrationDetailScreen({super.key, required this.item});

  final ItemRegistrationData item;

  @override
  Widget build(BuildContext context) {
    final String startPriceText = formatPrice(item.startPrice);
    // 즉시 입찰가는 현재 화면에서 노출하지 않기 위해 주석 처리
    // final String? instantPriceText = item.instantPrice > 0
    //     ? formatPrice(item.instantPrice)
    //     : null;

    final String auctionDurationText = formatAuctionDurationForDisplay(
      item.auctionDurationHours,
    );

    return ChangeNotifierProvider<ItemRegistrationDetailViewModel>(
      create: (_) => ItemRegistrationDetailViewModel(item: item)
        ..loadTerms()
        ..loadImage(),
      child: Consumer<ItemRegistrationDetailViewModel>(
        builder: (context, viewModel, _) {
          final double horizontalPadding = context.screenPadding;
          final double verticalPadding = context.spacingSmall;
          return Scaffold(
            backgroundColor: BackgroundColor,
            appBar: AppBar(
              title: const Text('매물 등록 확인'),
              centerTitle: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: blueColor),
                  onPressed: () {
                    viewModel.deleteItem(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: blueColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/add_item', extra: item.id);
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        verticalPadding,
                        horizontalPadding,
                        verticalPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Consumer<ItemRegistrationDetailViewModel>(
                            builder: (context, viewModel, _) {
                              return _buildImageSection(context, viewModel);
                            },
                          ),
                          SizedBox(height: context.spacingSmall),
                          _buildInfoCard(
                            context,
                            startPriceText,
                            auctionDurationText,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomButton(context, viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    ItemRegistrationDetailViewModel viewModel,
  ) {
    final imageUrls = viewModel.imageUrls;
    final hasImages = imageUrls.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: chatItemCardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: hasImages
            ? _ImageGallery(imageUrls: imageUrls)
            : Container(color: Colors.grey.shade200),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String startPriceText,
    String auctionDurationText,
  ) {
    final double cardPaddingH = context.spacingSmall + 6;
    final double cardPaddingV = context.spacingMedium;
    final double titleFont = context.fontSizeLarge;
    final double labelFont = context.fontSizeSmall + 1;
    final double valueFont = context.fontSizeMedium;

    return Container(
      decoration: BoxDecoration(
        color: chatItemCardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(
        horizontal: cardPaddingH,
        vertical: cardPaddingV,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: TextStyle(
              fontSize: titleFont,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: context.spacingSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '시작가',
                style: TextStyle(
                  fontSize: labelFont,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '$startPriceText원',
                style: TextStyle(
                  fontSize: valueFont,
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingSmall * 0.6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '경매 기간',
                style: TextStyle(
                  fontSize: labelFont,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                auctionDurationText,
                style: TextStyle(
                  fontSize: valueFont,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: context.spacingSmall * 1.5),
          const Divider(height: 1, thickness: 1, color: LightBorderColor),
          SizedBox(height: context.spacingSmall),
          Text(
            '상품 설명',
            style: TextStyle(
              fontSize: valueFont,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          SizedBox(height: context.spacingSmall * 0.6),
          Text(
            item.description,
            style: TextStyle(
              fontSize: context.fontSizeSmall + 1,
              color: textColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    ItemRegistrationDetailViewModel viewModel,
  ) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.screenPadding,
          0,
          context.screenPadding,
          context.spacingSmall,
        ),
        child: PrimaryButton(
          text: '등록하기',
          onPressed: () async {
            await showDialog<void>(
              context: context,
              barrierDismissible: true,
              builder: (dialogContext) {
                return ConfirmCheckCancelPopup(
                  title: ItemRegistrationTerms.popupTitle,
                  description: ItemRegistrationTerms.termsContent,
                  checkLabel: ItemRegistrationTerms.checkLabel,
                  confirmText: '등록하기',
                  cancelText: '취소',
                  onConfirm: (checked) async {
                    if (!checked) return;
                    await viewModel.confirmRegistration(context);
                  },
                  onCancel: () {},
                );
              },
            );
          },
          isEnabled: !viewModel.isSubmitting,
          height: 52,
          fontSize: 16,
          width: double.infinity,
        ),
      ),
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentPage = index;
            });
          },
          itemCount: widget.imageUrls.length,
          itemBuilder: (context, index) {
            final imageUrl = widget.imageUrls[index];
            final bool isVideo = isVideoFile(imageUrl);
            final displayUrl = isVideo
                ? getVideoThumbnailUrl(imageUrl)
                : imageUrl;

            return GestureDetector(
              onTap: () {
                if (isVideo) {
                  FullScreenVideoViewer.show(context, imageUrl);
                } else {
                  final imageOnlyUrls = widget.imageUrls
                      .where((url) => !isVideoFile(url))
                      .toList();
                  final imageIndex = imageOnlyUrls.indexOf(imageUrl);

                  if (imageIndex >= 0) {
                    FullScreenImageGalleryViewer.show(
                      context,
                      imageOnlyUrls,
                      initialIndex: imageIndex,
                    );
                  }
                }
              },
              child: Stack(
                children: [
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: displayUrl,
                      cacheManager: ItemImageCacheManager.instance,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: Colors.grey.shade200,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                  if (isVideo)
                    Positioned.fill(
                      child: Container(
                        color: TextPrimary.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: chatItemCardBackground,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: TextPrimary.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_currentPage + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: chatItemCardBackground,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
