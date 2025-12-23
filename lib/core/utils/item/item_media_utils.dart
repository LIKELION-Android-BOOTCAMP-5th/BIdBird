// 아이템 관련 미디어(비디오) 유틸리티

/// 파일 경로나 URL이 비디오 파일인지 확인
bool isVideoFile(String filePathOrUrl) {
  String path = filePathOrUrl;
  if (path.contains('?')) {
    path = path.split('?').first;
  }
  if (path.contains('/')) {
    path = path.split('/').last;
  }
  final extension = path.split('.').last.toLowerCase();
  const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v'];
  return videoExtensions.contains(extension);
}

/// 비디오 URL에서 썸네일 URL을 생성 (Cloudinary 기반)
String getVideoThumbnailUrl(String videoUrl) {
  if (videoUrl.contains('/video/upload/')) {
    try {
      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;
      
      final videoIndex = pathSegments.indexOf('video');
      if (videoIndex >= 0 && videoIndex < pathSegments.length - 1) {
        if (pathSegments[videoIndex + 1] == 'upload') {
          final afterUpload = pathSegments.sublist(videoIndex + 2);
          if (afterUpload.isNotEmpty) {
            final fileName = afterUpload.last;
            final fileNameWithoutExt = fileName.split('.').first;
            
            final thumbnailPath = [
              ...pathSegments.sublist(0, videoIndex + 2),
              'so_0',
              ...afterUpload.sublist(0, afterUpload.length - 1),
              '$fileNameWithoutExt.jpg',
            ];
            
            return uri.replace(pathSegments: thumbnailPath).toString();
          }
        }
      }
    } catch (e) {
      // URL 파싱 실패 시 원본 URL 반환
    }
  }
  return videoUrl;
}

/// Cloudinary URL에 서버 사이드 리사이즈 변환을 주입합니다.
/// res.cloudinary.com/.../(image|video)/upload/... 경로에 w_,h_,c_fill,f_auto,q_auto를 추가합니다.
String resizeCloudinaryUrl(
  String url, {
  int? width,
  int? height,
  bool cropFill = true,
}) {
  try {
    final uri = Uri.parse(url);
    if (!(uri.host.contains('res.cloudinary.com') || uri.path.contains('/image/upload/') || uri.path.contains('/video/upload/'))) {
      return url;
    }

    final segments = List<String>.from(uri.pathSegments);
    final imgIdx = segments.indexWhere((s) => s == 'image' || s == 'video');
    if (imgIdx == -1 || imgIdx + 1 >= segments.length || segments[imgIdx + 1] != 'upload') {
      return url;
    }

    // 변환 문자열 구성
    final parts = <String>[];
    if (width != null && width > 0) parts.add('w_$width');
    if (height != null && height > 0) parts.add('h_$height');
    if (cropFill) parts.add('c_fill');
    parts.addAll(['f_auto', 'q_auto']);
    final transform = parts.join(',');

    // 이미 변환이 포함되어 있으면 그대로 두기
    if (segments.length > imgIdx + 2 && segments[imgIdx + 2].contains(RegExp(r'^(w_|h_|c_|f_|q_)'))) {
      return url;
    }

    segments.insert(imgIdx + 2, transform);
    final newUri = uri.replace(pathSegments: segments);
    return newUri.toString();
  } catch (e) {
    return url;
  }
}