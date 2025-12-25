import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

/// 앱 브랜드 색상을 사용하는 로딩 인디케이터 위젯
/// 앱 전체에서 일관된 로딩 UI를 제공합니다.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.strokeWidth = 4.0,
    this.size,
  });

  /// 인디케이터 선의 두께
  final double strokeWidth;

  /// 인디케이터의 크기 (null이면 기본값 사용)
  final double? size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
      ),
    );
  }
}

/// 중앙에 배치된 로딩 인디케이터
class CenteredLoadingIndicator extends StatelessWidget {
  const CenteredLoadingIndicator({
    super.key,
    this.strokeWidth = 4.0,
    this.size,
  });

  /// 인디케이터 선의 두께
  final double strokeWidth;

  /// 인디케이터의 크기 (null이면 기본값 사용)
  final double? size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LoadingIndicator(
        strokeWidth: strokeWidth,
        size: size,
      ),
    );
  }
}

