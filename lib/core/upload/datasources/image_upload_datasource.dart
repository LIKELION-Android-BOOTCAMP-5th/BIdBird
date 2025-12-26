import 'package:bidbird/core/managers/cloudinary_manager.dart';
import 'package:bidbird/core/utils/item/media_resizer.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadDataSource {
  Future<List<String>> uploadImages(List<XFile> files) async {
    if (files.isEmpty) {
      return [];
    }
    // 로컬 파일과 원격 URL 분리
    final List<int> localIndices = [];
    final List<int> remoteIndices = [];
    for (int i = 0; i < files.length; i++) {
      final p = files[i].path;
      final uri = Uri.tryParse(p);
      final isRemote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (isRemote) {
        remoteIndices.add(i);
      } else {
        localIndices.add(i);
      }
    }

    // 1) 로컬 파일들만 리사이징/업로드
    final List<XFile> localFiles = [for (final i in localIndices) files[i]];

    List<String?> uploadedLocalUrls = [];
    List<XFile> resizedFiles = [];
    if (localFiles.isNotEmpty) {
      // 리사이징 처리
      resizedFiles = await MediaResizer.resizeImages(localFiles);
      // 병렬 업로드(과도한 동시성 방지, 디바이스/네트워크 안정성 향상)
      uploadedLocalUrls = await _uploadWithConcurrency(
        resizedFiles,
        (file) => CloudinaryManager.shared.uploadImageToCloudinary(file),
        concurrency: 4,
      );
    }

    // 2) 결과 병합: 원본 순서 유지. 원격 항목은 그대로 URL 사용.
    final List<String> mergedUrls = [];
    int localUrlCursor = 0;
    for (int i = 0; i < files.length; i++) {
      if (remoteIndices.contains(i)) {
        // 원격 URL은 업로드 없이 그대로 사용
        mergedUrls.add(files[i].path);
      } else {
        // 로컬 업로드 결과를 순서대로 소비
        if (localUrlCursor < uploadedLocalUrls.length) {
          final url = uploadedLocalUrls[localUrlCursor];
          if (url != null && url.isNotEmpty) {
            mergedUrls.add(url);
          }
          localUrlCursor += 1;
        }
      }
    }

    // 임시 리사이즈 파일 정리 (실패해도 무시)
    try {
      if (resizedFiles.isNotEmpty) {
        await MediaResizer.cleanupResizedFiles(resizedFiles);
      }
    } catch (_) {}

    return mergedUrls;
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

