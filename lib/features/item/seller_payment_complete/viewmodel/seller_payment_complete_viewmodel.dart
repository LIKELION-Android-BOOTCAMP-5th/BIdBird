import 'package:bidbird/core/widgets/components/pop_up/shipping_info_input_popup.dart';
import 'package:bidbird/core/widgets/components/pop_up/shipping_info_view_popup.dart';
import 'package:bidbird/features/item/bid_win/model/item_bid_win_entity.dart';
import 'package:bidbird/features/item/shipping/data/repository/shipping_info_repository.dart';
import 'package:flutter/material.dart';

class SellerPaymentCompleteViewModel extends ChangeNotifier {
  SellerPaymentCompleteViewModel({
    required this.item,
    ShippingInfoRepository? repository,
  }) : _repository = repository ?? ShippingInfoRepositoryImpl();

  final ItemBidWinEntity item;
  final ShippingInfoRepository _repository;

  Map<String, dynamic>? _shippingInfo;
  bool _isLoadingShippingInfo = true;

  Map<String, dynamic>? get shippingInfo => _shippingInfo;
  bool get isLoadingShippingInfo => _isLoadingShippingInfo;
  bool get hasShippingInfo => _shippingInfo != null &&
      _shippingInfo?['tracking_number'] != null &&
      (_shippingInfo?['tracking_number'] as String?)?.isNotEmpty == true;

  Future<void> loadShippingInfo() async {
    _isLoadingShippingInfo = true;
    notifyListeners();

    try {
      _shippingInfo = await _repository.getShippingInfo(item.itemId);
    } catch (e) {
      // 에러는 조용히 처리
    } finally {
      _isLoadingShippingInfo = false;
      notifyListeners();
    }
  }

  Future<void> showShippingInfoDialog(BuildContext context) async {
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
              await _saveOrUpdateShippingInfo(
                context: dialogContext,
                carrier: carrier,
                trackingNumber: trackingNumber,
              );
            },
          );
        },
      );
    }
  }

  Future<void> _saveOrUpdateShippingInfo({
    required BuildContext context,
    required String carrier,
    required String trackingNumber,
  }) async {
    try {
      if (_shippingInfo != null) {
        // 기존 정보가 있으면 택배사만 수정 (송장 번호는 수정 불가)
        final existingTrackingNumber = _shippingInfo?['tracking_number'] as String?;
        await _repository.updateShippingInfo(
          itemId: item.itemId,
          carrier: carrier,
          trackingNumber: existingTrackingNumber ?? trackingNumber,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('택배사 정보가 수정되었습니다'),
            ),
          );
        }
      } else {
        // 기존 정보가 없으면 새로 저장
        await _repository.saveShippingInfo(
          itemId: item.itemId,
          carrier: carrier,
          trackingNumber: trackingNumber,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('송장 정보가 입력되었습니다'),
            ),
          );
        }
      }
      // 정보 다시 로드
      await loadShippingInfo();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('송장 정보 저장 실패: ${e.toString()}'),
          ),
        );
      }
    }
  }
}


