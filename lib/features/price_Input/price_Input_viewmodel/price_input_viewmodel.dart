import 'package:flutter/material.dart';

import '../price_Input_data/price_input_data.dart';
import '../price_Input_repository/price_input_repository.dart';

class PriceInputViewModel extends ChangeNotifier {
  PriceInputViewModel({PriceInputRepository? repository})
      : _repository = repository ?? PriceInputRepository();

  final PriceInputRepository _repository;

  bool isSubmitting = false;

  Future<void> placeBid(
    BuildContext context, {
    required String itemId,
    required int bidPrice,
  }) async {
    if (isSubmitting) return;

    isSubmitting = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);

    try {
      final request = BidRequest(itemId: itemId, bidPrice: bidPrice);
      await _repository.placeBid(request);

      messenger.showSnackBar(
        const SnackBar(content: Text('입찰이 완료되었습니다.')),
      );

      Navigator.of(context).pop();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('입찰 중 오류가 발생했습니다: $e')),
      );
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }
}