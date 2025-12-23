import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/utils/item/media_resizer.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDataSource {
  Future<List<String>> uploadImages(List<XFile> files) async {
    if (files.isEmpty) {
      return [];
    }
    
    // 리사이징 처리
    final resizedFiles = await MediaResizer.resizeImages(files);
    // 병렬 업로드(과도한 동시성 방지, 디바이스/네트워크 안정성 향상)
    final results = await _uploadWithConcurrency(
      resizedFiles,
      (file) => CloudinaryManager.shared.uploadImageToCloudinary(file),
      concurrency: 4,
    );
    
    // 임시 리사이즈 파일 정리 (실패해도 무시)
    try {
      await MediaResizer.cleanupResizedFiles(resizedFiles);
    } catch (_) {}
    
    // null이 아닌 URL만 필터링하여 반환
    return results.whereType<String>().toList();
  }

  Future<List<T?>> _uploadWithConcurrency<S, T>(
    List<S> items,
    Future<T?> Function(S) task, {
    int concurrency = 4,
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

