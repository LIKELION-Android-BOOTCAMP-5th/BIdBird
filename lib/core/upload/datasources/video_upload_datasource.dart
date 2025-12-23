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
    
    // 과도한 동시 업로드 제한
    final results = await _uploadWithConcurrency(
      resizedFiles,
      (file) => CloudinaryManager.shared.uploadVideoToCloudinary(file),
      concurrency: 2,
    );
    
    // 임시 리사이즈 파일 정리
    try {
      await MediaResizer.cleanupResizedFiles(resizedFiles);
    } catch (_) {}
    
    // null이 아닌 URL만 필터링하여 반환
    return results.whereType<String>().toList();
  }

  Future<List<T?>> _uploadWithConcurrency<S, T>(
    List<S> items,
    Future<T?> Function(S) task, {
    int concurrency = 2,
  }) async {
    final List<T?> results = [];
    int index = 0;
    while (index < items.length) {
      final batch = items.sublist(
        index,
        (index + concurrency) > items.length ? items.length : (index + concurrency),
      );
      final batchResults = await Future.wait(batch.map(task));
      results.addAll(batchResults);
      index += batch.length;
    }
    return results;
  }
}

