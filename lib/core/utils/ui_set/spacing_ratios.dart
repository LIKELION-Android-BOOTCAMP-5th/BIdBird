/// 공통 간격 비율 상수
/// UI 요소의 위치와 크기를 결정하는 비율 값들
class SpacingRatios {
  /// 이미지 오버레이 패딩 비율 (0.67)
  /// 이미지 위의 버튼이나 라벨 위치에 사용
  static const double imageOverlayPadding = 0.67;
  
  /// 작은 폰트 크기 비율 (0.85)
  /// 작은 텍스트나 라벨에 사용
  static const double smallFontSize = 0.85;
  
  /// 중간 폰트 크기 비율 (0.9)
  /// 스텝 인디케이터 라벨 등에 사용
  static const double mediumFontSize = 0.9;
  
  /// 작은 간격 비율 (0.5)
  /// 세로 간격 축소에 사용
  static const double smallSpacing = 0.5;
}

/// 공통 UI 크기 상수
/// 고정된 크기 값들 (비율이 아닌 절대값)
class UISizes {
  /// 라벨과 필수 배지 사이 간격 (4px)
  static const double labelBadgeSpacing = 4.0;
  
  /// 필수 배지 가로 패딩 (6px)
  static const double requiredBadgeHorizontalPadding = 6.0;
  
  /// 필수 배지 세로 패딩 (2px)
  static const double requiredBadgeVerticalPadding = 2.0;
  
  /// 필수 배지 모서리 반경 (4px)
  static const double requiredBadgeBorderRadius = 4.0;
}

