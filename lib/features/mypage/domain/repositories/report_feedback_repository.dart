import '../entities/report_feedback_entity.dart';

abstract class ReportFeedbackRepository {
  Future<List<ReportFeedbackEntity>> fetchReports();
}
