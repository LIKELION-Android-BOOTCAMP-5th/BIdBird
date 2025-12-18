import 'package:flutter/widgets.dart';

/// Identity Verification 도메인 리포지토리 인터페이스
abstract class IdentityVerificationRepository {
  Future<bool> hasCi();
  Future<bool> requestIdentityVerification(BuildContext context);
}



