import 'package:bidbird/features/report/domain/repositories/report_repository.dart';

/// 사용자 닉네임 조회 유즈케이스
class FetchUserNicknameUseCase {
  FetchUserNicknameUseCase(this._repository);

  final ReportRepository _repository;

  Future<String?> call(String userId) {
    return _repository.fetchUserNickname(userId);
  }
}

