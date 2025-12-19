import '../../domain/repositories/terms_repository.dart';
import '../datasources/terms_remote_data_source.dart';

class TermsRepositoryImpl implements TermsRepository {
  TermsRepositoryImpl({TermsRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? TermsRemoteDataSource();

  final TermsRemoteDataSource _remoteDataSource;

  @override
  Future<String> fetchLatestTermsContent() {
    return _remoteDataSource.fetchLatestTermsContent();
  }
}
