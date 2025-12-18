import 'package:flutter/material.dart';

/// 반응형 디자인을 위한 유틸리티 클래스
/// 화면 크기에 따라 적절한 값을 계산하여 반환합니다.
class ResponsiveUtils {
  /// 화면 크기를 가져옵니다
  static Size getScreenSize(BuildContext context) {
    return MediaQuery.of(context).size;
  }

  /// 화면 너비를 가져옵니다
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// 화면 높이를 가져옵니다
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// 화면 너비의 비율로 값을 계산하고 범위를 제한합니다
  /// 
  /// [context] BuildContext
  /// [ratio] 화면 너비에 대한 비율 (0.0 ~ 1.0)
  /// [min] 최소값
  /// [max] 최대값
  static double widthRatio(
    BuildContext context,
    double ratio, {
    double? min,
    double? max,
  }) {
    final width = getScreenWidth(context);
    final value = width * ratio;
    if (min != null && max != null) {
      return value.clamp(min, max);
    } else if (min != null) {
      return value.clamp(min, double.infinity);
    } else if (max != null) {
      return value.clamp(0, max);
    }
    return value;
  }

  /// 화면 높이의 비율로 값을 계산하고 범위를 제한합니다
  /// 
  /// [context] BuildContext
  /// [ratio] 화면 높이에 대한 비율 (0.0 ~ 1.0)
  /// [min] 최소값
  /// [max] 최대값
  static double heightRatio(
    BuildContext context,
    double ratio, {
    double? min,
    double? max,
  }) {
    final height = getScreenHeight(context);
    final value = height * ratio;
    if (min != null && max != null) {
      return value.clamp(min, max);
    } else if (min != null) {
      return value.clamp(min, double.infinity);
    } else if (max != null) {
      return value.clamp(0, max);
    }
    return value;
  }

  /// 작은 화면인지 확인합니다 (기본값: 400px 미만)
  static bool isSmallScreen(BuildContext context, {double threshold = 400.0}) {
    return getScreenWidth(context) < threshold;
  }

  /// 중간 화면인지 확인합니다
  static bool isMediumScreen(BuildContext context, {double min = 400.0, double max = 800.0}) {
    final width = getScreenWidth(context);
    return width >= min && width < max;
  }

  /// 큰 화면인지 확인합니다 (기본값: 800px 이상)
  static bool isLargeScreen(BuildContext context, {double threshold = 800.0}) {
    return getScreenWidth(context) >= threshold;
  }
}

/// 반응형 값들을 미리 정의한 확장 클래스
/// BuildContext에서 직접 사용할 수 있습니다
extension ResponsiveExtension on BuildContext {
  /// 화면 너비를 가져옵니다
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);

  /// 화면 높이를 가져옵니다
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);

  /// 화면 너비의 비율로 값을 계산합니다
  double widthRatio(double ratio, {double? min, double? max}) {
    return ResponsiveUtils.widthRatio(this, ratio, min: min, max: max);
  }

  /// 화면 높이의 비율로 값을 계산합니다
  double heightRatio(double ratio, {double? min, double? max}) {
    return ResponsiveUtils.heightRatio(this, ratio, min: min, max: max);
  }

  /// 작은 화면인지 확인합니다
  bool isSmallScreen({double threshold = 400.0}) {
    return ResponsiveUtils.isSmallScreen(this, threshold: threshold);
  }

  /// 중간 화면인지 확인합니다
  bool isMediumScreen({double min = 400.0, double max = 800.0}) {
    return ResponsiveUtils.isMediumScreen(this, min: min, max: max);
  }

  /// 큰 화면인지 확인합니다
  bool isLargeScreen({double threshold = 800.0}) {
    return ResponsiveUtils.isLargeScreen(this, threshold: threshold);
  }
}





