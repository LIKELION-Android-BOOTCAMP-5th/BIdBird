import '../entities/report_feedback_entity.dart';
import '../repositories/report_feedback_repository.dart';

class GetReportFeedback {
  GetReportFeedback(this._repository);

  final ReportFeedbackRepository _repository;

  Future<List<ReportFeedbackEntity>> call() {
    return _repository.fetchReports();
  }
}
