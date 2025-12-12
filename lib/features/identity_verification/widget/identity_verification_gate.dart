import 'package:flutter/material.dart';

import '../data/repository/identity_verification_gateway_impl.dart';
import '../usecase/check_and_request_identity_verification_usecase.dart';
import '../screen/identity_verification_screen.dart';

class IdentityVerificationGate extends StatelessWidget {
  final WidgetBuilder onPassedBuilder;

  const IdentityVerificationGate({super.key, required this.onPassedBuilder});

  Future<bool> _ensureVerified(BuildContext context) async {
    final gateway = IdentityVerificationGatewayImpl();
    final useCase = CheckAndRequestIdentityVerificationUseCase(gateway);

    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => IdentityVerificationScreen(useCase: useCase),
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _ensureVerified(context),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final passed = snapshot.data ?? false;
        if (!passed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return Builder(builder: onPassedBuilder);
      },
    );
  }
}
