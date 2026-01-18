import 'package:bidbird/features/item_detail/detail/presentation/widgets/blocks/item_detail_body.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';

/// 카드 4: 미리보기 및 최종 등록
class PreviewConfirmCard extends StatelessWidget {
  const PreviewConfirmCard({
    super.key,
    required this.viewModel,
    required this.onBack,
  });

  final ItemAddViewModel viewModel;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    // 현재 입력된 데이터로 ItemDetail 엔티티 생성
    final previewItem = viewModel.toPreviewEntity();

    return ItemDetailBody(
      item: previewItem,
      isMyItem: true, // 미리보기는 내 매물로 간주
      isPreview: true, // 미리보기 모드 활성화 (탭 축소)
      bottomActionBar: const SizedBox.shrink(),
      // 미리보기에서는 앱바를 숨기거나 간단하게 표시
      appBar: AppBar(
        title: const Text('미리보기'),
        automaticallyImplyLeading: false, // 커스텀 leading 사용
        leading: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

