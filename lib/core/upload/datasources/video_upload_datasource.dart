import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/utils/item/media_resizer.dart';
import 'package:image_picker/image_picker.dart';

class VideoUploadDataSource {
  Future<List<String>> uploadVideos(List<XFile> files) async {
    if (files.isEmpty) {
      return [];
    }
    
    // 리사이징 처리
    final List<XFile> resizedFiles = [];
    for (final file in files) {
      final resized = await MediaResizer.resizeVideo(file);
      resizedFiles.add(resized ?? file);
    }
    
    // 모든 동영상을 병렬로 업로드
    final futures = resizedFiles.map((file) => 
      CloudinaryManager.shared.uploadVideoToCloudinary(file)
    ).toList();
    
    final results = await Future.wait(futures);
    
    // null이 아닌 URL만 필터링하여 반환
    return results.whereType<String>().toList();
  }
}

