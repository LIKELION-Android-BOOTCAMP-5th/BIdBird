import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:bidbird/core/utils/item/video_compressor_isolate.dart';

/// 미디어 리사이징 유틸리티
/// 이미지와 동영상을 리사이징하는 컴포넌트
class MediaResizer {
  /// 이미지 리사이징 설정
  static const int maxImageWidth = 1920;
  static const int maxImageHeight = 1920;
  static const int imageQuality = 85; // 0-100

  /// 썸네일 설정
  static const int thumbnailWidth = 400;
  static const int thumbnailHeight = 400;
  static const int thumbnailQuality = 80; // 0-100

  /// 동영상 리사이징 설정
  static const int maxVideoWidth = 1920;
  static const int maxVideoHeight = 1920;
  static const int videoBitrate = 2000000; // 2Mbps

  /// 이미지 파일인지 확인
  static bool _isImageFile(XFile file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension);
  }

  /// 동영상 파일인지 확인
  static bool _isVideoFile(XFile file) {
    final extension = path.extension(file.path).toLowerCase();
    return ['.mp4', '.mov', '.avi', '.mkv', '.webm'].contains(extension);
  }

  /// 단일 이미지 리사이징
  static Future<XFile?> resizeImage(
    XFile imageFile, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    try {
      if (!_isImageFile(imageFile)) {
        return imageFile; // 이미지가 아니면 그대로 반환
      }

      final file = File(imageFile.path);
      if (!await file.exists()) {
        return null;
      }

      // 원본 이미지 크기 확인 (업스케일 방지)
      final bytes = await file.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return imageFile; // 디코드 실패 시 원본 반환
      }

      final targetWidth = maxWidth ?? maxImageWidth;
      final targetHeight = maxHeight ?? maxImageHeight;
      final needsResize = decoded.width > targetWidth || decoded.height > targetHeight;

      if (!needsResize) {
        // 목표 크기 이하이면 업스케일/재압축 생략하여 성능 향상
        return imageFile;
      }

      // 리사이징된 이미지 생성
      final targetPath = await _getTempFilePath('resized_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.path,
        targetPath,
        quality: quality ?? imageQuality,
        minWidth: targetWidth,
        minHeight: targetHeight,
        keepExif: false,
      );

      if (result == null) {
        return imageFile; // 리사이징 실패 시 원본 반환
      }

      return XFile(result.path);
    } catch (e) {
      // 에러 발생 시 원본 파일 반환
      return imageFile;
    }
  }

  /// 여러 이미지 리사이징
  static Future<List<XFile>> resizeImages(
    List<XFile> imageFiles, {
    int? maxWidth,
    int? maxHeight,
    int? quality,
  }) async {
    final List<XFile> resizedImages = [];

    for (final imageFile in imageFiles) {
      if (_isImageFile(imageFile)) {
        final resized = await resizeImage(
          imageFile,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          quality: quality,
        );
        // 리사이징 실패 시 원본 이미지 사용
        resizedImages.add(resized ?? imageFile);
      } else {
        // 이미지가 아니면 그대로 추가
        resizedImages.add(imageFile);
      }
    }

    return resizedImages;
  }

  /// 동영상 리사이징 (Isolate 사용으로 UI 블로킹 방지)
  static Future<XFile?> resizeVideo(
    XFile videoFile, {
    int? maxWidth,
    int? maxHeight,
    int? bitrate,
  }) async {
    try {
      if (!_isVideoFile(videoFile)) {
        return videoFile; // 동영상이 아니면 그대로 반환
      }

      final file = File(videoFile.path);
      if (!await file.exists()) {
        return null;
      }

      // Isolate에서 비디오 압축 수행 (UI 블로킹 방지)
      final result = await VideoCompressorIsolate.compressVideo(
        videoFile,
        maxWidth: maxWidth ?? maxVideoWidth,
        maxHeight: maxHeight ?? maxVideoHeight,
      );

      if (result.isSuccess && result.path != null) {
        return XFile(result.path!);
      } else {
        // 압축 실패 시 원본 반환
        return videoFile;
      }
    } catch (e) {
      // 에러 발생 시 원본 파일 반환
      return videoFile;
    }
  }

  /// 이미지와 동영상을 자동으로 리사이징
  /// 이미지는 리사이징하고, 동영상은 리사이징합니다.
  static Future<List<XFile>> resizeMedia(
    List<XFile> mediaFiles, {
    int? imageMaxWidth,
    int? imageMaxHeight,
    int? imageQuality,
    int? videoMaxWidth,
    int? videoMaxHeight,
    int? videoBitrate,
  }) async {
    final List<XFile> resizedFiles = [];

    for (final file in mediaFiles) {
      if (_isImageFile(file)) {
        final resized = await resizeImage(
          file,
          maxWidth: imageMaxWidth,
          maxHeight: imageMaxHeight,
          quality: imageQuality,
        );
        if (resized != null) {
          resizedFiles.add(resized);
        }
      } else if (_isVideoFile(file)) {
        final resized = await resizeVideo(
          file,
          maxWidth: videoMaxWidth,
          maxHeight: videoMaxHeight,
          bitrate: videoBitrate,
        );
        if (resized != null) {
          resizedFiles.add(resized);
        }
      } else {
        // 알 수 없는 파일 타입은 그대로 추가
        resizedFiles.add(file);
      }
    }

    return resizedFiles;
  }

  /// 임시 파일 경로 생성
  static Future<String> _getTempFilePath(String fileName) async {
    final tempDir = await getTemporaryDirectory();
    return path.join(tempDir.path, fileName);
  }

  /// 이미지 썸네일 생성 (정사각형으로 crop하여 생성)
  static Future<XFile?> createImageThumbnail(
    XFile imageFile, {
    int? width,
    int? height,
    int? quality,
  }) async {
    try {
      if (!_isImageFile(imageFile)) {
        return null; // 이미지가 아니면 null 반환
      }

      final file = File(imageFile.path);
      if (!await file.exists()) {
        return null;
      }

      final targetWidth = width ?? thumbnailWidth;
      final targetHeight = height ?? thumbnailHeight;
      
      // 이미지를 로드하여 정사각형으로 crop
      final imageBytes = await file.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      
      if (originalImage == null) {
        return null;
      }
      
      // 정사각형으로 crop (중앙 기준)
      final size = originalImage.width < originalImage.height 
          ? originalImage.width 
          : originalImage.height;
      final offsetX = (originalImage.width - size) ~/ 2;
      final offsetY = (originalImage.height - size) ~/ 2;
      
      // 정사각형으로 crop
      final croppedImage = img.copyCrop(
        originalImage,
        x: offsetX,
        y: offsetY,
        width: size,
        height: size,
      );
      
      // 타겟 크기로 리사이즈
      final resizedImage = img.copyResize(
        croppedImage,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
      
      // JPEG로 인코딩
      final jpegBytes = img.encodeJpg(resizedImage, quality: quality ?? thumbnailQuality);
      
      // 임시 파일로 저장
      final targetPath = await _getTempFilePath('thumbnail_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final targetFile = File(targetPath);
      await targetFile.writeAsBytes(jpegBytes);

      return XFile(targetPath);
    } catch (e) {
      return null;
    }
  }

  /// 동영상 썸네일 생성 (첫 프레임 추출)
  /// 참고: video_compress 패키지에 썸네일 추출 메서드가 없으므로
  /// 비디오 썸네일은 Cloudinary가 자동으로 생성합니다.
  /// 이 메서드는 null을 반환하여 Cloudinary의 자동 썸네일을 사용하도록 합니다.
  static Future<XFile?> createVideoThumbnail(
    XFile videoFile, {
    int? width,
    int? height,
    int? quality,
  }) async {
    // video_compress 패키지에 썸네일 추출 메서드가 없으므로
    // 비디오 썸네일은 Cloudinary가 자동으로 생성하므로 null 반환
    // Cloudinary의 getVideoThumbnailUrl 함수를 사용하여 썸네일 URL 생성
    return null;
  }

  /// 미디어 파일에서 썸네일 생성 (이미지 또는 동영상)
  static Future<XFile?> createThumbnail(
    XFile mediaFile, {
    int? width,
    int? height,
    int? quality,
  }) async {
    if (_isImageFile(mediaFile)) {
      return await createImageThumbnail(
        mediaFile,
        width: width,
        height: height,
        quality: quality,
      );
    } else if (_isVideoFile(mediaFile)) {
      return await createVideoThumbnail(
        mediaFile,
        width: width,
        height: height,
        quality: quality,
      );
    }
    return null;
  }

  /// 리사이징된 파일 정리 (임시 파일 삭제)
  static Future<void> cleanupResizedFiles(List<XFile> files) async {
    for (final file in files) {
      try {
        final filePath = file.path;
        if (filePath.contains('resized_') || 
            filePath.contains('compressed_') ||
            filePath.contains('thumbnail_')) {
          final file = File(filePath);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (e) {
        // 파일 삭제 실패는 무시
      }
    }
  }
}

