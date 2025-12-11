import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/confirm_check_cancel_popup.dart';
import 'package:bidbird/features/item/bottom_sheet_buy_now_input/viewmodel/buy_now_input_viewmodel.dart';
import 'package:bidbird/features/item/detail/viewmodel/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widget/buy_now_header.dart';
import '../widget/buy_now_price_card.dart';
import '../widget/buy_now_primary_button.dart';

class BuyNowInputBottomSheet extends StatelessWidget {
  const BuyNowInputBottomSheet({
    super.key,
    required this.itemId,
    required this.buyNowPrice,
  });

  final String itemId;
  final int buyNowPrice;

  String _formatPrice(int price) {
    final buffer = StringBuffer();
    final text = price.toString();
    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;
      buffer.write(text[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BuyNowInputViewModel>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BuyNowHeader(onClose: () => Navigator.pop(context)),
            const SizedBox(height: 16),
            BuyNowPriceCard(formattedPrice: '${_formatPrice(buyNowPrice)}원'),
            const SizedBox(height: 24),
            BuyNowPrimaryButton(
              isSubmitting: viewModel.isSubmitting,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final parentContext = context;
                if (buyNowPrice < 10000 || buyNowPrice > 5000000) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('즉시 구매가는 10,000원 이상 5,000,000원 이하만 가능합니다.'),
                    ),
                  );
                  return;
                }
                try {
                  final isBlocked = await viewModel.checkBidRestriction();

                  if (isBlocked) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content:
                            Text('결제 3회 이상 실패하여 입찰이 제한되었습니다.'),
                      ),
                    );
                    return;
                  }
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('입찰 제한 정보를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.\n$e'),
                    ),
                  );
                  return;
                }

                if (!parentContext.mounted) return;

                _showTermsDialog(parentContext, viewModel);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog(
    BuildContext parentContext,
    BuyNowInputViewModel viewModel,
  ) {
    const terms =
        '즉시 구메란 회원이 경매 화면에서 회사가 제시하는 금액(예: 현재 입찰가에 일정 입찰 단위를 더한 금액 등)을 단일 조작으로 입력하여 곧바로 입찰을 완료하는 기능을 말합니다.\n\n'
        '즉시 구매는 회사 서버에 해당 입찰 정보가 도달하여 시스템에 정상적으로 저장된 시점을 기준으로 유효하게 성립하며, 화면 표시 지연·네트워크 장애 등으로 인한 시간 차이는 인정하지 않습니다.\n\n'
        '동일 금액에 대한 즉시 입찰이 복수 존재하는 경우, 회사 시스템에 먼저 접수·기록된 입찰을 우선하는 것으로 합니다.\n\n'
        '회원이 즉시 구매을 통해 제출한 입찰 금액, 수량, 조건 등은 관련 법령에서 정한 취소 사유가 있는 경우를 제외하고 경매 종료 전 임의 변경 또는 취소가 불가능합니다.\n\n'
        '즉시 입찰로 최고 입찰자가 된 회원은 경매 종료 시점에 낙찰자로 확정될 수 있으며, 이 경우 서비스 내 고지된 결제 기한, 방식 및 절차에 따라 결제 의무를 부담합니다. 정당한 사유 없이 결제를 이행하지 아니한 경우, 회사는 경매 참여 제한, 이용 정지, 손해배상 청구 등 약관 및 운영정책에서 정한 제재를 할 수 있습니다.\n\n'
        '회사는 다음 각 호의 어느 하나에 해당하는 경우 즉시 입찰을 사전 통지 없이 취소 또는 무효화할 수 있으며, 필요 시 해당 회원의 경매 참여를 제한할 수 있습니다.\n\n'
        '1) 시스템 오류, 통신 장애 등으로 정상적인 입찰 처리가 이루어지지 않은 경우\n'
        '2) 타인의 계정 도용, 비정상적인 프로그램·매크로 이용 등 부정한 방법으로 즉시 입찰이 이루어진 경우\n'
        '3) 기타 관련 법령, 본 약관 또는 운영정책을 중대한 위반한 사실이 인정되는 경우\n\n'
        '즉시 입찰과 관련하여 회사가 고의 또는 중대한 과실 없이 제공한 정보의 지연, 오류, 누락, 시스템 장애 등으로 인해 회원 또는 제3자에게 발생한 손해에 대하여 회사는 관련 법령에서 달리 정하지 않는 한 책임을 지지 않습니다.';

    showDialog(
      context: parentContext,
      barrierDismissible: true,
      builder: (dialogContext) {
        return ConfirmCheckCancelPopup(
          title: '즉시 구매 약관',
          description: terms,
          checkLabel: '위 내용을 모두 확인했고 동의합니다.',
          confirmText: '동의',
          cancelText: '취소',
          onConfirm: (checked) {
            if (!checked) return;
            _showConfirmDialog(parentContext, viewModel);
          },
          onCancel: () {},
        );
      },
    );
  }

  void _showConfirmDialog(
    BuildContext parentContext,
    BuyNowInputViewModel viewModel,
  ) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => ConfirmCheckCancelPopup(
        title: '즉시 구매',
        description:
            '결제는 10분 이내에 완료해야 합니다.\n제한 시간을 초과하면 거래가 자동 취소됩니다.\n해당 상황이 3회 반복되면 거래가 일시 중지됩니다.',
        checkLabel: '',
        confirmText: '확인',
        cancelText: '취소',
        onConfirm: (_) async {
          Navigator.pop(dialogContext);
          await _processInstantBid(parentContext, viewModel);
        },
        onCancel: () {},
      ),
    );
  }

  Future<void> _processInstantBid(
    BuildContext parentContext,
    BuyNowInputViewModel viewModel,
  ) async {
    try {
      await viewModel.placeBid(itemId: itemId, bidPrice: buyNowPrice);

      if (!parentContext.mounted) return;
      await showDialog(
        context: parentContext,
        barrierDismissible: false,
        builder: (dialogContext) => AskPopup(
          content: '즉시 구매가 완료되었습니다.',
          yesText: '확인',
          yesLogic: () async {
            Navigator.pop(dialogContext);
            if (!parentContext.mounted) return;

            // 상세 화면 강제 새로고침
            final detailViewModel =
                parentContext.read<ItemDetailViewModel?>();
            if (detailViewModel != null) {
              await detailViewModel.loadItemDetail();
            }

            if (parentContext.mounted) {
              Navigator.pop(parentContext);
            }
          },
        ),
      );
    } catch (e) {
      if (parentContext.mounted) {
        showDialog(
          context: parentContext,
          builder: (dialogContext) => AskPopup(
            content: '오류가 발생했습니다.\n$e',
            yesText: '확인',
            yesLogic: () async {
              Navigator.pop(dialogContext);
            },
          ),
        );
      }
    }
  }
}
