import 'dart:io';
import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDataSource {
  Future<List<String>> uploadImages(List<XFile> files) async {
    List<String> urls = [];
    
    for (var file in files) {
      // 파일 확장자로 이미지/동영상 구분
      final extension = file.path.split('.').last.toLowerCase();
      final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'];
      
      if (videoExtensions.contains(extension)) {
        // 동영상 업로드
        final videoUrl = await CloudinaryManager.shared.uploadVideoToCloudinary(file);
        if (videoUrl != null) {
          urls.add(videoUrl);
        }
      } else {
        // 이미지 업로드 (기존 방식)
        final imageUrl = await CloudinaryManager.shared.uploadImageToCloudinary(file);
        if (imageUrl != null) {
          urls.add(imageUrl);
        }
      }
    }
    
    return urls;
  }
}
