import 'package:flutter/material.dart';

/// 폼 검증을 위한 공통 mixin
/// State 클래스에서 사용하여 에러 처리 로직을 통일
/// 
/// 사용 예시:
/// ```dart
/// class MyCardState extends State<MyCard> with FormValidationMixin {
///   String? _fieldError;
///   bool _shouldShowErrors = false;
///   
///   @override
///   void validateFields() {
///     startValidation(() {
///       _fieldError = null;
///       // 검증 로직
///       if (someCondition) {
///         _fieldError = '에러 메시지';
///       }
///     });
///   }
///   
///   @override
///   void clearAllErrors() {
///     _fieldError = null;
///   }
/// }
/// ```
mixin FormValidationMixin<T extends StatefulWidget> on State<T> {
  /// 에러 표시 여부 (하위 클래스에서 선언)
  bool get shouldShowErrors;
  
  /// 에러 표시 여부 설정 (하위 클래스에서 구현)
  set shouldShowErrors(bool value);

  /// 검증 시작
  /// [validationCallback]에서 에러를 초기화하고 검증 로직을 수행
  void startValidation(VoidCallback validationCallback) {
    if (mounted) {
      setState(() {
        shouldShowErrors = true;
        clearAllErrors();
        validationCallback();
      });
    }
  }

  /// 검증 모드 종료
  void stopValidation() {
    if (mounted) {
      setState(() {
        shouldShowErrors = false;
        clearAllErrors();
      });
    }
  }

  /// 모든 에러를 초기화
  /// 하위 클래스에서 구현해야 함
  void clearAllErrors();

  /// 특정 에러를 안전하게 제거
  /// [errorSetter]는 에러를 null로 설정하는 콜백
  void clearError(VoidCallback errorSetter) {
    if (mounted && shouldShowErrors) {
      setState(() {
        errorSetter();
      });
    }
  }
}

