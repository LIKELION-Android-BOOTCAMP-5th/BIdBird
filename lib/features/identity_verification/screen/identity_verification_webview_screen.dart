import 'package:bidbird/core/config/portone_config.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter/iamport_certification.dart';
import 'package:portone_flutter/model/certification_data.dart';

class KgInicisIdentityWebViewScreen extends StatelessWidget {
  const KgInicisIdentityWebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IamportCertification(
      appBar: null,
      initialChild: const Center(child: CircularProgressIndicator()),
      userCode: PortoneConfig.userCode,
      data: CertificationData(
        pg: PortoneConfig.pg,
        merchantUid: 'cert_${DateTime.now().millisecondsSinceEpoch}',
        mRedirectUrl: PortoneConfig.redirectUrl,
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
