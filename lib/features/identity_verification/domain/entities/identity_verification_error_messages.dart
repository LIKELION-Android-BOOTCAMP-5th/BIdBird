/// 본인인증 관련 에러 메시지

class IdentityVerificationErrorMessages {
  /// 본인인증 중 오류 발생
  static const String verificationError = '본인인증 중 오류가 발생했습니다.';
  
  /// 본인인증 상태 확인 실패
  static String verificationStatusCheckFailed(Object error) => 
      '본인인증 상태를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.\n$error';
  
  /// 본인인증 후 이용 가능
  static const String verificationRequired = '본인 인증 후 이용 가능합니다.';
  
  /// 다시 시도 버튼 텍스트
  static const String retry = '다시 시도';
}



