import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bidbird/core/upload/progress/upload_progress_bus.dart';

class CloudinaryManager {
  static final CloudinaryManager _shared = CloudinaryManager();
  static CloudinaryManager get shared => _shared;

  static final String cloudName = 'dn12so6sm';
  static final String uploadPreset = 'bidbird_upload_preset';
  static final String imageUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  static final String videoUploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/video/upload';

  // 단일 Dio 인스턴스를 재사용하여 연결/핸드셰이크 오버헤드 감소
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(minutes: 2),
      receiveTimeout: const Duration(minutes: 2),
    ),
  );

  Future<String?> uploadImageToCloudinary(XFile inputImage) async {
    try {
      final filePath = inputImage.path;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 파일 존재 확인
      final file = await inputImage.length();
      if (file == 0) {
        // 이미지 업로드 실패: 파일이 비어있습니다
        return null;
      }
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
        'upload_preset': uploadPreset,
      });

      final response = await _postWithRetry(
        url: imageUploadUrl,
        data: formData,
        totalTimeout: const Duration(seconds: 30),
        onSendProgress: (sent, total) {
          UploadProgressBus.instance.emit(
            UploadProgressEvent(
              filePath: filePath,
              sent: sent,
              total: total,
              resourceType: 'image',
            ),
          );
        },
      );

      if (response.statusCode == 200) {
        final secureUrl = response.data['secure_url'] as String?;
        if (secureUrl != null) {
          return secureUrl;
        } else {
          // 이미지 업로드 실패: secure_url이 null입니다
          return null;
        }
      } else {
        // 이미지 업로드 실패: statusCode=${response.statusCode}
        return null;
      }
    } catch (e) {
      // 이미지 업로드 에러: $e
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

      final response = await _postWithRetry(
        url: videoUploadUrl,
        data: formData,
        totalTimeout: const Duration(minutes: 5),
        onSendProgress: (sent, total) {
          UploadProgressBus.instance.emit(
            UploadProgressEvent(
              filePath: filePath,
              sent: sent,
              total: total,
              resourceType: 'video',
            ),
          );
        },
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

  // 재시도(지수 백오프) 지원 업로드 헬퍼
  Future<Response<dynamic>> _postWithRetry({
    required String url,
    required FormData data,
    required Duration totalTimeout,
    int maxRetries = 2,
    void Function(int, int)? onSendProgress,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await _dio
            .post(
              url,
              data: data,
              onSendProgress: onSendProgress,
            )
            .timeout(totalTimeout);
      } catch (e) {
        if (attempt >= maxRetries) rethrow;
        final backoffMs = 500 * (1 << attempt); // 500ms, 1000ms
        await Future.delayed(Duration(milliseconds: backoffMs));
        attempt += 1;
      }
    }
  }
}
