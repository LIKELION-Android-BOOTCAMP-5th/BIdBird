import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_view_popup.dart';
import 'package:bidbird/core/widgets/item/bid_win/item_bid_result_body.dart';
import 'package:bidbird/features/chat/presentation/screens/chatting_room_screen.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:flutter/material.dart';

class SellerPaymentCompleteScreen extends StatefulWidget {
  const SellerPaymentCompleteScreen({
    super.key,
    required this.item,
  });

  final ItemBidWinEntity item;

  @override
  State<SellerPaymentCompleteScreen> createState() => _SellerPaymentCompleteScreenState();
}

class _SellerPaymentCompleteScreenState extends State<SellerPaymentCompleteScreen> {
  final ShippingInfoRepository _shippingInfoRepository = ShippingInfoRepository();
  Map<String, dynamic>? _shippingInfo;
  bool _isLoadingShippingInfo = true;

  @override
  void initState() {
    super.initState();
    _loadShippingInfo();
  }

  Future<void> _loadShippingInfo() async {
    try {
      final info = await _shippingInfoRepository.getShippingInfo(widget.item.itemId);
      if (mounted) {
        setState(() {
          _shippingInfo = info;
          _isLoadingShippingInfo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingShippingInfo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    item: widget.item,
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
                      builder: (_) => ChattingRoomScreen(itemId: widget.item.itemId),
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
                onPressed: () {
                  final hasShippingInfo = _shippingInfo != null && 
                      _shippingInfo?['tracking_number'] != null &&
                      (_shippingInfo?['tracking_number'] as String?)?.isNotEmpty == true;
                  
                  if (hasShippingInfo) {
                    // 송장 정보가 있으면 확인 팝업 표시
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return ShippingInfoViewPopup(
                          createdAt: _shippingInfo?['created_at'] as String?,
                          carrier: _shippingInfo?['carrier'] as String?,
                          trackingNumber: _shippingInfo?['tracking_number'] as String?,
                        );
                      },
                    );
                  } else {
                    // 송장 정보가 없으면 입력 팝업 표시
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) {
                        return ShippingInfoInputPopup(
                          initialCarrier: _shippingInfo?['carrier'] as String?,
                          initialTrackingNumber: _shippingInfo?['tracking_number'] as String?,
                          onConfirm: (carrier, trackingNumber) async {
                            try {
                              if (_shippingInfo != null) {
                                // 기존 정보가 있으면 택배사만 수정 (송장 번호는 수정 불가)
                                final existingTrackingNumber = _shippingInfo?['tracking_number'] as String?;
                                await _shippingInfoRepository.updateShippingInfo(
                                  itemId: widget.item.itemId,
                                  carrier: carrier,
                                  trackingNumber: existingTrackingNumber ?? trackingNumber, // 기존 송장 번호 유지
                                );
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('택배사 정보가 수정되었습니다'),
                                    ),
                                  );
                                }
                              } else {
                                // 기존 정보가 없으면 새로 저장
                                await _shippingInfoRepository.saveShippingInfo(
                                  itemId: widget.item.itemId,
                                  carrier: carrier,
                                  trackingNumber: trackingNumber,
                                );
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('송장 정보가 입력되었습니다'),
                                    ),
                                  );
                                }
                              }
                              // 정보 다시 로드
                              await _loadShippingInfo();
                            } catch (e) {
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                    content: Text('송장 정보 저장 실패: ${e.toString()}'),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: defaultBorder,
                  ),
                ),
                child: Text(
                  (_shippingInfo != null && 
                   _shippingInfo?['tracking_number'] != null &&
                   (_shippingInfo?['tracking_number'] as String?)?.isNotEmpty == true)
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
  }
}

