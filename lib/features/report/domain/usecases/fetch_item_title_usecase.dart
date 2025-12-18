import 'package:bidbird/features/report/domain/repositories/report_repository.dart';

/// 상품 제목 조회 유즈케이스
class FetchItemTitleUseCase {
  FetchItemTitleUseCase(this._repository);

  final ReportRepository _repository;

  Future<String?> call(String itemId) {
    return _repository.fetchItemTitle(itemId);
  }
}

