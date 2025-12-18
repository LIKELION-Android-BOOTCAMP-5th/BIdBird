import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';
import 'package:bidbird/features/report/domain/repositories/report_repository.dart';

/// 신고 타입 목록 조회 유즈케이스
class FetchReportTypesUseCase {
  FetchReportTypesUseCase(this._repository);

  final ReportRepository _repository;

  Future<List<ReportTypeEntity>> call() {
    return _repository.fetchReportTypes();
  }
}

