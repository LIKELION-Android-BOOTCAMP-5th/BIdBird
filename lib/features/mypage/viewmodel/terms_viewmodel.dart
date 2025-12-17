import 'package:flutter/material.dart';

import '../data/terms_repository.dart';

class TermsItem {
  final String title;
  final String body;

  const TermsItem({required this.title, required this.body});
}

class TermsViewModel extends ChangeNotifier {
  TermsViewModel(this._repository) {
    loadTerms();
  }

  final TermsRepository _repository;

  bool isLoading = false;
  String? errorMessage;

  List<TermsItem> termsContent = [];

  Future<void> loadTerms() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final content = await _repository.fetchLatestTermsContent();

      termsContent = [
        TermsItem(title: '서비스 이용약관', body: content),

        // TermsItem(
        //   title: '개인정보 처리방침',
        //   body: '',
        // ),
      ];
    } catch (e) {
      errorMessage = e.toString();
      termsContent = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
