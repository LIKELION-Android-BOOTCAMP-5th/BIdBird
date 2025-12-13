import 'package:flutter/material.dart';
import 'responsive_utils.dart';

// responsive_utils의 extension 메서드들도 사용할 수 있도록 export
export 'responsive_utils.dart';

/// 반응형 디자인 상수
/// 공통으로 사용되는 반응형 값들을 미리 정의합니다.
class ResponsiveConstants {
  // 패딩
  static double horizontalPadding(BuildContext context) =>
      context.widthRatio(0.05, min: 16.0, max: 24.0);
  
  static double verticalPadding(BuildContext context) =>
      context.heightRatio(0.02, min: 12.0, max: 20.0);
  
  static double screenPadding(BuildContext context) =>
      context.widthRatio(0.04, min: 12.0, max: 20.0);

  // 간격
  static double spacingSmall(BuildContext context) =>
      context.widthRatio(0.02, min: 6.0, max: 10.0);
  
  static double spacingMedium(BuildContext context) =>
      context.heightRatio(0.025, min: 16.0, max: 28.0);
  
  static double spacingLarge(BuildContext context) =>
      context.heightRatio(0.05, min: 24.0, max: 40.0);

  // 폰트 크기
  static double fontSizeSmall(BuildContext context) =>
      context.widthRatio(0.032, min: 11.0, max: 15.0);
  
  static double fontSizeMedium(BuildContext context) =>
      context.widthRatio(0.037, min: 12.0, max: 16.0);
  
  static double fontSizeLarge(BuildContext context) =>
      context.widthRatio(0.045, min: 16.0, max: 20.0);
  
  static double fontSizeXLarge(BuildContext context) =>
      context.widthRatio(0.055, min: 18.0, max: 26.0);

  // 버튼
  static double buttonHeight(BuildContext context) =>
      context.heightRatio(0.065, min: 48.0, max: 60.0);
  
  static double buttonFontSize(BuildContext context) =>
      context.widthRatio(0.042, min: 14.0, max: 18.0);

  // 이미지/아이콘
  static double iconSizeSmall(BuildContext context) =>
      context.widthRatio(0.05, min: 18.0, max: 24.0);
  
  static double iconSizeMedium(BuildContext context) =>
      context.widthRatio(0.08, min: 28.0, max: 40.0);
  
  static double imageSize(BuildContext context) =>
      context.widthRatio(0.3, min: 100.0, max: 140.0);
  
  // 특수 케이스
  static double bottomPadding(BuildContext context) =>
      context.heightRatio(0.1, min: 60.0, max: 100.0);
  
  static double labelBottomPadding(BuildContext context) =>
      context.widthRatio(0.02, min: 6.0, max: 10.0);
  
  static double borderWidth(BuildContext context) =>
      context.widthRatio(0.004, min: 1.0, max: 2.0);
  
  static double inputPadding(BuildContext context) =>
      context.widthRatio(0.03, min: 10.0, max: 16.0);
}

/// Extension으로 더 간편하게 사용
extension ResponsiveConstantsExtension on BuildContext {
  // 패딩
  double get hPadding => ResponsiveConstants.horizontalPadding(this);
  double get vPadding => ResponsiveConstants.verticalPadding(this);
  double get screenPadding => ResponsiveConstants.screenPadding(this);
  
  // 간격
  double get spacingSmall => ResponsiveConstants.spacingSmall(this);
  double get spacingMedium => ResponsiveConstants.spacingMedium(this);
  double get spacingLarge => ResponsiveConstants.spacingLarge(this);
  
  // 폰트
  double get fontSizeSmall => ResponsiveConstants.fontSizeSmall(this);
  double get fontSizeMedium => ResponsiveConstants.fontSizeMedium(this);
  double get fontSizeLarge => ResponsiveConstants.fontSizeLarge(this);
  double get fontSizeXLarge => ResponsiveConstants.fontSizeXLarge(this);
  
  // 버튼
  double get buttonHeight => ResponsiveConstants.buttonHeight(this);
  double get buttonFontSize => ResponsiveConstants.buttonFontSize(this);
  
  // 아이콘/이미지
  double get iconSizeSmall => ResponsiveConstants.iconSizeSmall(this);
  double get iconSizeMedium => ResponsiveConstants.iconSizeMedium(this);
  double get imageSize => ResponsiveConstants.imageSize(this);
  
  // 특수 케이스
  double get bottomPadding => ResponsiveConstants.bottomPadding(this);
  double get labelBottomPadding => ResponsiveConstants.labelBottomPadding(this);
  double get borderWidth => ResponsiveConstants.borderWidth(this);
  double get inputPadding => ResponsiveConstants.inputPadding(this);
}

