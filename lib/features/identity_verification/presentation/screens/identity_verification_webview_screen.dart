import 'dart:math';

import 'package:bidbird/core/config/portone_config.dart';
import 'package:flutter/material.dart';
import 'package:portone_flutter/iamport_certification.dart';
import 'package:portone_flutter/model/certification_data.dart';

class KgInicisIdentityWebViewScreen extends StatefulWidget {
  const KgInicisIdentityWebViewScreen({super.key});

  @override
  State<KgInicisIdentityWebViewScreen> createState() =>
      _KgInicisIdentityWebViewScreenState();
}

class _KgInicisIdentityWebViewScreenState
    extends State<KgInicisIdentityWebViewScreen> {
  late final Future<void> _initFuture;
  late final String _merchantUid;

  @override
  void initState() {
    super.initState();
    _initFuture = PortoneConfig.isInitialized
        ? Future<void>.value()
        : PortoneConfig.initialize();
    _merchantUid =
        'cert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              Navigator.of(context).pop('');
            }
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return IamportCertification(
          appBar: null,
          initialChild: const Center(child: CircularProgressIndicator()),
          userCode: PortoneConfig.userCode,
          data: CertificationData(
            pg: PortoneConfig.pg,
            merchantUid: _merchantUid,
            mRedirectUrl: PortoneConfig.redirectUrl,
          ),
          callback: (Map<String, String> result) async {
            final success = result['success'] == 'true';
            final impUid = result['imp_uid'] ?? '';

            final isValidImpUid = impUid.isNotEmpty &&
                impUid.startsWith('imp_') &&
                impUid.length >= 10 &&
                impUid.length <= 100;

            if (!success || !isValidImpUid) {
              Navigator.of(context).pop('');
              return;
            }

            Navigator.of(context).pop(impUid);
          },
        );
      },
    );
  }
}



