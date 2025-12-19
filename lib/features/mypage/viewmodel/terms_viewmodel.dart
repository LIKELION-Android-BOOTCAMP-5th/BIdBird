import 'package:flutter/material.dart';

import '../domain/entities/terms_entity.dart';
import '../domain/usecases/get_terms_content.dart';

class TermsViewModel extends ChangeNotifier {
  TermsViewModel(this._getTermsContent) {
    loadTerms();
  }

  final GetTermsContent _getTermsContent;

  bool isLoading = false;
  String? errorMessage;

  List<TermsSectionEntity> termsContent = [];

  Future<void> loadTerms() async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final content = await _getTermsContent();

      termsContent = [
        TermsSectionEntity(title: '서비스 이용약관', body: content),
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
