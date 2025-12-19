import '../repositories/blacklist_repository.dart';

class UnblockUser {
  UnblockUser(this._repository);

  final BlacklistRepository _repository;

  Future<void> call(String targetUserId) {
    return _repository.unblockUser(targetUserId);
  }
}
