import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
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
              height: 48,
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
                child: const Text(
                  '구매자 연락하기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
                child: ElevatedButton(
                  onPressed: () {
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
                                // 기존 정보가 있으면 수정
                                await _shippingInfoRepository.updateShippingInfo(
                                  itemId: widget.item.itemId,
                                  carrier: carrier,
                                  trackingNumber: trackingNumber,
                                );
                                if (dialogContext.mounted) {
                                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                                    const SnackBar(
                                      content: Text('송장 정보가 수정되었습니다'),
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
                  },
                style: ElevatedButton.styleFrom(
                  backgroundColor: blueColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: defaultBorder,
                  ),
                ),
                child: Text(
                  _shippingInfo != null ? '배송 정보 수정하기' : '배송 정보 입력하기',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
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

