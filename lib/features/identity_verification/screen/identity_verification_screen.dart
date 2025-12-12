import 'package:bidbird/core/utils/identity_verification/identity_verification_error_messages.dart';
import 'package:bidbird/core/utils/identity_verification/identity_verification_texts.dart';
import 'package:flutter/material.dart';

import '../usecase/check_and_request_identity_verification_usecase.dart';

class IdentityVerificationScreen extends StatefulWidget {
  final CheckAndRequestIdentityVerificationUseCase useCase;

  const IdentityVerificationScreen({super.key, required this.useCase});

  @override
  State<IdentityVerificationScreen> createState() => _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState extends State<IdentityVerificationScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.useCase(context);
      if (!mounted) return;

      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = IdentityVerificationErrorMessages.verificationError;
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startFlow,
                        child: const Text(IdentityVerificationErrorMessages.retry),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
