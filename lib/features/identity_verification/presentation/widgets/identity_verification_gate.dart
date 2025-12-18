import 'package:flutter/material.dart';

import 'package:bidbird/features/identity_verification/data/repositories/identity_verification_repository.dart';
import 'package:bidbird/features/identity_verification/domain/usecases/check_and_request_identity_verification_usecase.dart';
import 'package:bidbird/features/identity_verification/presentation/screens/identity_verification_screen.dart';

class IdentityVerificationGate extends StatelessWidget {
  final WidgetBuilder onPassedBuilder;

  const IdentityVerificationGate({super.key, required this.onPassedBuilder});

  Future<bool> _ensureVerified(BuildContext context) async {
    final repository = IdentityVerificationRepositoryImpl();
    final useCase = CheckAndRequestIdentityVerificationUseCase(repository);

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



