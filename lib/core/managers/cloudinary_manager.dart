import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

class CloudinaryManager {
  static final CloudinaryManager _shared = CloudinaryManager();
  static CloudinaryManager get shared => _shared;

  static final String cloudName = 'dn12so6sm';
  static final String uploadPreset = 'bidbird_upload_preset';
  static final String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static final String videoUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

  Future<String?> uploadImageToCloudinary(XFile inputImage) async {
    try {
      final filePath = inputImage.path;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 파일 존재 확인
      final file = await inputImage.length();
      if (file == 0) {
        print('이미지 업로드 실패: 파일이 비어있습니다');
        return null;
      }
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'upload_preset': uploadPreset,
      });

      final dio = Dio();
      final response = await dio.post(
        imageUploadUrl,
        data: formData,
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        } else {
          print('이미지 업로드 실패: secure_url이 null입니다');
          return null;
        }
      } else {
        print('이미지 업로드 실패: statusCode=${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('이미지 업로드 에러: $e');
      print('스택 트레이스: $stackTrace');
      return null;
    }
  }

  Future<List<String>> uploadImageListToCloudinary(
    List<XFile> imageList,
  ) async {
    final List<XFile> images = imageList;
    List<String> imageUrlList = [];

    try {
      if (images.isNotEmpty) {
        for (var image in images) {
          final url = await uploadImageToCloudinary(image);
          if (url != null) {
            imageUrlList.add(url);
          } else {
            return List.empty();
          }
        }
      }
    } catch (e) {
      return List.empty();
    }
    return imageUrlList;
  }

  Future<String?> uploadVideoToCloudinary(XFile inputVideo) async {
    try {
      final filePath = inputVideo.path;

      final extension = filePath.split('.').last.toLowerCase();
      final videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'];
      final fileExtension = videoExtensions.contains(extension) ? extension : 'mp4';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'upload_preset': uploadPreset,
        'resource_type': 'video',
      });

      final dio = Dio();
      final response = await dio.post(
        videoUploadUrl,
        data: formData,
      ).timeout(
        const Duration(minutes: 5),
      );

      if (response.statusCode == 200) {
        return response.data['secure_url'] as String?;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> uploadVideoListToCloudinary(
    List<XFile> videoList,
  ) async {
    final List<XFile> videos = videoList;
    List<String> videoUrlList = [];

    try {
      if (videos.isNotEmpty) {
        for (var video in videos) {
          final url = await uploadVideoToCloudinary(video);
          if (url != null) {
            videoUrlList.add(url);
          } else {
            return List.empty();
          }
        }
      }
    } catch (e) {
      return List.empty();
    }
    return videoUrlList;
  }
}
