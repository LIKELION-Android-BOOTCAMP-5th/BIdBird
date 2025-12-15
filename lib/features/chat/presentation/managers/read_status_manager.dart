import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';

/// 읽음 상태 관리자
/// 메시지 읽음 처리 로직을 관리하는 클래스
class ReadStatusManager {
  /// unread_count를 기반으로 마지막으로 본 메시지까지 읽음 처리
  /// 
  /// [messages] 메시지 리스트
  /// [unreadCount] 읽지 않은 메시지 수
  /// [onMarkAsRead] 읽음 처리 콜백 (선택적)
  /// 
  /// Returns: 마지막으로 본 메시지의 인덱스 (-1이면 모든 메시지가 읽음)
  int markMessagesAsReadUpToLastViewed(
    List<ChatMessageEntity> messages,
    int unreadCount, {
    void Function(ChatMessageEntity)? onMarkAsRead,
  }) {
    if (messages.isEmpty) return -1;

    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    if (userId == null) return -1;

    // unread_count가 0이면 모든 메시지가 읽음 처리됨
    if (unreadCount <= 0) {
      return -1; // 모든 메시지가 읽음 처리된 상태
    }

    // unread_count를 기반으로 마지막으로 본 메시지 인덱스 계산
    // unread_count가 N이면, 최신 메시지부터 N개가 읽지 않은 메시지
    // 따라서 messages.length - unreadCount 번째 메시지가 마지막으로 본 메시지
    final lastViewedIndex = messages.length - unreadCount;

    if (lastViewedIndex < 0 || lastViewedIndex >= messages.length) {
      // 인덱스가 유효하지 않으면 처리하지 않음
      return -1;
    }

    // 마지막으로 본 메시지의 시간 가져오기
    final lastViewedMessage = messages[lastViewedIndex];
    DateTime? lastViewedTime;
    try {
      lastViewedTime = DateTime.parse(lastViewedMessage.createdAt).toLocal();
    } catch (e) {
      // 날짜 파싱 오류 시 처리하지 않음
      return -1;
    }

    // 마지막으로 본 메시지 시간 이하의 모든 메시지를 읽음 처리
    // (본인이 보낸 메시지는 제외)
    for (int i = 0; i < messages.length; i++) {
      try {
        final messageTime = DateTime.parse(messages[i].createdAt).toLocal();
        // 마지막으로 본 메시지 시간 이하이고, 본인이 보낸 메시지가 아니면 읽음 처리
        if (!messageTime.isAfter(lastViewedTime) &&
            messages[i].senderId != userId) {
          onMarkAsRead?.call(messages[i]);
        }
      } catch (e) {
        // 날짜 파싱 오류 무시
        continue;
      }
    }

    return lastViewedIndex;
  }

  /// 읽지 않은 메시지가 있는지 확인하고 첫 번째 읽지 않은 메시지의 인덱스를 반환
  /// 
  /// [messages] 메시지 리스트
  /// [unreadCount] 읽지 않은 메시지 수
  /// [lastMessageAt] 마지막으로 본 메시지 시간 (ISO 문자열)
  /// 
  /// Returns: 첫 번째 읽지 않은 메시지의 인덱스 (-1이면 읽지 않은 메시지 없음)
  int findFirstUnreadMessageIndex(
    List<ChatMessageEntity> messages,
    int unreadCount,
    DateTime? lastMessageAt,
  ) {
    if (messages.isEmpty) return -1;

    // 읽지 않은 메시지가 없으면 -1 반환
    if (unreadCount <= 0) return -1;

    // 마지막 메시지 시간이 없으면 -1 반환
    if (lastMessageAt == null) return -1;

    // 마지막 메시지 시간 이후의 첫 번째 메시지 찾기
    for (int i = 0; i < messages.length; i++) {
      try {
        final messageTime = DateTime.parse(messages[i].createdAt).toLocal();
        if (messageTime.isAfter(lastMessageAt)) {
          return i;
        }
      } catch (e) {
        // 날짜 파싱 오류 무시
        continue;
      }
    }

    return -1; // 읽지 않은 메시지를 찾을 수 없음
  }

  /// 내가 보낸 메시지의 읽음 상태 계산
  /// 
  /// [messages] 메시지 리스트
  /// [currentIndex] 현재 메시지 인덱스
  /// [userId] 현재 사용자 ID
  /// 
  /// Returns: (isRead, isUnread) 튜플
  ({bool isRead, bool isUnread}) calculateReadStatus(
    List<ChatMessageEntity> messages,
    int currentIndex,
    String userId,
  ) {
    if (messages.isEmpty || currentIndex < 0 || currentIndex >= messages.length) {
      return (isRead: false, isUnread: false);
    }

    final currentMessage = messages[currentIndex];
    
    // 상대방이 보낸 메시지는 읽음 표시 없음
    if (currentMessage.senderId != userId) {
      return (isRead: false, isUnread: false);
    }

    // 마지막 내 메시지의 인덱스 찾기
    int? lastMyMessageIndex;
    for (int i = messages.length - 1; i >= 0; i--) {
      if (messages[i].senderId == userId) {
        lastMyMessageIndex = i;
        break;
      }
    }

    if (lastMyMessageIndex == null) {
      return (isRead: false, isUnread: false);
    }

    // 현재 메시지가 마지막 내 메시지인지 확인
    final isLastMyMessage = currentIndex == lastMyMessageIndex;

    // 상대방이 읽은 가장 최근 내 메시지의 인덱스 찾기
    // 상대방이 메시지를 보낸 시점 이전의 마지막 내 메시지
    int? lastReadMyMessageIndex;
    for (int i = messages.length - 1; i >= 0; i--) {
      // 상대방 메시지를 찾으면, 그 이전의 내 메시지 찾기
      if (messages[i].senderId != userId) {
        // 상대방 메시지 이전의 내 메시지 찾기
        for (int j = i - 1; j >= 0; j--) {
          if (messages[j].senderId == userId) {
            lastReadMyMessageIndex = j;
            break;
          }
        }
        break;
      }
    }

    if (isLastMyMessage) {
      // 마지막 내 메시지인 경우
      if (lastReadMyMessageIndex == null) {
        // 상대방이 아직 메시지를 보내지 않았거나, 모든 내 메시지가 읽지 않은 것
        return (isRead: false, isUnread: true);
      } else if (lastReadMyMessageIndex < currentIndex) {
        // 마지막 내 메시지가 읽지 않은 것 (상대방이 읽은 마지막 메시지보다 나중)
        return (isRead: false, isUnread: true);
      } else if (currentIndex == lastReadMyMessageIndex) {
        // 마지막 내 메시지가 가장 최근에 읽은 메시지
        return (isRead: true, isUnread: false);
      }
    } else {
      // 마지막 내 메시지가 아닌 경우
      if (lastReadMyMessageIndex != null && currentIndex == lastReadMyMessageIndex) {
        // 가장 최근에 읽은 내 메시지
        return (isRead: true, isUnread: false);
      }
    }

    return (isRead: false, isUnread: false);
  }
}

