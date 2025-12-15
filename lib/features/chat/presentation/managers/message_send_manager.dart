import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
import 'package:bidbird/features/chat/domain/usecases/send_first_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_image_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:bidbird/features/chat/presentation/managers/message_sender.dart';
import 'package:image_picker/image_picker.dart';

/// 메시지 전송 결과
class MessageSendResult {
  final bool success;
  final String? errorMessage;
  final String? roomId; // 첫 메시지 전송 시 생성된 roomId
  final bool isFirstMessage; // 첫 메시지인지 여부

  MessageSendResult({
    required this.success,
    this.errorMessage,
    this.roomId,
    this.isFirstMessage = false,
  });

  factory MessageSendResult.success({
    String? roomId,
    bool isFirstMessage = false,
  }) {
    return MessageSendResult(
      success: true,
      roomId: roomId,
      isFirstMessage: isFirstMessage,
    );
  }

  factory MessageSendResult.failure(String errorMessage) {
    return MessageSendResult(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

/// 메시지 전송 관리자
/// ChattingRoomViewmodel의 sendMessage() 로직을 분리한 클래스
class MessageSendManager {
  final SendFirstMessageUseCase _sendFirstMessageUseCase;
  final SendTextMessageUseCase _sendTextMessageUseCase;
  final SendImageMessageUseCase _sendImageMessageUseCase;

  MessageSendManager({
    required SendFirstMessageUseCase sendFirstMessageUseCase,
    required SendTextMessageUseCase sendTextMessageUseCase,
    required SendImageMessageUseCase sendImageMessageUseCase,
  })  : _sendFirstMessageUseCase = sendFirstMessageUseCase,
        _sendTextMessageUseCase = sendTextMessageUseCase,
        _sendImageMessageUseCase = sendImageMessageUseCase;

  /// 메시지 전송 실행
  /// [roomId] 현재 채팅방 ID (null이면 첫 메시지)
  /// [itemId] 상품 ID (첫 메시지 전송 시 필요)
  /// [messageText] 텍스트 메시지 내용
  /// [images] 이미지 파일 목록
  /// [messageType] 메시지 타입
  /// [onError] 에러 발생 시 콜백
  Future<MessageSendResult> sendMessage({
    String? roomId,
    required String itemId,
    required String messageText,
    required List<XFile> images,
    required MessageType messageType,
    required void Function(String) onError,
  }) async {
    // 이미지가 있는 경우
    if (images.isNotEmpty) {
      return await _sendMessageWithImages(
        roomId: roomId,
        itemId: itemId,
        messageText: messageText,
        images: images,
        messageType: messageType,
        onError: onError,
      );
    }

    // 텍스트만 있는 경우
    if (messageText.trim().isNotEmpty) {
      return await _sendTextMessage(
        roomId: roomId,
        itemId: itemId,
        messageText: messageText,
        onError: onError,
      );
    }

    // 텍스트도 이미지도 없는 경우
    return MessageSendResult.failure("전송할 메시지나 이미지가 없습니다");
  }

  /// 이미지가 포함된 메시지 전송
  Future<MessageSendResult> _sendMessageWithImages({
    String? roomId,
    required String itemId,
    required String messageText,
    required List<XFile> images,
    required MessageType messageType,
    required void Function(String) onError,
  }) async {
    if (roomId == null) {
      // 첫 메시지 전송 - 첫 번째 이미지만 사용
      return await _sendFirstMessageWithImage(
        itemId: itemId,
        messageText: messageText,
        images: images,
        messageType: messageType,
        onError: onError,
      );
    } else {
      // 기존 채팅방에서 여러 이미지 전송
      return await _sendMultipleImagesToExistingRoom(
        roomId: roomId,
        messageText: messageText,
        images: images,
        onError: onError,
      );
    }
  }

  /// 첫 메시지 전송 (이미지 포함)
  Future<MessageSendResult> _sendFirstMessageWithImage({
    required String itemId,
    required String messageText,
    required List<XFile> images,
    required MessageType messageType,
    required void Function(String) onError,
  }) async {
    if (images.isEmpty) {
      return MessageSendResult.failure("이미지가 없습니다");
    }

    // 첫 번째 이미지로 첫 메시지 전송
    final sender = FirstImageMessageSender(
      sendFirstMessageUseCase: _sendFirstMessageUseCase,
      itemId: itemId,
      image: images.first,
    );

    final result = await sender.send();
    if (!result.success) {
      return MessageSendResult.failure(
        result.errorMessage ?? "메시지 전송 실패",
      );
    }

    if (result.roomId == null) {
      return MessageSendResult.failure("roomId가 null입니다");
    }

    // 나머지 이미지들을 순차적으로 전송
    if (images.length > 1) {
      for (int i = 1; i < images.length; i++) {
        final imageSender = ImageMessageSender(
          sendImageMessageUseCase: _sendImageMessageUseCase,
          roomId: result.roomId!,
          image: images[i],
        );
        final imageResult = await imageSender.send();
        if (!imageResult.success) {
          onError(imageResult.errorMessage ?? "이미지 전송 실패");
          // 에러가 나도 나머지 이미지는 계속 전송 시도
        }
      }
    }

    return MessageSendResult.success(
      roomId: result.roomId,
      isFirstMessage: true,
    );
  }

  /// 기존 채팅방에 여러 이미지 전송
  Future<MessageSendResult> _sendMultipleImagesToExistingRoom({
    required String roomId,
    required String messageText,
    required List<XFile> images,
    required void Function(String) onError,
  }) async {
    // 텍스트가 있으면 먼저 텍스트 메시지 전송
    if (messageText.trim().isNotEmpty) {
      final textSender = TextMessageSender(
        sendTextMessageUseCase: _sendTextMessageUseCase,
        roomId: roomId,
        message: messageText,
      );
      final textResult = await textSender.send();
      if (!textResult.success) {
        return MessageSendResult.failure(
          textResult.errorMessage ?? "메시지 전송 실패",
        );
      }
    }

    // 모든 이미지들을 순차적으로 전송
    for (int i = 0; i < images.length; i++) {
      final imageToSend = images[i];
      final sender = ImageMessageSender(
        sendImageMessageUseCase: _sendImageMessageUseCase,
        roomId: roomId,
        image: imageToSend,
      );
      final result = await sender.send();
      if (!result.success) {
        onError(
          "이미지 ${i + 1}/${images.length} 전송 실패: ${result.errorMessage ?? "알 수 없는 오류"}",
        );
        // 에러가 나도 나머지 이미지는 계속 전송 시도
      }
    }

    return MessageSendResult.success();
  }

  /// 텍스트 메시지 전송
  Future<MessageSendResult> _sendTextMessage({
    String? roomId,
    required String itemId,
    required String messageText,
    required void Function(String) onError,
  }) async {
    MessageSender? sender;

    if (roomId == null) {
      // 첫 메시지 전송
      sender = FirstTextMessageSender(
        sendFirstMessageUseCase: _sendFirstMessageUseCase,
        itemId: itemId,
        message: messageText,
      );
    } else {
      // 기존 채팅방에서 메시지 전송
      sender = TextMessageSender(
        sendTextMessageUseCase: _sendTextMessageUseCase,
        roomId: roomId,
        message: messageText,
      );
    }

    if (sender == null) {
      return MessageSendResult.failure(
        "메시지 전송 실패: 전송 전략을 생성할 수 없습니다",
      );
    }

    final result = await sender.send();
    if (!result.success) {
      return MessageSendResult.failure(
        result.errorMessage ?? "메시지 전송 실패",
      );
    }

    return MessageSendResult.success(
      roomId: result.roomId,
      isFirstMessage: roomId == null && result.roomId != null,
    );
  }
}



