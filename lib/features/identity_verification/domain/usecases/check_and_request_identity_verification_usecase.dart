import 'package:bidbird/features/identity_verification/domain/repositories/identity_verification_repository.dart';
import 'package:flutter/widgets.dart';

class CheckAndRequestIdentityVerificationUseCase {
  final IdentityVerificationRepository _repository;

  CheckAndRequestIdentityVerificationUseCase(this._repository);

  Future<bool> call(BuildContext context) async {
    final hasCi = await _repository.hasCi();
    if (hasCi) {
      return true;
    }

    // CI가 없으면 본인인증 플로우 진입
    final success = await _repository.requestIdentityVerification(context);
    return success;
  }
}



