import 'package:flutter/material.dart';

import '../data/datasource/item_bid_win_datasource.dart';
import '../model/item_bid_win_entity.dart';
import '../../detail/model/item_detail_entity.dart';

class ItemBidWinViewModel extends ChangeNotifier {
  ItemBidWinViewModel({ItemBidWinDatasource? datasource})
      : _datasource = datasource ?? ItemBidWinDatasource();

  final ItemBidWinDatasource _datasource;

  ItemBidWinEntity? _item;
  ItemBidWinEntity? get item => _item;

  bool _isPaying = false;
  bool get isPaying => _isPaying;

  String? _error;
  String? get error => _error;

  void initWithDetail(ItemDetail detail) {
    _item = _datasource.toEntityFromDetail(detail);
    notifyListeners();
  }

  Future<void> startPayment() async {
    if (_item == null || _isPaying) return;
    _isPaying = true;
    _error = null;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }
}
