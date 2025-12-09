import 'package:flutter/material.dart';

import '../data/report_feedback_repository.dart';
import '../model/report_feedback_model.dart';

class ReportFeedbackViewModel extends ChangeNotifier {
  ReportFeedbackViewModel({ReportFeedbackRepository? repository})
    : _repository = repository ?? ReportFeedbackRepository(); //안넣으면기본리포지토리적용

  final ReportFeedbackRepository _repository;

  List<ReportFeedbackModel> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;

  //뷰모델보호//다른뷰모델도적용하기
  List<ReportFeedbackModel> get reports => _reports;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReports() async {
    if (_isLoading) return; //반복요청대비//현재는당겨서새로고침없어서그렇게필요는없음

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); //화면

    try {
      _reports = await _repository.fetchReports();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  //개별아이템에대한당겨서새로고침기능을추가하는경우필요함
  // Future<ReportFeedbackModel?> fetchReport(String id) async {
  //   try {
  //     return await _repository.fetchReportById(id);
  //   } catch (_) {
  //     return null;
  //   }
  // }
}
