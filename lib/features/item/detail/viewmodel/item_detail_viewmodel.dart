import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/item/detail/model/item_detail_entity.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/repository/item_detail_repository.dart';

class ItemDetailViewModel extends ChangeNotifier {
  final String itemId;
  final ItemDetailRepository _repository;

  ItemDetailViewModel({required this.itemId, ItemDetailRepository? repository})
    : _repository = repository ?? ItemDetailRepository() {
    _supabase = SupabaseManager.shared.supabase;
  }

  late final SupabaseClient _supabase;

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

  Map<String, dynamic>? _sellerProfile;
  Map<String, dynamic>? get sellerProfile => _sellerProfile;

  List<Map<String, dynamic>> _bidHistory = [];
  List<Map<String, dynamic>> get bidHistory => _bidHistory;

  RealtimeChannel? _bidStatusChannel;
  RealtimeChannel? _bidLogChannel;

  Future<void> loadItemDetail() async {
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

      // 추가 데이터 로딩
      await Future.wait([
        _loadFavoriteState(),
        _checkTopBidder(),
        _loadSellerProfile(),
        _loadBidHistory(),
      ]);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteState() async {
    _isFavorite = await _repository.checkIsFavorite(itemId);
    notifyListeners();
  }

  Future<void> _checkTopBidder() async {
    _isTopBidder = await _repository.checkIsTopBidder(itemId);
    notifyListeners();
  }

  Future<void> _loadSellerProfile() async {
    if (_itemDetail?.sellerId != null) {
      _sellerProfile = await _repository.fetchSellerProfile(
        _itemDetail!.sellerId,
      );
      notifyListeners();
    }
  }

  Future<void> _loadBidHistory() async {
    _bidHistory = await _repository.fetchBidHistory(itemId);
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    try {
      await _repository.toggleFavorite(itemId, _isFavorite);
      _isFavorite = !_isFavorite;
      notifyListeners();
    } catch (e) {
      debugPrint('[ItemDetailViewModel] toggle favorite error: $e');
    }
  }

  void setupRealtimeSubscription() {
    // auctions: 현재가, 최고 입찰자, 상태 코드 변경 감지
    _bidStatusChannel = _supabase.channel('auctions_$itemId');
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
            debugPrint('[ItemDetailViewModel] auctions 변경 감지');
            loadItemDetail();
          },
        )
        .subscribe();

    // bid_log 는 더 이상 사용하지 않으므로 채널 생성 안 함
    if (_bidLogChannel != null) {
      _supabase.removeChannel(_bidLogChannel!);
      _bidLogChannel = null;
    }
  }

  @override
  void dispose() {
    if (_bidStatusChannel != null) _supabase.removeChannel(_bidStatusChannel!);
    if (_bidLogChannel != null) _supabase.removeChannel(_bidLogChannel!);
    super.dispose();
  }
}
