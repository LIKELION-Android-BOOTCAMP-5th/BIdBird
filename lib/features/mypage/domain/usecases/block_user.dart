import '../repositories/blacklist_repository.dart';

class BlockUser {
  BlockUser(this._repository);

  final BlacklistRepository _repository;

  Future<String?> call(String targetUserId) {
    return _repository.blockUser(targetUserId);
  }
}
