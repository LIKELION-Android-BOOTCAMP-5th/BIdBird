import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:bidbird/core/upload/progress/upload_progress_bus.dart';
import 'package:bidbird/features/item_enroll/add/domain/usecases/upload_item_images_with_thumbnail_usecase.dart';
import 'package:bidbird/features/item_enroll/add/domain/entities/item_image_upload_result.dart';

/// 이미지 업로드를 진행률 콜백과 함께 수행하는 서비스
class UploadService {
  UploadService(this._useCase);

  final UploadItemImagesWithThumbnailUseCase _useCase;

  StreamSubscription? _sub;

  Future<ItemImageUploadResult> uploadWithProgress({
    required List<XFile> images,
    required int primaryImageIndex,
    void Function(double progress)? onProgress,
  }) async {
    final Map<String, double> fileProgress = {};
    void emit() {
      if (onProgress == null) return;
      if (fileProgress.isEmpty) {
        onProgress(0.0);
        return;
      }
      final avg = fileProgress.values.fold<double>(0.0, (a, b) => a + b) / fileProgress.length;
      onProgress(avg.clamp(0.0, 1.0));
    }

    // 초기화
    for (final f in images) {
      fileProgress[f.path] = 0.0;
    }
    emit();

    _sub?.cancel();
    _sub = UploadProgressBus.instance.stream.listen((event) {
      if (!fileProgress.containsKey(event.filePath)) {
        fileProgress[event.filePath] = 0.0;
      }
      fileProgress[event.filePath] = event.total > 0 ? event.sent / event.total : 0.0;
      emit();
    });

    try {
      final result = await _useCase(images: images, primaryImageIndex: primaryImageIndex);
      return result;
    } finally {
      await _sub?.cancel();
      _sub = null;
      fileProgress.clear();
      emit();
    }
  }
}
