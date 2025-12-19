import '../repositories/profile_repository.dart';

class DeleteAccount {
  DeleteAccount(this._repository);

  final ProfileRepository _repository;

  Future<void> call() {
    return _repository.deleteAccount();
  }
}
