import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/sections/content_input_section.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';

/// 카드 3: 상세·확인
class DetailConfirmCard extends StatelessWidget {
  const DetailConfirmCard({super.key, required this.viewModel});

  final ItemAddViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    // 반응형 값 캐싱
    final hPadding = context.hPadding;
    final vPadding = context.vPadding;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상품 설명 입력
          Expanded(
            child: ContentInputSection(
              label: '상품 설명',
              controller: viewModel.descriptionController,
              hintText: '상품에 대한 상세한 설명을 입력하세요',
              maxLength: 1000,
              minLines: null,
              maxLines: null,
            ),
          ),
        ],
      ),
    );
  }
}
