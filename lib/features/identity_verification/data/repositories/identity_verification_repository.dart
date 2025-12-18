import 'package:bidbird/features/identity_verification/data/datasources/identity_verification_datasource.dart';
import 'package:bidbird/features/identity_verification/domain/repositories/identity_verification_repository.dart' as domain;
import 'package:flutter/widgets.dart';

/// Identity Verification 리포지토리 구현체
class IdentityVerificationRepositoryImpl implements domain.IdentityVerificationRepository {
  IdentityVerificationRepositoryImpl({IdentityVerificationDatasource? datasource})
      : _datasource = datasource ?? IdentityVerificationDatasource();

  final IdentityVerificationDatasource _datasource;

  @override
  Future<bool> hasCi() {
    return _datasource.hasCi();
  }

  @override
  Future<bool> requestIdentityVerification(BuildContext context) async {
    final impUid = await _datasource.getImpUidFromWebView(context);
    if (impUid == null) {
      return false;
    }

    return _datasource.submitIdentityVerification(impUid);
  }
}



