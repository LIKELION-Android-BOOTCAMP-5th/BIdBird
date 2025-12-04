import 'package:flutter/material.dart';

import '../data/repository/item_registration_repository.dart';
import '../model/item_registration_entity.dart';

class ItemRegistrationViewModel extends ChangeNotifier {
  ItemRegistrationViewModel({ItemRegistrationRepository? repository})
      : _repository = repository ?? ItemRegistrationRepository();

  final ItemRegistrationRepository _repository;

  bool isLoading = false;
  bool isRegistering = false;
  List<ItemRegistrationData> items = <ItemRegistrationData>[];

  Future<void> init() async {
    await fetchMyPendingItems();
  }

  Future<void> fetchMyPendingItems() async {
    isLoading = true;
    notifyListeners();

    try {
      items = await _repository.fetchMyPendingItems();
    } catch (e) {
      // TODO: 에러 로깅 또는 처리
      items = <ItemRegistrationData>[];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

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
