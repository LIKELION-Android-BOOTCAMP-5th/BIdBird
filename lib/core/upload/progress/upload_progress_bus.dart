import 'dart:async';

class UploadProgressEvent {
  final String filePath;
  final int sent;
  final int total;
  final String resourceType; // image | video

  UploadProgressEvent({
    required this.filePath,
    required this.sent,
    required this.total,
    required this.resourceType,
  });

  double get progress => total > 0 ? sent / total : 0.0;
}

class UploadProgressBus {
  UploadProgressBus._();
  static final UploadProgressBus instance = UploadProgressBus._();

  final StreamController<UploadProgressEvent> _controller =
      StreamController<UploadProgressEvent>.broadcast();

  Stream<UploadProgressEvent> get stream => _controller.stream;

  void emit(UploadProgressEvent event) {
    if (!_controller.isClosed) {
      _controller.add(event);
    }
  }

  void dispose() {
    _controller.close();
  }
}
