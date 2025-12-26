import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
import 'package:bidbird/core/widgets/item/components/sections/content_input_section.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 카드 3: 상세·확인
class DetailConfirmCard extends StatelessWidget {
  const DetailConfirmCard({super.key, required this.viewModel});

  final ItemAddViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // 반응형 값 캐싱
    final hPadding = context.hPadding;
    final vPadding = context.vPadding;
    final spacing = context.spacingMedium;
    final spacingSmall = context.spacingSmall;
    final fontSizeSmall = context.fontSizeSmall;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상품 설명 입력
          ContentInputSection(
            label: '상품 설명',
            controller: viewModel.descriptionController,
            hintText: '상품에 대한 상세한 설명을 입력하세요',
            maxLength: 1000,
            minLines: 8,
            maxLines: 8,
          ),
          SizedBox(height: spacing),

          // PDF 보증서 업로드 섹션
          FormLabel(text: '보증서 (PDF) (선택)'),
          Consumer<ItemAddViewModel>(
            builder: (context, vm, _) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(spacingSmall),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: defaultBorder,
                  border: Border.all(color: LightBorderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (vm.selectedDocuments.isEmpty)
                      GestureDetector(
                        onTap: () => vm.pickDocuments(),
                        child: Container(
                          height: 60,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.file_present_outlined,
                                  color: iconColor, size: 20),
                              SizedBox(width: spacingSmall),
                              Text(
                                'PDF 보증서를 업로드하세요',
                                style: TextStyle(
                                  fontSize: fontSizeSmall,
                                  color: iconColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...List.generate(vm.selectedDocuments.length,
                              (index) {
                            final doc = vm.selectedDocuments[index];
                            final fileName = doc.originalName;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: BackgroundColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: BorderColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.description_outlined,
                                      size: 14, color: blueColor),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      fileName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: TextPrimary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: () => vm.removeDocumentAt(index),
                                    child: Icon(Icons.close,
                                        size: 14, color: iconColor),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (vm.selectedDocuments.length < 5)
                            GestureDetector(
                              onTap: () => vm.pickDocuments(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: blueColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child:
                                    Icon(Icons.add, size: 16, color: blueColor),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
