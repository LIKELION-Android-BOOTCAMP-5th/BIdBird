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
    }
  }
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
