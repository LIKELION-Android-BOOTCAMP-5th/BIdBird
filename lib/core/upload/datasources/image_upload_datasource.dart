import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDataSource {
  Future<List<String>> uploadImages(List<XFile> files) async {
    if (files.isEmpty) {
      return [];
    }
    
    // 모든 이미지를 병렬로 업로드
    final futures = files.map((file) => 
      CloudinaryManager.shared.uploadImageToCloudinary(file)
    ).toList();
    
    final results = await Future.wait(futures);
    
    // null이 아닌 URL만 필터링하여 반환
    return results.whereType<String>().toList();
  }
}

