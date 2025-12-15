import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
import 'package:bidbird/features/chat/domain/usecases/send_first_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_image_message_usecase.dart';
import 'package:bidbird/features/chat/domain/usecases/send_text_message_usecase.dart';
import 'package:image_picker/image_picker.dart';

/// 메시지 전송 결과
class MessageSendResult {
  final bool success;
  final String? errorMessage;
  final String? roomId; // 첫 메시지 전송 시 생성된 roomId

  MessageSendResult({
    required this.success,
    this.errorMessage,
    this.roomId,
  });

  factory MessageSendResult.success({String? roomId}) {
    return MessageSendResult(success: true, roomId: roomId);
  }

  factory MessageSendResult.failure(String errorMessage) {
    return MessageSendResult(success: false, errorMessage: errorMessage);
  }
}

/// 메시지 전송 전략 인터페이스
abstract class MessageSender {
  Future<MessageSendResult> send();
}

/// 첫 텍스트 메시지 전송 전략
class FirstTextMessageSender implements MessageSender {
  final SendFirstMessageUseCase _sendFirstMessageUseCase;
  final String itemId;
  final String message;

  FirstTextMessageSender({
    required SendFirstMessageUseCase sendFirstMessageUseCase,
    required this.itemId,
    required this.message,
  }) : _sendFirstMessageUseCase = sendFirstMessageUseCase;

  @override
  Future<MessageSendResult> send() async {
    if (message.isEmpty) {
      return MessageSendResult.failure("메시지가 비어있습니다");
    }

    try {
      final roomId = await _sendFirstMessageUseCase(
        itemId: itemId,
        messageType: MessageType.text,
        message: message,
      );

      if (roomId == null) {
        return MessageSendResult.failure("메세지 전송 실패: roomId가 null입니다");
      }

      return MessageSendResult.success(roomId: roomId);
    } catch (e) {
      return MessageSendResult.failure("메세지 전송 실패: $e");
    }
  }
}

/// 첫 이미지 메시지 전송 전략
class FirstImageMessageSender implements MessageSender {
  final SendFirstMessageUseCase _sendFirstMessageUseCase;
  final String itemId;
  final XFile image;

  FirstImageMessageSender({
    required SendFirstMessageUseCase sendFirstMessageUseCase,
    required this.itemId,
    required this.image,
  }) : _sendFirstMessageUseCase = sendFirstMessageUseCase;

  @override
  Future<MessageSendResult> send() async {
    try {
      // 미디어 업로드
      final mediaUrl = await _uploadMedia(image);
      if (mediaUrl == null) {
        return MessageSendResult.failure("미디어 업로드 실패");
      }

      // 첫 메시지 전송
      final roomId = await _sendFirstMessageUseCase(
        itemId: itemId,
        messageType: MessageType.image,
        imageUrl: mediaUrl,
      );

      if (roomId == null) {
        return MessageSendResult.failure("메세지 전송 실패: roomId가 null입니다");
      }

      return MessageSendResult.success(roomId: roomId);
    } catch (e) {
      return MessageSendResult.failure("메세지 전송 실패: $e");
    }
  }

  Future<String?> _uploadMedia(XFile file) async {
    try {
      // 파일 존재 확인
      final fileLength = await file.length();
      if (fileLength == 0) {
        return null;
      }
      
      if (isVideoFile(file.path)) {
        return await CloudinaryManager.shared.uploadVideoToCloudinary(file);
      } else {
        return await CloudinaryManager.shared.uploadImageToCloudinary(file);
      }
    } catch (e, stackTrace) {
      return null;
    }
  }
}

/// 기존 채팅방 텍스트 메시지 전송 전략
class TextMessageSender implements MessageSender {
  final SendTextMessageUseCase _sendTextMessageUseCase;
  final String roomId;
  final String message;

  TextMessageSender({
    required SendTextMessageUseCase sendTextMessageUseCase,
    required this.roomId,
    required this.message,
  }) : _sendTextMessageUseCase = sendTextMessageUseCase;

  @override
  Future<MessageSendResult> send() async {
    if (message.isEmpty) {
      return MessageSendResult.failure("메시지가 비어있습니다");
    }

    try {
      await _sendTextMessageUseCase(roomId, message);
      return MessageSendResult.success();
    } catch (e) {
      return MessageSendResult.failure("메세지 전송 실패: $e");
    }
  }
}

/// 기존 채팅방 이미지 메시지 전송 전략
class ImageMessageSender implements MessageSender {
  final SendImageMessageUseCase _sendImageMessageUseCase;
  final String roomId;
  final XFile image;

  ImageMessageSender({
    required SendImageMessageUseCase sendImageMessageUseCase,
    required this.roomId,
    required this.image,
  }) : _sendImageMessageUseCase = sendImageMessageUseCase;

  @override
  Future<MessageSendResult> send() async {
    try {
      // 미디어 업로드
      final mediaUrl = await _uploadMedia(image);
      if (mediaUrl == null) {
        return MessageSendResult.failure("미디어 업로드 실패");
      }

      // 이미지 메시지 전송
      await _sendImageMessageUseCase(roomId, mediaUrl);
      return MessageSendResult.success();
    } catch (e) {
      return MessageSendResult.failure("메세지 전송 실패: $e");
    }
  }

  Future<String?> _uploadMedia(XFile file) async {
    try {
      // 파일 존재 확인
      final fileLength = await file.length();
      if (fileLength == 0) {
        return null;
      }
      
      if (isVideoFile(file.path)) {
        return await CloudinaryManager.shared.uploadVideoToCloudinary(file);
      } else {
        return await CloudinaryManager.shared.uploadImageToCloudinary(file);
      }
    } catch (e, stackTrace) {
      return null;
    }
  }
}

