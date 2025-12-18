import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/identity_verification/domain/entities/identity_verification_error_messages.dart';
import 'package:bidbird/features/identity_verification/domain/entities/identity_verification_texts.dart';
import 'package:bidbird/features/identity_verification/data/repositories/identity_verification_repository.dart';
import 'package:bidbird/features/identity_verification/presentation/screens/identity_verification_screen.dart';
import 'package:bidbird/features/identity_verification/domain/usecases/check_and_request_identity_verification_usecase.dart';
import 'package:flutter/material.dart';

Future<bool> ensureIdentityVerified(
  BuildContext context, {
  String? message,
  VoidCallback? onCancel,
}) async {
  final repository = IdentityVerificationRepositoryImpl();

  // 1. 먼저 서버에서 CI 존재 여부 확인
  try {
    final hasCi = await repository.hasCi();
    if (hasCi) {
      // 이미 CI가 있으면 팝업 없이 바로 통과
      return true;
    }
  } catch (e) {
    // CI 조회 실패 시에는 아래 본인인증 플로우로 유도
  }

  bool proceed = false;

  // 2. CI가 없을 때만 AskPopup으로 본인인증 안내
  if (!context.mounted) return false;
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return AskPopup(
        content: message ?? IdentityVerificationTexts.defaultMessage,
        noText: IdentityVerificationTexts.cancel,
        yesText: IdentityVerificationTexts.confirm,
        yesLogic: () async {
          proceed = true;
          Navigator.of(dialogContext).pop();
        },
      );
    },
  );

  if (!proceed) {
    onCancel?.call();
    return false;
  }

  // 3. 팝업에서 확인을 누른 경우에만 본인인증 화면으로 이동
  try {
    if (!context.mounted) return false;

    final useCase = CheckAndRequestIdentityVerificationUseCase(repository);
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => IdentityVerificationScreen(useCase: useCase),
      ),
    );

    if (!context.mounted) return false;
    
    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(IdentityVerificationErrorMessages.verificationRequired),
        ),
      );
    }

    return result ?? false;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(IdentityVerificationErrorMessages.verificationStatusCheckFailed(e)),
      ),
    );
    return false;
  }
}

