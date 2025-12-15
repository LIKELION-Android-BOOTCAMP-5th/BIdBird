import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/item/components/others/item_bid_result_body.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/seller_payment_complete/viewmodel/seller_payment_complete_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SellerPaymentCompleteScreen extends StatelessWidget {
  const SellerPaymentCompleteScreen({
    super.key,
    required this.item,
  });

  final ItemBidWinEntity item;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SellerPaymentCompleteViewModel>(
      create: (_) => SellerPaymentCompleteViewModel(item: item)..loadShippingInfo(),
      child: Consumer<SellerPaymentCompleteViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: BackgroundColor,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: ItemBidResultBody(
                          item: item,
                          title: '결제가 완료되었습니다',
                          subtitle: '배송 정보를 입력해주세요',
                          icon: Icons.check_circle,
                          iconColor: blueColor,
                          priceLabel: '결제 금액',
                          onClose: () {
                            Navigator.of(context).pop();
                          },
                          actions: [
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveConstants.buttonHeight(context),
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChattingRoomScreen(itemId: item.itemId),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: const BorderSide(color: BorderColor),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: defaultBorder,
                                  ),
                                ),
                                child: Text(
                                  '구매자 연락하기',
                                  style: TextStyle(
                                    fontSize: ResponsiveConstants.buttonFontSize(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveConstants.spacingSmall(context)),
                            SizedBox(
                              width: double.infinity,
                              height: ResponsiveConstants.buttonHeight(context),
                              child: ElevatedButton(
                                onPressed: () => viewModel.showShippingInfoDialog(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: blueColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: defaultBorder,
                                  ),
                                ),
                                child: Text(
                                  viewModel.hasShippingInfo
                                      ? '배송 정보 확인하기'
                                      : '배송 정보 입력하기',
                                  style: TextStyle(
                                    fontSize: ResponsiveConstants.buttonFontSize(context),
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: ResponsiveConstants.spacingMedium(context)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
