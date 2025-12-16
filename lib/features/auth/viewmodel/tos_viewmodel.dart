import 'package:bidbird/features/auth/data/repository/tos_repository.dart';
import 'package:bidbird/features/auth/model/tos_model.dart';
import 'package:flutter/cupertino.dart';

class ToSViewmodel extends ChangeNotifier {
  final ToSRepository _tosRepository;

  List<ToSModel> _tosInfo = [];
  List<ToSModel> get tosInfo => _tosInfo;

  ToSViewmodel(this._tosRepository) {
    fetchToSinfo();
  }

  Future<void> fetchToSinfo() async {
    _tosInfo = await _tosRepository.getToSinfo();
    notifyListeners();
  }

  Future<void> tosAgreed() async {
    await _tosRepository.tosAgreed();
  }
}
