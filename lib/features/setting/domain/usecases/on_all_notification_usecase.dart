

import 'package:bidbird/features/setting/domain/repositories/notify_setting_repository.dart';

class OnAllNotificationUseCase{
  OnAllNotificationUseCase(this._repository);

  final NotifySettingRepository _repository;

  Future<void> call() {
    return _repository.sendImageMessage();
  }
}