import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/data/repositories/chat_repositorie.dart';
import 'package:bidbird/features/chat/model/chatting_room_entity.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatListViewmodel extends ChangeNotifier {
  ChatRepositorie _repository = ChatRepositorie();
  List<ChattingRoomEntity> chattingRoomList = [];
  bool isLoading = false;
  RealtimeChannel? _isBuyerChannel;
  RealtimeChannel? _isSellerChannel;

  // int inputCount = 0;

  // final TextEditingController textEditingController = TextEditingController();

  // 뷰모델 생성자, context를 통해 리포지토리를 받아올 수 있음.
  ChatListViewmodel(BuildContext context) {
    fetchChattingRoomList();
    setupRealtimeSubscription();
  }

  Future<void> fetchChattingRoomList() async {
    isLoading = true;
    notifyListeners();
    chattingRoomList = await _repository.fetchChattingRoomList();
    isLoading = false;
    notifyListeners();
  }

  Future<void> reloadList() async {
    chattingRoomList = [];
    chattingRoomList = await _repository.fetchChattingRoomList();
    notifyListeners();
  }

  void setupRealtimeSubscription() {
    final currentId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (currentId == null) return;
    _isBuyerChannel = SupabaseManager.shared.supabase.channel(
      'chattingRoomByBuyer',
    );
    _isBuyerChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chatting_room',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buyer_id',
            value: currentId,
          ),
          callback: (payload) {
            reloadList();
          },
        )
        .subscribe();

    _isSellerChannel = SupabaseManager.shared.supabase.channel(
      'chattingRoomBySeller',
    );
    _isSellerChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'chatting_room',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: currentId,
          ),
          callback: (payload) {
            reloadList();
          },
        )
        .subscribe();
    print("채팅 리스트 뷰모델의 채널들이 연결 되었습니다");
  }

  @override
  void dispose() {
    if (_isBuyerChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_isBuyerChannel!);
    if (_isSellerChannel != null)
      SupabaseManager.shared.supabase.removeChannel(_isSellerChannel!);
    print("채팅 리스트 뷰모델의 채널들이 닫혔습니다");
    // if (_itemsChannel != null) _supabase.removeChannel(_itemsChannel!);
    // if (_bidLogChannel != null) _supabase.removeChannel(_bidLogChannel!);
    super.dispose();
  }

  // 입력한 글자 수를 받아오는 함수
  // void handleTextInput(String input) {
  //   inputCount = input.length;
  //   notifyListeners();
  // }

  // Future 함수는 API나 Supabase, 메소드 채널과 사용할 때,
  // 처리를 하는데 시간이 걸리는 작업을 할때 사용됨.
  // 아래 함수 안 에서는 시간이 필요한 작업은 await를 사용 해야함
  // Future<void> function() async {
  //   try {
  //
  //   } catch (e) {
  //
  //   }
  //
  //   // 리빌딩, 리콤포지션 진행
  //   notifyListeners();
  // }
  // Future<void> function1() async {
  //   // 시간 지연 코드
  //   await Future.delayed(const Duration(milliseconds: 1700));
  //   notifyListeners();
  // }
}
