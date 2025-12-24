import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

/// 비디오 압축을 위한 Isolate 매개변수
class _VideoCompressParams {
  final String videoPath;
  final SendPort sendPort;

  _VideoCompressParams({
    required this.videoPath,
    required this.sendPort,
  });
}

/// 비디오 압축 결과
class VideoCompressResult {
  final String? path;
  final String? error;

  VideoCompressResult({this.path, this.error});

  bool get isSuccess => path != null && error == null;
}

/// Isolate에서 실행되는 비디오 압축 유틸리티
/// UI 블로킹 없이 백그라운드에서 비디오 압축을 수행합니다.
class VideoCompressorIsolate {
  /// 비디오 압축을 Isolate에서 실행 (UI 블로킹 방지)
  static Future<VideoCompressResult> compressVideo(
    XFile videoFile, {
    int? maxWidth,
    int? maxHeight,
  }) async {
    try {
      final file = File(videoFile.path);
      if (!await file.exists()) {
        return VideoCompressResult(error: '비디오 파일이 존재하지 않습니다.');
      }

      // Isolate 대신 compute 사용 (Flutter에서 권장하는 방식)
      final result = await compute(
        _compressVideoInBackground,
        _CompressParams(
          videoPath: videoFile.path,
          maxWidth: maxWidth ?? 1920,
          maxHeight: maxHeight ?? 1920,
        ),
      );

      return result;
    } catch (e) {
      return VideoCompressResult(error: '비디오 압축 실패: $e');
    }
  }

  /// 백그라운드에서 실행되는 비디오 압축 함수
  static Future<VideoCompressResult> _compressVideoInBackground(
    _CompressParams params,
  ) async {
    try {
      // 동영상 정보 가져오기
      final mediaInfo = await VideoCompress.getMediaInfo(params.videoPath);

      // 이미 리사이징이 필요 없는 경우
      if (mediaInfo.width != null &&
          mediaInfo.height != null &&
          mediaInfo.width! <= params.maxWidth &&
          mediaInfo.height! <= params.maxHeight) {
        return VideoCompressResult(path: params.videoPath);
      }

      // 동영상 압축
      final compressedVideo = await VideoCompress.compressVideo(
        params.videoPath,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: 30,
      );

      if (compressedVideo?.path == null) {
        return VideoCompressResult(error: '비디오 압축 실패');
      }

      return VideoCompressResult(path: compressedVideo!.path);
    } catch (e) {
      return VideoCompressResult(error: '비디오 압축 중 오류 발생: $e');
    }
  }
}

/// compute 함수에 전달할 압축 파라미터
class _CompressParams {
  final String videoPath;
  final int maxWidth;
  final int maxHeight;

  _CompressParams({
    required this.videoPath,
    required this.maxWidth,
    required this.maxHeight,
  });
}
