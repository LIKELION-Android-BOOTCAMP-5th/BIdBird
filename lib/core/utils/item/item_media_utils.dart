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