import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:bidbird/features/bid/data/datasources/item_bid_win_datasource.dart';
import 'package:bidbird/features/bid/data/repositories/bid_repository.dart';
import 'package:bidbird/features/bid/domain/repositories/bid_repository.dart' as domain;
import 'package:bidbird/features/bid/domain/entities/item_bid_win_entity.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chat_list_viewmodel.dart';

class ItemBidWinViewModel extends ChangeNotifier {
  ItemBidWinViewModel({ItemBidWinDatasource? datasource, domain.BidRepository? bidRepository})
      : _datasource = datasource ?? ItemBidWinDatasource(),
        _bidRepository = bidRepository ?? BidRepositoryImpl();

  final ItemBidWinDatasource _datasource;
  final domain.BidRepository _bidRepository;

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

  // 임시로 주석 처리: 결제 비활성화
  /*
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
  */

  // ignore: non_constant_identifier_names
  Future<void> Temporary_bid() async {
    if (_item == null || _isPaying) return;
    _isPaying = true;
    _error = null;
    notifyListeners();

    try {
      // 임시 코드: 사용자끼리 거래, 채팅 시작 또는 알림
      debugPrint('임시 거래 시작: itemId ${_item?.itemId}');
      // 채팅방 생성
      final roomId = await _bidRepository.createChatRoom(_item!.itemId, _item!.sellerId, _item!.buyerId);
      if (roomId != null) {
        // 채팅 목록 새로고침
        ChatListViewmodel.instance?.reloadList();
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }
}

