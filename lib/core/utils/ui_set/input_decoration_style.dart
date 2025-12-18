import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';

/// 매물 등록 및 신고 화면에서 공통으로 사용하는 InputDecoration 스타일
InputDecoration createStandardInputDecoration(
  BuildContext context, {
  required String hint,
  String? errorText,
  Color? fillColor,
  Color? borderColor,
  Color? focusedBorderColor,
}) {
  final hintFontSize = context.fontSizeSmall;
  final horizontalPadding = context.inputPadding;
  final verticalPadding = context.inputPadding;
  final borderWidth = context.borderWidth;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: iconColor, fontSize: hintFontSize),
    contentPadding: EdgeInsets.symmetric(
      horizontal: horizontalPadding,
      vertical: verticalPadding,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(
        color: borderColor ?? BackgroundColor,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(
        color: borderColor ?? BackgroundColor,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(
        color: focusedBorderColor ?? blueColor,
        width: borderWidth,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: const BorderSide(color: RedColor),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(defaultRadius),
      borderSide: BorderSide(
        color: RedColor,
        width: borderWidth,
      ),
    ),
    errorStyle: TextStyle(
      color: RedColor,
      fontSize: hintFontSize,
    ),
    errorMaxLines: 1,
    filled: true,
    fillColor: fillColor ?? Colors.white,
  );
}

