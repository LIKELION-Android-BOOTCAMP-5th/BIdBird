import 'package:bidbird/core/mixins/form_validation_mixin.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/fields/form_label.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';
import 'package:bidbird/features/item_enroll/add/presentation/viewmodels/item_add_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 카드 3: 상세 정보 (설명 및 PDF 첨부)
class ItemDetailEntryCard extends StatefulWidget {
  const ItemDetailEntryCard({
    super.key,
    required this.viewModel,
    required this.inputDecoration,
    this.addContentKey,
    this.addPDFKey,
  });

  final ItemAddViewModel viewModel;
  final InputDecoration Function(String hint) inputDecoration;
  final GlobalKey? addContentKey;
  final GlobalKey? addPDFKey;

  @override
  State<ItemDetailEntryCard> createState() => ItemDetailEntryCardState();
}

class ItemDetailEntryCardState extends State<ItemDetailEntryCard>
    with FormValidationMixin {
  String? _descriptionError;
  bool _shouldShowErrors = false;

  @override
  bool get shouldShowErrors => _shouldShowErrors;

  @override
  set shouldShowErrors(bool value) => _shouldShowErrors = value;

  void validateFields() {
    startValidation(() {
      if (widget.viewModel.descriptionController.text.trim().isEmpty) {
        _descriptionError = ItemRegistrationErrorMessages.descriptionRequired;
      }
    });
  }

  @override
  void clearAllErrors() {
    _descriptionError = null;
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacingMedium;
    final hPadding = context.hPadding;
    final vPadding = context.vPadding;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 설명 입력
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormLabel(text: '상세 설명'),
              TextField(
                key: widget.addContentKey,
                controller: widget.viewModel.descriptionController,
                maxLines: 8,
                minLines: 5,
                decoration: widget
                    .inputDecoration('상품에 대한 상세한 설명을 입력해주세요 (상태, 구성품 등)')
                    .copyWith(
                      errorText: shouldShowErrors ? _descriptionError : null,
                    ),
                onChanged: (value) {
                  if (shouldShowErrors &&
                      _descriptionError != null &&
                      value.trim().isNotEmpty) {
                    clearError(() => _descriptionError = null);
                  }
                },
              ),
            ],
          ),
          SizedBox(height: spacing * 1.5),
          // PDF 첨부 섹션
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FormLabel(text: '보증서 및 관련 서류 (PDF)'),
              const Text(
                '상품의 정품 보증서나 관련 서류를 PDF 형식으로 첨부할 수 있습니다 (선택 사항).',
                style: TextStyle(fontSize: 12, color: TextSecondary),
              ),
              const SizedBox(height: 12),
              Consumer<ItemAddViewModel>(
                builder: (context, vm, _) {
                  return Column(
                    children: [
                      ...vm.selectedDocuments.map((doc) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc.originalName,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => vm.removeDocument(doc),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          key: widget.addPDFKey,
                          onPressed: () => vm.pickDocument(),
                          icon: const Icon(Icons.add),
                          label: const Text('PDF 파일 추가'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: blueColor),
                            foregroundColor: blueColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
