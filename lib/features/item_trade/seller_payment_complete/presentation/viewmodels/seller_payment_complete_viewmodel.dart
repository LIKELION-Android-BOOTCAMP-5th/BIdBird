import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_input_popup.dart';
import 'package:bidbird/features/item_trade/shipping/presentation/widgets/shipping_info_view_popup.dart';
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_trade/shipping/data/repositories/shipping_info_repository.dart';
import 'package:bidbird/features/item_trade/shipping/domain/usecases/get_shipping_info_usecase.dart';
import 'package:bidbird/features/item_trade/shipping/domain/usecases/save_shipping_info_usecase.dart';
import 'package:bidbird/features/item_trade/shipping/domain/usecases/update_shipping_info_usecase.dart';
import 'package:flutter/material.dart';

/// SellerPaymentComplete ViewModel - Thin Pattern
/// 책임: 판매자 결제 완료 UI 상태 관리
/// 제외: 비즈니스 로직 (UseCase에서 처리)
class SellerPaymentCompleteViewModel extends ChangeNotifier {
  SellerPaymentCompleteViewModel({
    required this.item,
    GetShippingInfoUseCase? getShippingInfoUseCase,
    SaveShippingInfoUseCase? saveShippingInfoUseCase,
    UpdateShippingInfoUseCase? updateShippingInfoUseCase,
  })  : _getShippingInfoUseCase =
            getShippingInfoUseCase ?? GetShippingInfoUseCase(ShippingInfoRepositoryImpl()),
        _saveShippingInfoUseCase =
            saveShippingInfoUseCase ?? SaveShippingInfoUseCase(ShippingInfoRepositoryImpl()),
        _updateShippingInfoUseCase = updateShippingInfoUseCase ??
            UpdateShippingInfoUseCase(ShippingInfoRepositoryImpl());

  final ItemBidWinEntity item;
  final GetShippingInfoUseCase _getShippingInfoUseCase;
  final SaveShippingInfoUseCase _saveShippingInfoUseCase;
  final UpdateShippingInfoUseCase _updateShippingInfoUseCase;

  // State: Shipping Info
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
      _shippingInfo = await _getShippingInfoUseCase(item.itemId);
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
        await _updateShippingInfoUseCase(
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
        await _saveShippingInfoUseCase(
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


