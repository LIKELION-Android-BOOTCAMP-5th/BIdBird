import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_check_cancel_popup.dart';
import 'package:bidbird/features/item/item_registration_list/model/item_registration_entity.dart';
import 'package:bidbird/features/item/item_registration_detail/viewmodel/item_registration_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ItemRegistrationDetailScreen extends StatelessWidget {
  const ItemRegistrationDetailScreen({super.key, required this.item});

  final ItemRegistrationData item;

  String _formatPrice(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final reverseIndex = str.length - i;
      buffer.write(str[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != str.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final String startPriceText = _formatPrice(item.startPrice);
    final String? instantPriceText =
        item.instantPrice > 0 ? _formatPrice(item.instantPrice) : null;

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
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      color: blueColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                          _buildImageSection(),
                          const SizedBox(height: 16),
                          _buildInfoCard(startPriceText, instantPriceText),
                          const SizedBox(height: 12),
                          _buildDescriptionCard(),
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

  Widget _buildImageSection() {
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
              child: item.thumbnailUrl != null && item.thumbnailUrl!.isNotEmpty
                  ? Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
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

  Widget _buildInfoCard(String startPriceText, String? instantPriceText) {
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
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '시작가 ₩$startPriceText',
            style: const TextStyle(
              fontSize: 13,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            instantPriceText != null
                ? '즉시 입찰가 ₩$instantPriceText'
                : '즉시 입찰가: 없음',
            style: const TextStyle(
              fontSize: 13,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상품 설명',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: textColor,
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
                          title: '약관 확인',
                          description:
                              '1. 판매자는 시작가와 즉시 구매가(선택 입력)를 정확하게 입력해야 합니다. 허위 정보 입력은 금지됩니다.\n'
                              '2. 등록된 매물은 경매 시작 시점부터 경매 종료까지 임의 수정 또는 삭제가 제한될 수 있습니다.\n'
                              '3. 경매 종료 후 낙찰자가 존재할 경우, 판매자는 해당 낙찰자에게 매물을 반드시 인도해야 합니다. 임의 취소는 허용되지 않습니다.\n'
                              '4. 낙찰 금액 또는 즉시 구매 금액은 플랫폼 정책에 따라 결제·정산 절차가 진행됩니다. 판매자는 이에 동의한 것으로 간주됩니다.\n'
                              '5. 매물 설명, 사진, 상태 정보 등 모든 기재 내용은 사실에 기반해야 합니다. 허위 또는 과장 기재로 인해 발생하는 문제는 판매자 책임입니다.\n'
                              '6. 불법 물품, 타인의 권리를 침해하는 물품, 거래가 제한된 물품은 등록이 금지됩니다. 위반 시 매물 삭제 및 서비스 이용 제한이 적용될 수 있습니다.\n'
                              '7. 거래 과정에서 분쟁이 발생할 경우, 플랫폼의 분쟁 처리 기준 및 검증 절차가 우선 적용됩니다. 판매자는 관련 자료 제출 요청에 협조해야 합니다.\n'
                              '8. 매물 등록 시점부터 거래 종료까지 모든 기록은 운영 정책에 따라 보관·검토될 수 있습니다.\n'
                              '9. 약관에 위배되는 행위가 확인될 경우, 플랫폼은 매물 삭제, 거래 중단, 계정 제재 등의 조치를 시행할 수 있습니다.\n'
                              '10. 본 약관은 등록 시점 기준으로 적용되며, 운영 정책에 따라 변경될 수 있습니다.',
                          checkLabel: '약관을 모두 확인했고 동의합니다.',
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
