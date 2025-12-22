import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
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
    final String? instantPriceText = item.instantPrice > 0
        ? formatPrice(item.instantPrice)
        : null;

    final String auctionDurationText = formatAuctionDurationForDisplay(
      item.auctionDurationHours,
    );

    return ChangeNotifierProvider<ItemRegistrationDetailViewModel>(
      create: (_) => ItemRegistrationDetailViewModel(item: item)
        ..loadTerms()
        ..loadImage(),
      child: Consumer<ItemRegistrationDetailViewModel>(
        builder: (context, viewModel, _) {
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Consumer<ItemRegistrationDetailViewModel>(
                            builder: (context, viewModel, _) {
                              return _buildImageSection(context, viewModel);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildInfoCard(
                            startPriceText,
                            instantPriceText,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 1,
        child: hasImages
            ? _ImageGallery(imageUrls: imageUrls)
            : const Center(
                child: Text(
                  '이미지 없음',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(
    String startPriceText,
    String? instantPriceText,
    String auctionDurationText,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '시작가',
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              Text(
                '$startPriceText원',
                style: const TextStyle(
                  fontSize: 14,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '즉시 입찰가',
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              Text(
                instantPriceText != null ? '$instantPriceText원' : '없음',
                style: const TextStyle(fontSize: 14, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '경매 기간',
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              Text(
                auctionDurationText,
                style: const TextStyle(fontSize: 14, color: textColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 12),
          const Text(
            '상품 설명',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(fontSize: 14, color: textColor),
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
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (context, url, error) => const Center(
                        child: Text(
                          '이미지 없음',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                  if (isVideo)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            color: Colors.white,
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
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${_currentPage + 1}/${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
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
