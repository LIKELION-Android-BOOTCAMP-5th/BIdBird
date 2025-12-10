import 'package:flutter/material.dart';
import 'package:portone_flutter/iamport_certification.dart';
import 'package:portone_flutter/model/certification_data.dart';

/// KG이니시스 통합인증을 포트원 IamportCertification 위젯으로 호출하는 화면
/// 별도의 Scaffold/AppBar 없이 본인인증 WebView만 표시한다.
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
        // TODO: 필요시 추가 옵션 설정 (name, phone, carrier 등)
      ),
      callback: (Map<String, String> result) async {
        final success = result['success'] == 'true';
        final impUid = result['imp_uid'] ?? '';

        if (!success || impUid.isEmpty) {
          Navigator.of(context).pop('');
          return;
        }

        // TODO: impUid를 서버로 보내어 포트원 REST API로 CI/DI 조회 후 CI를 받아오도록 구현
        // 현재는 임시로 impUid 자체를 CI처럼 사용하여 플로우를 통과시키도록 함.
        Navigator.of(context).pop(impUid);
      },
    );
  }
}
