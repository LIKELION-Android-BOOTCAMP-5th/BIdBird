import 'package:bidbird/features/report/data/datasources/report_datasource.dart';
import 'package:bidbird/features/report/domain/entities/report_type_entity.dart';
import 'package:bidbird/features/report/domain/repositories/report_repository.dart' as domain;

/// Report 리포지토리 구현체
class ReportRepositoryImpl implements domain.ReportRepository {
  ReportRepositoryImpl({ReportDatasource? datasource})
      : _datasource = datasource ?? ReportDatasource();

  final ReportDatasource _datasource;

  @override
  Future<List<ReportTypeEntity>> fetchReportTypes() {
    return _datasource.fetchReportTypes();
  }

  @override
  Future<void> submitReport({
    required String? itemId,
    required String targetUserId,
    required String reportCode,
    required String reportContent,
    List<String> imageUrls = const [],
  }) {
    return _datasource.submitReport(
      itemId: itemId,
      targetUserId: targetUserId,
      reportCode: reportCode,
      reportContent: reportContent,
      imageUrls: imageUrls,
    );
  }

  @override
  Future<String?> fetchUserNickname(String userId) {
    return _datasource.fetchUserNickname(userId);
  }

  @override
  Future<String?> fetchItemTitle(String itemId) {
    return _datasource.fetchItemTitle(itemId);
  }
}



