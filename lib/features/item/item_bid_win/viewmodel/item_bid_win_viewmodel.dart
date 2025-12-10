import 'package:flutter/foundation.dart';

import '../data/repository/item_bid_win_repository.dart';
import '../model/item_bid_win_entity.dart';
import '../../detail/model/item_detail_entity.dart';

class ItemBidWinViewModel extends ChangeNotifier {
  ItemBidWinViewModel({ItemBidWinRepository? repository})
      : _repository = repository ?? ItemBidWinRepository();

  final ItemBidWinRepository _repository;

  ItemBidWinEntity? _item;
  ItemBidWinEntity? get item => _item;

  bool _isPaying = false;
  bool get isPaying => _isPaying;

  String? _error;
  String? get error => _error;

  void initWithDetail(ItemDetail detail) {
    _item = _repository.fromItemDetail(detail);
    notifyListeners();
  }

  Future<void> startPayment() async {
    if (_item == null || _isPaying) return;
    _isPaying = true;
    _error = null;
    notifyListeners();

    try {
      // TODO: 결제 API 연동 및 상태 업데이트
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }
}
