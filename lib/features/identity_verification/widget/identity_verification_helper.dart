import 'package:bidbird/core/widgets/components/pop_up/ask_popup.dart';
import 'package:bidbird/features/identity_verification/data/repository/identity_verification_gateway_impl.dart';
import 'package:bidbird/features/identity_verification/screen/identity_verification_screen.dart';
import 'package:bidbird/features/identity_verification/usecase/check_and_request_identity_verification_usecase.dart';
import 'package:flutter/material.dart';

/// 본인인증이 필요한 작업 전에 호출하는 헬퍼 함수
/// 
/// [context] BuildContext
/// [message] 본인인증 안내 메시지 (기본값: '본인 인증을 해주세요.')
/// [onCancel] 사용자가 취소했을 때 호출되는 콜백 (선택사항)
/// 
/// Returns: 본인인증 성공 여부 (bool)
Future<bool> ensureIdentityVerified(
  BuildContext context, {
  String? message,
  VoidCallback? onCancel,
}) async {
  final gateway = IdentityVerificationGatewayImpl();

  // 1. 먼저 서버에서 CI 존재 여부 확인
  try {
    final hasCi = await gateway.hasCi();
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
        content: message ?? '본인 인증을 해주세요.',
        noText: '취소',
        yesText: '확인',
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

    final useCase = CheckAndRequestIdentityVerificationUseCase(gateway);
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute(
        builder: (_) => IdentityVerificationScreen(useCase: useCase),
      ),
    );

    if (!context.mounted) return false;
    
    if (result != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본인 인증 후 이용 가능합니다.'),
        ),
      );
    }

    return result ?? false;
  } catch (e) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('본인 인증 상태를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.\n$e'),
      ),
    );
    return false;
  }
}
