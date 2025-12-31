/// 데이터/네트워크 예외를 사용자 메시지로 변환
class ErrorMapper {
  String map(Object error) {
    final s = error.toString();

    // 공통 패턴 정리
    if (s.contains('Exception: ')) {
      return s.replaceFirst('Exception: ', '');
    }
    if (s.contains('로그인이 필요합니다')) {
      return '로그인이 필요합니다.';
    }
    if (s.contains('필수') && s.contains('누락')) {
      return '필수 정보가 누락되었습니다. 모든 항목을 입력해주세요.';
    }
    if (s.contains('서버 오류')) {
      return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }

    // 입찰 관련 에러 패턴
    if (s.contains('AUCTION_ALREADY_ENDED')) {
      return '경매가 이미 종료되었습니다.';
    }
    if (s.contains('ALREADY_TOP_BIDDER')) {
      return '이미 최고 입찰자입니다.';
    }
    if (s.contains('AUCTION_NOT_IN_PROGRESS')) {
      return '진행 중인 경매가 아닙니다.';
    }
    if (s.contains('BID_PRICE_TOO_LOW')) {
      return '입찰가는 현재가보다 높아야 합니다.';
    }

    // 기본 메시지
    return '요청 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.';
  }
}
