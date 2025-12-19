import 'package:bidbird/features/auth/data/repositories/tos_repository_impl.dart';
import 'package:bidbird/features/auth/domain/entities/tos_entity.dart';
import 'package:bidbird/features/auth/domain/usecases/get_tos_info_usecase.dart';
import 'package:bidbird/features/auth/domain/usecases/tos_agreed_usecase.dart';
import 'package:flutter/cupertino.dart';

class ToSViewmodel extends ChangeNotifier {
  final GetToSInfoUseCase _getToSInfoUseCase;
  final ToSAgreedUseCase _tosAgreedUseCase;

  List<ToSEntity> _tosInfo = [];
  List<ToSEntity> get tosInfo => _tosInfo;

  ToSViewmodel()
      : _getToSInfoUseCase = GetToSInfoUseCase(ToSRepositoryImpl()),
        _tosAgreedUseCase = ToSAgreedUseCase(ToSRepositoryImpl()) {
    fetchToSinfo();
  }

  Future<void> fetchToSinfo() async {
    _tosInfo = await _getToSInfoUseCase.call();
    notifyListeners();
  }

  Future<void> tosAgreed() async {
    await _tosAgreedUseCase.call();
  }
}


