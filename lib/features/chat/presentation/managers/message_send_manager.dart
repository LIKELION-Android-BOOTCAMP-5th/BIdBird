import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/utils/item/item_media_utils.dart';
import 'package:bidbird/features/chat/domain/repositories/chat_repository.dart';
import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
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
  final ChatRepository _repository;

  MessageSendManager({
    required ChatRepository repository,
  }) : _repository = repository;

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
    final result = await _sendFirstImageMessage(
      itemId: itemId,
      image: images.first,
      messageType: messageType,
    );
    if (!result.success) {
      return MessageSendResult.failure(
        result.errorMessage ?? "메시지 전송 실패",
      );
    }

    if (result.roomId == null) {
      return MessageSendResult.failure("roomId가 null입니다");
    }

    // 나머지 이미지들을 병렬로 업로드한 후 순차적으로 전송
    if (images.length > 1) {
      final remainingImages = images.sublist(1);
      // 모든 이미지를 병렬로 업로드
      final uploadFutures = remainingImages.map((image) => _uploadMedia(image)).toList();
      final mediaUrls = await Future.wait(uploadFutures);

      // 업로드된 이미지들을 순차적으로 메시지로 전송 (순서 유지)
      for (int i = 0; i < mediaUrls.length; i++) {
        final mediaUrl = mediaUrls[i];
        if (mediaUrl == null) {
          onError("이미지 ${i + 2}/${images.length} 업로드 실패");
          continue;
        }

        try {
          await _repository.sendImageMessage(result.roomId!, mediaUrl);
        } catch (e) {
          onError("이미지 ${i + 2}/${images.length} 전송 실패: $e");
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
      try {
        await _repository.sendTextMessage(roomId, messageText);
      } catch (e) {
        return MessageSendResult.failure("메시지 전송 실패: $e");
      }
    }

    // 모든 이미지를 병렬로 업로드
    final uploadFutures = images.map((image) => _uploadMedia(image)).toList();
    final mediaUrls = await Future.wait(uploadFutures);

    // 업로드된 이미지들을 순차적으로 메시지로 전송 (순서 유지)
    for (int i = 0; i < mediaUrls.length; i++) {
      final mediaUrl = mediaUrls[i];
      if (mediaUrl == null) {
        onError("이미지 ${i + 1}/${images.length} 업로드 실패");
        continue;
      }

      try {
        await _repository.sendImageMessage(roomId, mediaUrl);
      } catch (e) {
        onError(
          "이미지 ${i + 1}/${images.length} 전송 실패: $e",
        );
        // 에러가 나도 나머지 이미지는 계속 전송 시도
      }
    }

    return MessageSendResult.success();
  }

  /// 미디어 업로드 헬퍼 메서드
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
    } catch (e) {
      return null;
    }
  }

  /// 텍스트 메시지 전송
  Future<MessageSendResult> _sendTextMessage({
    String? roomId,
    required String itemId,
    required String messageText,
    required void Function(String) onError,
  }) async {
    if (roomId == null) {
      // 첫 메시지 전송
      try {
        final roomId = await _repository.firstMessage(
          itemId: itemId,
          message: messageText,
          messageType: MessageType.text,
        );
        if (roomId == null) {
          return MessageSendResult.failure("메시지 전송 실패: roomId가 null입니다");
        }
        return MessageSendResult.success(
          roomId: roomId,
          isFirstMessage: true,
        );
      } catch (e) {
        return MessageSendResult.failure("메시지 전송 실패: $e");
      }
    } else {
      // 기존 채팅방에서 메시지 전송
      try {
        await _repository.sendTextMessage(roomId, messageText);
        return MessageSendResult.success();
      } catch (e) {
        return MessageSendResult.failure("메시지 전송 실패: $e");
      }
    }
  }

  /// 첫 메시지 전송 (이미지 포함) - 내부 헬퍼
  Future<MessageSendResult> _sendFirstImageMessage({
    required String itemId,
    required XFile image,
    required MessageType messageType,
  }) async {
    try {
      // 미디어 업로드
      final mediaUrl = await _uploadMedia(image);
      if (mediaUrl == null) {
        return MessageSendResult.failure("미디어 업로드 실패");
      }

      // 첫 메시지 전송
      final roomId = await _repository.firstMessage(
        itemId: itemId,
        messageType: messageType,
        imageUrl: mediaUrl,
      );

      if (roomId == null) {
        return MessageSendResult.failure("메시지 전송 실패: roomId가 null입니다");
      }

      return MessageSendResult.success(
        roomId: roomId,
        isFirstMessage: true,
      );
    } catch (e) {
      return MessageSendResult.failure("메시지 전송 실패: $e");
    }
  }
}



