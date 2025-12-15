import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_check_cancel_popup.dart';
import 'package:bidbird/features/chat/presentation/widgets/full_screen_video_viewer.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/features/item/registration/detail/viewmodel/item_registration_detail_viewmodel.dart';
import 'package:bidbird/features/item/registration/list/model/item_registration_entity.dart';
import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

    final String auctionDurationText = 
        formatAuctionDurationForDisplay(item.auctionDurationHours);

    return ChangeNotifierProvider<ItemRegistrationDetailViewModel>(
      create: (_) => ItemRegistrationDetailViewModel(item: item)..loadTerms(),
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
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildImageSection(context),
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

  Widget _buildImageSection(BuildContext context) {
    final thumbnailUrl = item.thumbnailUrl;
    final bool isVideo = thumbnailUrl != null && isVideoFile(thumbnailUrl);
    final displayUrl = isVideo 
        ? getVideoThumbnailUrl(thumbnailUrl) 
        : thumbnailUrl;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.hardEdge,
      child: AspectRatio(
        aspectRatio: 1,
        child: Stack(
          children: [
            Positioned.fill(
              child: displayUrl != null && displayUrl.isNotEmpty
                  ? GestureDetector(
                      onTap: isVideo
                          ? () {
                              // 전체 화면 비디오 플레이어로 재생
                              FullScreenVideoViewer.show(context, thumbnailUrl);
                            }
                          : null,
                      child: Stack(
                        children: [
                          CachedNetworkImage(
                            imageUrl: displayUrl,
                            cacheManager: ItemImageCacheManager.instance,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Text(
                                '이미지 없음',
                                style: TextStyle(color: Colors.white, fontSize: 16),
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
                    )
                  : const Center(
                      child: Text(
                        '이미지 없음',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
            ),
            const Positioned(
              right: 8,
              bottom: 8,
              child: Text(
                '1/1',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
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
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: blueColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: viewModel.isSubmitting
                ? null
                : () async {
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
            child: const Text(
              '등록하기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
