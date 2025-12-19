import '../repositories/terms_repository.dart';

class GetTermsContent {
  GetTermsContent(this._repository);

  final TermsRepository _repository;

  Future<String> call() {
    return _repository.fetchLatestTermsContent();
  }
}
