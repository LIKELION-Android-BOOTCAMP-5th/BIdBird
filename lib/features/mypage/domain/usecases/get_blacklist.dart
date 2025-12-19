import '../entities/blacklisted_user_entity.dart';
import '../repositories/blacklist_repository.dart';

class GetBlacklist {
  GetBlacklist(this._repository);

  final BlacklistRepository _repository;

  Future<List<BlacklistedUserEntity>> call() {
    return _repository.fetchBlacklist();
  }
}
