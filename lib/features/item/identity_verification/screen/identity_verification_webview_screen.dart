import 'package:flutter/material.dart';
import 'package:portone_flutter/iamport_certification.dart';
import 'package:portone_flutter/model/certification_data.dart';

class KgInicisIdentityWebViewScreen extends StatelessWidget {
  const KgInicisIdentityWebViewScreen({super.key});

  static const _userCode = 'imp83681831';

  @override
  Widget build(BuildContext context) {
    return IamportCertification(
      appBar: null,
      initialChild: const Center(child: CircularProgressIndicator()),
      userCode: _userCode,
      data: CertificationData(
        pg: 'inicis_unified',
        merchantUid: 'cert_${DateTime.now().millisecondsSinceEpoch}',
        mRedirectUrl: 'https://example.com',
      ),
      callback: (Map<String, String> result) async {
        final success = result['success'] == 'true';
        final impUid = result['imp_uid'] ?? '';

        if (!success || impUid.isEmpty) {
          Navigator.of(context).pop('');
          return;
        }

        Navigator.of(context).pop(impUid);
      },
    );
  }
}
