import 'package:flutter/widgets.dart';

abstract class IdentityVerificationGateway {
  /// 서버에서 현재 사용자의 CI 존재 여부를 확인
  Future<bool> hasCi();

  /// 포트원 KG이니시스를 통해 본인인증 플로우를 시작하고 CI를 받아옴
  /// 성공 시 CI 문자열 반환
  Future<String> requestIdentityVerification(BuildContext context);

  /// 발급받은 CI를 서버에 저장
  Future<void> saveCi(String ci);
}