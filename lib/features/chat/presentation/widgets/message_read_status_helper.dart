import 'package:bidbird/features/chat/domain/entities/chat_message_entity.dart';

/// 메시지 읽음 상태 계산 헬퍼
/// 메시지의 읽음/안읽음 상태를 계산하는 로직을 분리한 클래스
class MessageReadStatusHelper {
  /// 메시지의 읽음 상태 계산
  /// [messages] 전체 메시지 리스트
  /// [index] 현재 메시지 인덱스
  /// [userId] 현재 사용자 ID
  /// [isCurrentUser] 현재 사용자가 보낸 메시지인지 여부
  /// 
  /// Returns: (isRead, isUnread) 튜플
  static (bool isRead, bool isUnread) getReadStatus(
    List<ChatMessageEntity> messages,
    int index,
    String? userId,
    bool isCurrentUser,
  ) {
    bool isRead = false;
    bool isUnread = false;

    if (isCurrentUser && userId != null) {
      // 내가 보낸 메시지: 상대방이 읽었는지 확인
      // 가장 최근에 읽은 내 메시지 하나에만 읽음 표시
      // 마지막 내 메시지가 아직 읽지 않았다면 안읽음 표시

      // 마지막 내 메시지의 인덱스 찾기
      int? lastMyMessageIndex;
      for (int i = messages.length - 1; i >= 0; i--) {
        if (messages[i].senderId == userId) {
          lastMyMessageIndex = i;
          break;
        }
      }

      // 상대방이 읽은 가장 최근 내 메시지의 인덱스 찾기
      // 상대방이 메시지를 보낸 시점 이전의 마지막 내 메시지
      int? lastReadMyMessageIndex;
      for (int i = messages.length - 1; i >= 0; i--) {
        // 상대방 메시지를 찾으면, 그 이전의 마지막 내 메시지가 가장 최근에 읽은 메시지
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

      // 현재 메시지가 마지막 내 메시지인지 확인
      final isLastMyMessage = lastMyMessageIndex != null && index == lastMyMessageIndex;

      if (isLastMyMessage) {
        // 마지막 내 메시지인 경우
        if (lastReadMyMessageIndex == null) {
          // 상대방이 아직 메시지를 보내지 않았거나, 모든 내 메시지가 읽지 않은 것
          isUnread = true;
        } else if (lastReadMyMessageIndex < index) {
          // 마지막 내 메시지가 읽지 않은 것 (상대방이 읽은 마지막 메시지보다 나중)
          isUnread = true;
        } else if (index == lastReadMyMessageIndex) {
          // 마지막 내 메시지가 가장 최근에 읽은 메시지
          isRead = true;
        }
      } else {
        // 마지막 내 메시지가 아닌 경우
        if (lastReadMyMessageIndex != null && index == lastReadMyMessageIndex) {
          // 가장 최근에 읽은 내 메시지
          isRead = true;
        }
      }
    }
    // 상대방이 보낸 메시지는 읽음 표시 없음 (isRead는 이미 false)

    return (isRead, isUnread);
  }
}



