import 'package:flutter/widgets.dart';

abstract class IdentityVerificationGateway {
  Future<bool> hasCi();
  Future<bool> requestIdentityVerification(BuildContext context);
}