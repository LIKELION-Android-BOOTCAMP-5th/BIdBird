String formatRemainingTime(DateTime finishTime) {
  final diff = finishTime.difference(DateTime.now());
  if (diff.isNegative) {
    return '00:00:00';
  }
  final hours = diff.inHours;
  final minutes = diff.inMinutes % 60;
  final seconds = diff.inSeconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

bool isVideoFile(String filePathOrUrl) {
  // URL이나 파일 경로에서 확장자 추출
  String path = filePathOrUrl;
  // URL인 경우 쿼리 파라미터 제거
  if (path.contains('?')) {
    path = path.split('?').first;
  }
  // URL인 경우 경로만 추출
  if (path.contains('/')) {
    path = path.split('/').last;
  }
  final extension = path.split('.').last.toLowerCase();
  const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm', '3gp', 'm4v'];
  return videoExtensions.contains(extension);
}

/// Cloudinary 동영상 URL에서 썸네일 이미지 URL 생성
String getVideoThumbnailUrl(String videoUrl) {
  // Cloudinary 동영상 URL에서 썸네일 생성
  // 예: https://res.cloudinary.com/.../video/upload/v123/abc.mp4
  // -> https://res.cloudinary.com/.../video/upload/so_0/v123/abc.jpg
  if (videoUrl.contains('/video/upload/')) {
    try {
      // URL을 파싱하여 썸네일 URL 생성
      final uri = Uri.parse(videoUrl);
      final pathSegments = uri.pathSegments;
      
      // video/upload 다음에 변환 파라미터와 버전, 파일명이 있음
      final videoIndex = pathSegments.indexOf('video');
      if (videoIndex >= 0 && videoIndex < pathSegments.length - 1) {
        if (pathSegments[videoIndex + 1] == 'upload') {
          // video/upload/ 이후의 경로를 가져옴
          final afterUpload = pathSegments.sublist(videoIndex + 2);
          if (afterUpload.isNotEmpty) {
            // 마지막 세그먼트가 파일명 (확장자 포함)
            final fileName = afterUpload.last;
            final fileNameWithoutExt = fileName.split('.').first;
            
            // so_0은 동영상의 첫 프레임을 의미하는 변환 파라미터
            final thumbnailPath = [
              ...pathSegments.sublist(0, videoIndex + 2),
              'so_0', // 동영상의 첫 프레임
              ...afterUpload.sublist(0, afterUpload.length - 1),
              '$fileNameWithoutExt.jpg',
            ];
            
            return uri.replace(pathSegments: thumbnailPath).toString();
          }
        }
      }
    } catch (e) {
      // 파싱 실패 시 원본 URL 반환
    }
  }
  // Cloudinary URL이 아니거나 파싱 실패 시 원본 URL 반환
  return videoUrl;
}

String formatPrice(int price) {
  final buffer = StringBuffer();
  final text = price.toString();
  for (int i = 0; i < text.length; i++) {
    final reverseIndex = text.length - i;
    buffer.write(text[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1 && i != text.length - 1) {
      buffer.write(',');
    }
  }
  return buffer.toString();
}

String formatRelativeTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  DateTime? time;
  try {
    time = DateTime.tryParse(isoString);
  } catch (_) {
    time = null;
  }
  if (time == null) return '';

  final now = DateTime.now();
  final diff = now.difference(time);

  if (diff.inSeconds < 60) {
    return '방금 전';
  } else if (diff.inMinutes < 60) {
    return '${diff.inMinutes}분 전';
  } else if (diff.inHours < 24) {
    return '${diff.inHours}시간 전';
  } else {
    final days = diff.inDays;
    return '$days일 전';
  }
}
