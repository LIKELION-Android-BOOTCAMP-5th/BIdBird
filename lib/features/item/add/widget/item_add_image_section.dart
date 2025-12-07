import 'dart:io';

import 'package:bidbird/core/utils/ui_set/border_radius.dart';
import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:flutter/material.dart';

import '../viewmodel/item_add_viewmodel.dart';

class ItemAddImagesSection extends StatelessWidget {
  const ItemAddImagesSection({
    super.key,
    required this.viewModel,
    required this.onTapAdd,
  });

  final ItemAddViewModel viewModel;
  final VoidCallback onTapAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: BackgroundColor,
        borderRadius: defaultBorder,
        border: Border.all(color: BackgroundColor),
      ),
      child: Stack(
        children: [
          if (viewModel.selectedImages.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.file_upload_outlined,
                    color: iconColor,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '이미지를 업로드하세요',
                    style: TextStyle(
                      fontSize: 13,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              itemBuilder: (context, index) {
                final image = viewModel.selectedImages[index];
                final bool isPrimary = index == viewModel.primaryImageIndex;
                return GestureDetector(
                  onTap: () {
                    viewModel.setPrimaryImage(index);
                  },
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: defaultBorder,
                        child: Image.file(
                          File(image.path),
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            viewModel.removeImageAt(index);
                          },
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      if (isPrimary)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: blueColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '대표 이미지',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: viewModel.selectedImages.length,
            ),
          Positioned(
            right: 8,
            bottom: 8,
            child: GestureDetector(
              onTap: onTapAdd,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: blueColor,
                  borderRadius: BorderRadius.circular(defaultRadius),
                ),
                child: const Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: blueColor,
                borderRadius: BorderRadius.circular(defaultRadius),
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${viewModel.selectedImages.length}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
