import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository/item_detail_repository.dart';

class ItemDetailViewModel extends ChangeNotifier {
  final String itemId;
  final ItemDetailRepository _repository;

  ItemDetailViewModel({required this.itemId, ItemDetailRepository? repository})
    : _repository = repository ?? ItemDetailRepository();

  ItemDetail? _itemDetail;
  ItemDetail? get itemDetail => _itemDetail;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  bool _isFavorite = false;
  bool get isFavorite => _isFavorite;

  bool _isTopBidder = false;
  bool get isTopBidder => _isTopBidder;

  bool _isMyItem = false;
  bool get isMyItem => _isMyItem;

  Map<String, dynamic>? _sellerProfile;
  Map<String, dynamic>? get sellerProfile => _sellerProfile;

  List<Map<String, dynamic>> _bidHistory = [];
  List<Map<String, dynamic>> get bidHistory => _bidHistory;

  RealtimeChannel? _bidStatusChannel;
  bool _isLoadingDetail = false;

  Future<void> loadItemDetail() async {
    // 중복 로딩 방지
    if (_isLoadingDetail) return;
    
    _isLoadingDetail = true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _itemDetail = await _repository.fetchItemDetail(itemId);

      if (_itemDetail == null) {
        _error = '상품을 찾을 수 없습니다.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _isLoading = false;
      notifyListeners();

      // 추가 데이터 로딩 - 부분 실패 허용
      await Future.wait([
        _checkIsMyItem(),
        _loadFavoriteState(),
        _checkTopBidder(),
        _loadSellerProfile(),
        _loadBidHistory(),
      ], eagerError: false);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    } finally {
      _isLoadingDetail = false;
    }
  }

  Future<void> _loadFavoriteState() async {
    try {
      _isFavorite = await _repository.checkIsFavorite(itemId);
      notifyListeners();
    } catch (e) {
      // 즐겨찾기 상태 로드 실패 시 기본값 유지
    }
  }

  Future<void> _checkTopBidder() async {
    try {
      _isTopBidder = await _repository.checkIsTopBidder(itemId);
      notifyListeners();
    } catch (e) {
      // 최고 입찰자 확인 실패 시 기본값 유지
    }
  }

  Future<void> _checkIsMyItem() async {
    if (_itemDetail != null) {
      try {
        _isMyItem = await _repository.checkIsMyItem(itemId, _itemDetail!.sellerId);
        notifyListeners();
      } catch (e) {
        // 내 아이템 확인 실패 시 기본값 유지
      }
    }
  }

  Future<void> _loadSellerProfile() async {
    if (_itemDetail?.sellerId != null) {
      try {
        _sellerProfile = await _repository.fetchSellerProfile(
          _itemDetail!.sellerId,
        );
        notifyListeners();
      } catch (e) {
        // 판매자 프로필 로드 실패 시 null 유지
      }
    }
  }

  Future<void> _loadBidHistory() async {
    try {
      _bidHistory = await _repository.fetchBidHistory(itemId);
      notifyListeners();
    } catch (e) {
      // 입찰 내역 로드 실패 시 빈 리스트 유지
    }
  }

  Future<void> toggleFavorite() async {
    try {
      await _repository.toggleFavorite(itemId, _isFavorite);
      _isFavorite = !_isFavorite;
      notifyListeners();
    } catch (e) {
      // toggle favorite 실패 시 조용히 처리
    }
  }

  void setupRealtimeSubscription() {
    // auctions: 현재가, 최고 입찰자, 상태 코드 변경 감지
    _bidStatusChannel = _repository.supabase.channel('auctions_$itemId');
    _bidStatusChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'auctions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'item_id',
            value: itemId,
          ),
          callback: (payload) {
            loadItemDetail();
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    if (_bidStatusChannel != null) {
      _repository.supabase.removeChannel(_bidStatusChannel!);
    }
    super.dispose();
  }
}
