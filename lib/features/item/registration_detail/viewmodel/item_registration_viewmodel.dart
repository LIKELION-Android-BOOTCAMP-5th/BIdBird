import 'package:flutter/material.dart';

import '../data/repository/item_registration_repository.dart';

class ItemRegistrationDetailViewModel extends ChangeNotifier {
  ItemRegistrationDetailViewModel({ItemRegistrationRepository? repository})
      : _repository = repository ?? ItemRegistrationRepository();

  final ItemRegistrationRepository _repository;

  bool isRegistering = false;

  DateTime getNextAuctionStartTime() {
    final DateTime now = DateTime.now();
    final int minute = now.minute;
    if (minute % 10 == 0) {
      return DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        minute,
      );
    }

    final int addMinutes = 10 - (minute % 10);
    final DateTime added = now.add(Duration(minutes: addMinutes));
    return DateTime(
      added.year,
      added.month,
      added.day,
      added.hour,
      added.minute,
    );
  }

  Future<bool> registerItem(
      BuildContext context, String itemId, DateTime auctionStartAt) async {
    if (isRegistering) return false;

    isRegistering = true;
    notifyListeners();

    final messenger = ScaffoldMessenger.of(context);

    try {
      await _repository.registerItem(itemId, auctionStartAt);


      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('등록 중 오류가 발생했습니다: $e')),
      );
      return false;
    } finally {
      isRegistering = false;
    }
  }
}
