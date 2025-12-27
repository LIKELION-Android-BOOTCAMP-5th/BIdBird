import 'dart:io';

import 'package:bidbird/core/managers/item_image_cache_manager.dart';
import 'package:bidbird/core/utils/item/item_auction_duration_utils.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/core/utils/item/item_price_utils.dart';
import 'package:bidbird/core/utils/item/item_registration_terms.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/full_screen_video_viewer.dart';
import 'package:bidbird/core/widgets/item/components/buttons/primary_button.dart';
import 'package:bidbird/core/widgets/item/dialogs/full_screen_image_gallery_viewer.dart';
import 'package:bidbird/features/item_enroll/registration/detail/presentation/viewmodels/item_registration_detail_viewmodel.dart';
import 'package:bidbird/features/item_enroll/registration/detail/presentation/widgets/item_registration_terms_popup.dart';
import 'package:bidbird/features/item_enroll/registration/list/domain/entities/item_registration_entity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ItemRegistrationDetailScreen extends StatelessWidget {
  const ItemRegistrationDetailScreen({super.key, required this.item});

  final ItemRegistrationData item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemRegistrationDetailViewModel>(
      create: (_) => ItemRegistrationDetailViewModel(item: item)
        ..loadTerms()
        ..loadImage(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            appBar: AppBar(
              title: const Text('매물 등록 확인'),
              centerTitle: true,
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: TextSecondary),
                  onPressed: () {
                    context.read<ItemRegistrationDetailViewModel>().deleteItem(
                          context,
                        );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: TextSecondary),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildAttachmentSummary(context),
                          const SizedBox(height: 16), // Reduced from 24
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTitleSection(item),
                                const SizedBox(height: 20), // Reduced from 32
                                _buildPriceSection(item),
                                const SizedBox(height: 12), // Reduced from 16
                                _buildConditionSection(item),
                                const SizedBox(height: 20), // Reduced from 32
                                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                                const SizedBox(height: 20), // Reduced from 32
                                _buildDescriptionSection(item),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Selector<ItemRegistrationDetailViewModel, bool>(
                    selector: (_, vm) => vm.isSubmitting,
                    builder: (context, isSubmitting, _) {
                      return _buildBottomButton(context, isSubmitting);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentSummary(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F4F6),
      child: Selector<ItemRegistrationDetailViewModel, List<String>>(
        selector: (_, vm) => vm.imageUrls,
        builder: (context, imageUrls, _) {
          if (imageUrls.isEmpty) {
            return const SizedBox(
              height: 220,
              child: Center(
                  child: Text("첨부된 파일이 없습니다.",
                      style: TextStyle(color: TextSecondary))),
            );
          }

          // Case 1: Single File - Full Width
          if (imageUrls.length == 1) {
            return SizedBox(
              height: 300, // Slightly taller for single view
              width: double.infinity,
              child: _buildAttachmentItem(context, imageUrls[0], 0, isSingle: true),
            );
          }

          // Case 2: Multiple Files - Horizontal List
          return SizedBox(
            height: 220,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              scrollDirection: Axis.horizontal,
              itemCount: imageUrls.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _buildAttachmentItem(context, imageUrls[index], index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentItem(BuildContext context, String imageUrl, int index, {bool isSingle = false}) {
    final bool isPdf = imageUrl.toLowerCase().contains('.pdf');
    // If single, use full width (double.infinity effectively via parent).
    // If list, fixed width.
    final double? width = isSingle ? null : 160; 
    
    if (isPdf) {
      return Container(
        width: width,
        // For single view, we might want margin if it's full width, or just full bleed.
        // Let's keep consistency with image styling.
        margin: isSingle ? const EdgeInsets.all(0) : null,
        child: _buildPdfCard(context, imageUrl),
      );
    }
    
    // Image/Video
    final bool isVideo = isVideoFile(imageUrl);
    final displayUrl = isVideo ? getVideoThumbnailUrl(imageUrl) : imageUrl;
    
    return GestureDetector(
      onTap: () {
        final viewModel = context.read<ItemRegistrationDetailViewModel>();
        final imageUrls = viewModel.imageUrls;
        
        if (isVideo) {
          FullScreenVideoViewer.show(context, imageUrl);
        } else {
          final imageOnlyUrls = imageUrls
              .where((url) => !url.toLowerCase().contains('.pdf') && !isVideoFile(url))
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
      child: Container(
        width: width, // null for single to expand
        decoration: BoxDecoration(
          color: Colors.white,
          // Only round corners if it's a list item. Single item full bleed shouldn't unless specified.
          // User said "photo come out full on the screen". Usually implies full bleed or close to it.
          // Let's keep borders for list, maybe remove for single?
          // Actually, let's keep simple border radius for list, but flat for single if full width.
          borderRadius: isSingle ? null : BorderRadius.circular(12),
          border: isSingle ? null : Border.all(color: const Color(0xFFE5E8EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
             Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: displayUrl,
                cacheManager: ItemImageCacheManager.instance,
                fit: BoxFit.cover,
                // Adjust memCacheHeight based on view height
                memCacheHeight: ((isSingle ? 300 : 220) * MediaQuery.of(context).devicePixelRatio).round(),
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey.shade100,
                  child: const Center(
                    child: Icon(Icons.error_outline,
                        color: TextSecondary),
                  ),
                ),
              ),
            ),
            if (isVideo)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
             // Index indicator (only for multiple)
             if (!isSingle)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Single Item Counter (e.g. 1/1) could be added if needed, but user just said "full screen".
          ],
        ),
      ),
    );
  }

  Widget _buildPdfCard(BuildContext context, String url) {
    final viewModel = context.watch<ItemRegistrationDetailViewModel>();
    final isDownloaded = viewModel.isPdfDownloaded(url);
    final fileName = Uri.parse(url).pathSegments.last;
    final bool isSingleView = viewModel.imageUrls.length == 1;

    return GestureDetector(
      onTap: () async {
        if (isDownloaded) {
           final dir = await getApplicationDocumentsDirectory();
           final file = File('${dir.path}/$fileName');
           if (context.mounted) {
             Navigator.push(
               context,
               MaterialPageRoute(
                 builder: (context) => Scaffold(
                   appBar: AppBar(title: Text(fileName)),
                   body: SfPdfViewer.file(file),
                 ),
               ),
             );
           }
        } else {
          await viewModel.downloadPdf(context, url);
        }
      },
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: isSingleView ? null : BorderRadius.circular(12),
          border: isSingleView ? null : Border.all(color: const Color(0xFFE5E8EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf, 
                size: 32,
                color: blueColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: TextPrimary,
              ),
            ),
             const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isDownloaded ? Icons.check_circle : Icons.download_rounded,
                  color: isDownloaded ? Colors.green : TextSecondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  isDownloaded ? "저장됨" : "다운로드",
                  style: TextStyle(
                    fontSize: 11,
                    color: isDownloaded ? Colors.green : TextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection(ItemRegistrationData item) {
    return Text(
      item.title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: TextPrimary,
        height: 1.3,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceSection(ItemRegistrationData item) {
    final startPriceText = formatPrice(item.startPrice);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "시작가",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: TextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$startPriceText원",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: blueColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSection(ItemRegistrationData item) {
    final now = DateTime.now();
    final endTime = now.add(Duration(hours: item.auctionDurationHours));
    final String endTimeText = DateFormat('yyyy.MM.dd HH:mm').format(endTime);
    final String durationText = formatAuctionDurationForDisplay(item.auctionDurationHours);

    // 통합된 조건 박스
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E8EB)),
      ),
      child: Column(
        children: [
          _buildCompactConditionRow("경매 기간", durationText),
          const SizedBox(height: 12),
          Container(height: 1, color: const Color(0xFFF5F5F5)), // Divider
          const SizedBox(height: 12),
          _buildCompactConditionRow("종료 예정", endTimeText),
        ],
      ),
    );
  }

  Widget _buildCompactConditionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: TextSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: TextPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(ItemRegistrationData item) {
    final bool isEmpty = item.description.trim().isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "상품 설명",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: TextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
           width: double.infinity,
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(
             color: const Color(0xFFF9FAFB),
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: const Color(0xFFF2F4F6)),
           ),
           child: isEmpty 
            ? const Text(
                "입력된 설명이 없습니다.",
                style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
              )
            : _ExpandableDescription(description: item.description),
        ),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isSubmitting) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      padding: EdgeInsets.fromLTRB(
        context.screenPadding,
        12,
        context.screenPadding,
        context.spacingSmall + MediaQuery.of(context).padding.bottom,
      ),
      child: PrimaryButton(
        text: '매물 등록하기',
        onPressed: () async {
          await showDialog<void>(
            context: context,
            barrierDismissible: true,
            builder: (dialogContext) {
              return ItemRegistrationTermsPopup(
                title: ItemRegistrationTerms.popupTitle,
                sections: ItemRegistrationTerms.sections, // Updated parameter
                checkLabel: ItemRegistrationTerms.checkLabel, // Updated parameter
                confirmText: '등록하기',
                cancelText: '취소',
                onConfirm: (checked) async {
                  if (!checked) return;
                  await context
                      .read<ItemRegistrationDetailViewModel>()
                      .confirmRegistration(context);
                },
                onCancel: () {},
              );
            },
          );
        },
        isEnabled: !isSubmitting,
        height: 52,
        fontSize: 16,
        width: double.infinity,
      ),
    );
  }
}


class _ExpandableDescription extends StatefulWidget {
  final String description;

  const _ExpandableDescription({required this.description});

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // Simple line count estimation.
    final bool isLong = widget.description.length > 80 || widget.description.contains('\n'); // approx check

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.description,
          style: const TextStyle(
            fontSize: 14,
            height: 1.6,
            color: Color(0xFF424242), // slightly softer reading black
          ),
          maxLines: _isExpanded ? null : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
        ),
        if (isLong) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Text(
                  _isExpanded ? "접기" : "더보기",
                  style: const TextStyle(
                    fontSize: 13,
                    color: TextSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                 Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 16,
                  color: TextSecondary,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
