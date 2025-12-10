// check_and_request_identity_verification_usecase.dart

import 'package:bidbird/features/item/identity_verification/data/repository/identity_verification_gateway.dart';
import 'package:flutter/widgets.dart';

class CheckAndRequestIdentityVerificationUseCase {
  final IdentityVerificationGateway _gateway;

  CheckAndRequestIdentityVerificationUseCase(this._gateway);

  /// 1. 서버에서 CI 존재 여부를 확인
  /// 2. 없으면 본인인증을 요청하여 CI 발급 후 서버에 저장
  /// 3. 최종적으로 CI가 존재하면 true, 그렇지 않으면 false 반환
  Future<bool> call(BuildContext context) async {
    final hasCi = await _gateway.hasCi();
    if (hasCi) {
      return true;
    }

    // CI가 없으면 본인인증 플로우 진입
    final ci = await _gateway.requestIdentityVerification(context);
    if (ci.isEmpty) {
      return false;
    }

    await _gateway.saveCi(ci);
    return true;
  }
}
