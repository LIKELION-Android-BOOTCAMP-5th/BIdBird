import 'package:bidbird/core/managers/supabase_manager.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:bidbird/features/chat/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 채팅 메시지 리스트 위젯
/// 메시지 목록을 표시하고 스크롤을 관리
class ChatMessageList extends StatelessWidget {
  final ChattingRoomViewmodel viewModel;

  const ChatMessageList({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: viewModel.isScrollPositionReady ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 0), // 즉시 표시 (애니메이션 없음)
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollEndNotification) {
            // 초기 로드가 아닐 때만 스크롤 처리 (사용자가 수동으로 스크롤한 경우)
            // 스크롤이 끝났을 때 roomInfo를 업데이트하여 unreadCount 변경 감지 (디바운스 적용)
            viewModel.fetchRoomInfoDebounced();
          }
          return false;
        },
        child: ListView.builder(
          controller: viewModel.scrollController,
          itemCount: viewModel.messages.length,
          reverse: false,
          cacheExtent: 0,
          padding: const EdgeInsets.only(bottom: 16),
          physics: viewModel.listViewPhysics ?? const ClampingScrollPhysics(),
          itemBuilder: (context, index) {
            return _buildMessageItem(context, index);
          },
        ),
      ),
    );
  }

  Widget _buildMessageItem(BuildContext context, int index) {
    final message = viewModel.messages[index];
    final userId = SupabaseManager.shared.supabase.auth.currentUser?.id;
    final isCurrentUser = message.senderId == userId;

    // 같은 사람이 연속해서 보낸 메시지 중 마지막인지 여부 (시간 표시용)
    final bool isLastFromSameSender;
    if (index == viewModel.messages.length - 1) {
      isLastFromSameSender = true;
    } else {
      final nextMessage = viewModel.messages[index + 1];
      isLastFromSameSender = nextMessage.senderId != message.senderId;
    }

    // 같은 사람이 연속해서 보낸 메시지 중 첫 번째인지 여부 (아바타 표시용)
    final bool isFirstFromSameSender;
    if (index == 0) {
      isFirstFromSameSender = true;
    } else {
      final prevMessage = viewModel.messages[index - 1];
      isFirstFromSameSender = prevMessage.senderId != message.senderId;
    }

    // 날짜 구분 표시 여부 계산
    final showDateHeader = _shouldShowDateHeader(index);

    // 메시지 읽음 여부 확인
    final (isRead, isUnread) = _getReadStatus(index, userId, isCurrentUser);

    Widget messageWidget = _buildMessageBubble(
      context,
      message,
      isCurrentUser,
      isLastFromSameSender,
      isFirstFromSameSender,
      isRead,
      isUnread,
    );

    if (showDateHeader) {
      DateTime? currentDate;
      try {
        currentDate = DateTime.parse(message.createdAt).toLocal();
      } catch (_) {
        currentDate = null;
      }

      if (currentDate != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.spacingSmall,
              ),
              child: _ChatDateSeparator(date: currentDate),
            ),
            messageWidget,
          ],
        );
      }
    }

    return messageWidget;
  }

  bool _shouldShowDateHeader(int index) {
    DateTime? currentDate;
    DateTime? previousDate;
    try {
      currentDate = DateTime.parse(viewModel.messages[index].createdAt).toLocal();
      if (index > 0) {
        previousDate = DateTime.parse(viewModel.messages[index - 1].createdAt).toLocal();
      }
    } catch (_) {
      return false;
    }

    if (previousDate == null) {
      // 첫 번째 메시지는 항상 날짜 표시
      return true;
    } else {
      return !_isSameDay(currentDate, previousDate);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  (bool isRead, bool isUnread) _getReadStatus(
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
      for (int i = viewModel.messages.length - 1; i >= 0; i--) {
        if (viewModel.messages[i].senderId == userId) {
          lastMyMessageIndex = i;
          break;
        }
      }

      // 상대방이 읽은 가장 최근 내 메시지의 인덱스 찾기
      // 상대방이 메시지를 보낸 시점 이전의 마지막 내 메시지
      int? lastReadMyMessageIndex;
      for (int i = viewModel.messages.length - 1; i >= 0; i--) {
        // 상대방 메시지를 찾으면, 그 이전의 마지막 내 메시지가 가장 최근에 읽은 메시지
        if (viewModel.messages[i].senderId != userId) {
          // 상대방 메시지 이전의 내 메시지 찾기
          for (int j = i - 1; j >= 0; j--) {
            if (viewModel.messages[j].senderId == userId) {
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

  Widget _buildMessageBubble(
    BuildContext context,
    dynamic message,
    bool isCurrentUser,
    bool isLastFromSameSender,
    bool isFirstFromSameSender,
    bool isRead,
    bool isUnread,
  ) {
    if (isCurrentUser) {
      return Padding(
        padding: EdgeInsets.only(
          top: isFirstFromSameSender ? 10 : 4,
        ),
        child: MessageBubble(
          message: message,
          isCurrentUser: true,
          showTime: isLastFromSameSender,
          isRead: isRead,
          isUnread: isUnread,
        ),
      );
    } else {
      // 상대방 메시지: 왼쪽에 프로필, 오른쪽에 말풍선
      final double avatarSize = context.isLargeScreen() ? 42 : 36;
      final opponent = viewModel.roomInfo?.opponent;

      Widget avatarWidget;
      if (isFirstFromSameSender) {
        final String? profileImageUrl = opponent?.profileImage;
        avatarWidget = CircleAvatar(
          radius: avatarSize / 2,
          backgroundColor: const Color(0xFFE5E7EB), // BorderColor
          backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
              ? NetworkImage(profileImageUrl)
              : null,
          child: profileImageUrl != null && profileImageUrl.isNotEmpty
              ? null
              : const Icon(
                  Icons.person,
                  color: Color(0xFFF5F6F8), // BackgroundColor
                ),
        );
      } else {
        avatarWidget = SizedBox(
          width: avatarSize,
          height: avatarSize,
        );
      }

      return Padding(
        padding: EdgeInsets.only(
          left: context.spacingSmall,
          right: context.spacingSmall,
          top: isFirstFromSameSender ? 10 : 4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            avatarWidget,
            SizedBox(width: context.spacingSmall),
            Expanded(
              child: MessageBubble(
                message: message,
                isCurrentUser: false,
                showTime: isLastFromSameSender,
                isRead: isRead,
              ),
            ),
          ],
        ),
      );
    }
  }
}

/// 날짜 구분선 위젯
class _ChatDateSeparator extends StatelessWidget {
  final DateTime date;

  const _ChatDateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    final isToday = messageDate == today;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isToday
              ? const Color(0xFFE3E7EE) // 오늘 날짜 강조
              : const Color(0xFFEDEFF2), // 기본 배경
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today,
              size: 12,
              color: isToday
                  ? const Color(0xFF3C4043) // 오늘 날짜 텍스트
                  : const Color(0xFF5F6368), // 기본 텍스트
            ),
            const SizedBox(width: 6),
            Text(
              isToday
                  ? '오늘'
                  : DateFormat('yyyy년 M월 d일').format(date),
              style: TextStyle(
                color: isToday
                    ? const Color(0xFF3C4043) // 오늘 날짜 텍스트
                    : const Color(0xFF5F6368), // 기본 텍스트
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

