import 'package:bidbird/features/chat/domain/usecases/message_type.dart';
import 'package:image_picker/image_picker.dart';

/// 이미지 선택 결과
class ImagePickerResult {
  final List<XFile> images;
  final MessageType messageType;

  ImagePickerResult({
    required this.images,
    required this.messageType,
  });
}

/// 이미지 선택 관리자
/// 이미지/비디오 선택 로직을 관리하는 클래스
class ImagePickerManager {
  final ImagePicker _picker = ImagePicker();

  /// 갤러리에서 여러 이미지 선택
  Future<ImagePickerResult?> pickImagesFromGallery() async {
    final List<XFile> pickedImages = await _picker.pickMultiImage(
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    
    if (pickedImages.isEmpty) {
      return null;
    }
    
    // 리사이징은 upload datasource에서 처리
    return ImagePickerResult(
      images: pickedImages,
      messageType: MessageType.image,
    );
  }

  /// 카메라에서 이미지 선택
  Future<ImagePickerResult?> pickImageFromCamera() async {
    final XFile? pickedImage = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    
    if (pickedImage == null) {
      return null;
    }
    
    // 리사이징은 upload datasource에서 처리
    return ImagePickerResult(
      images: [pickedImage],
      messageType: MessageType.image,
    );
  }

  /// 갤러리에서 비디오 선택
  Future<ImagePickerResult?> pickVideoFromGallery() async {
    final XFile? pickedVideo = await _picker.pickVideo(
      source: ImageSource.gallery,
    );
    
    if (pickedVideo == null) {
      return null;
    }
    
    // 리사이징은 upload datasource에서 처리
    return ImagePickerResult(
      images: [pickedVideo],
      messageType: MessageType.video,
    );
  }
}




