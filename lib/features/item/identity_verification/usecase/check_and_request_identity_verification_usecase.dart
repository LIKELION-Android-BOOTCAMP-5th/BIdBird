import 'package:bidbird/features/item/identity_verification/data/repository/identity_verification_gateway.dart';
import 'package:flutter/widgets.dart';

class CheckAndRequestIdentityVerificationUseCase {
  final IdentityVerificationGateway _gateway;

  CheckAndRequestIdentityVerificationUseCase(this._gateway);

  Future<bool> call(BuildContext context) async {
    final hasCi = await _gateway.hasCi();
    if (hasCi) {
      return true;
    }

    // CI가 없으면 본인인증 플로우 진입
    final success = await _gateway.requestIdentityVerification(context);
    return success;
  }
}
