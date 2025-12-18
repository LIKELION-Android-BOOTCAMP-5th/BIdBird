import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/chat/presentation/viewmodels/chatting_room_viewmodel.dart';
import 'package:flutter/material.dart';

/// 채팅 입력 영역 위젯
/// 텍스트 입력 필드, + 버튼, 전송 버튼을 포함
class ChatInputArea extends StatefulWidget {
  final ChattingRoomViewmodel viewModel;
  final FocusNode focusNode;
  final VoidCallback onImageSourceSheet;

  const ChatInputArea({
    super.key,
    required this.viewModel,
    required this.focusNode,
    required this.onImageSourceSheet,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() {
      setState(() {}); // 포커스 상태 변경 시 리빌드
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.viewModel.messageController.text.trim().isNotEmpty;
    final hasImages = widget.viewModel.images.isNotEmpty;
    final canSend = hasText || hasImages; // 텍스트 또는 이미지가 있으면 전송 가능

    return SafeArea(
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFFFFFF), // 입력 영역 배경
          border: Border(
            top: BorderSide(
              color: Color(0xFFE5E7EB), // 상단 divider
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          context.screenPadding,
          8,
          context.screenPadding,
          8,
        ),
        child: Row(
          children: [
            // 왼쪽 + 버튼
            InkWell(
              onTap: widget.onImageSourceSheet,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: context.isLargeScreen() ? 40 : 36,
                height: context.isLargeScreen() ? 40 : 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.add,
                  color: Color(0xFF5F6368),
                  size: 20,
                ),
              ),
            ),
            SizedBox(width: context.spacingSmall),
            // 가운데 입력 필드
            Expanded(
              child: Builder(
                builder: (context) {
                  final hasFocus = widget.focusNode.hasFocus;

                  return Container(
                    constraints: const BoxConstraints(
                      minHeight: 40,
                      maxHeight: 96,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: context.inputPadding,
                      vertical: 0,
                    ),
                    decoration: BoxDecoration(
                      color: hasFocus
                          ? const Color(0xFFFFFFFF)
                          : const Color(0xFFF5F6F8),
                      borderRadius: BorderRadius.circular(20),
                      border: hasFocus
                          ? Border.all(
                              color: const Color(0xFFD0D5DD),
                              width: 1,
                            )
                          : null,
                      boxShadow: hasFocus
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: TextField(
                      focusNode: widget.focusNode,
                      minLines: 1,
                      maxLines: 4,
                      controller: widget.viewModel.messageController,
                      style: TextStyle(
                        fontSize: context.fontSizeMedium,
                        color: const Color(0xFF111111),
                      ),
                      textAlignVertical: TextAlignVertical.center,
                      decoration: InputDecoration(
                        hintText: "메시지를 입력하세요",
                        hintStyle: TextStyle(
                          color: const Color(0xFF9AA0A6),
                          fontSize: context.fontSizeMedium,
                        ),
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {}); // 전송 버튼 상태 업데이트
                      },
                      onTap: () {
                        setState(() {}); // 포커스 상태 업데이트
                      },
                      onSubmitted: (value) {
                        if (!widget.viewModel.isSending && canSend) {
                          widget.viewModel.sendMessage();
                          // 입력창 리셋
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              setState(() {});
                            }
                          });
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: context.spacingSmall),
            // 오른쪽 전송 버튼
            InkWell(
              onTap: (!canSend || widget.viewModel.isSending)
                  ? null
                  : () {
                      widget.viewModel.sendMessage();
                      // 입력창 리셋
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {});
                        }
                      });
                    },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: context.isLargeScreen() ? 40 : 36,
                height: context.isLargeScreen() ? 40 : 36,
                decoration: BoxDecoration(
                  color: !canSend
                      ? const Color(0xFFE0E3E7) // Disabled
                      : const Color(0xFF4F7CF5), // Enabled
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: widget.viewModel.isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: !canSend
                              ? const Color(0xFF9AA0A6) // Disabled
                              : Colors.white, // Enabled
                          size: 20,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

