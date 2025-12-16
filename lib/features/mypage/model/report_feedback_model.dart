import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

//DB의숫자가뭔지모르겠어서일단이렇게함//enum을쓸필요가있나
String getReportStatusString(int? value) {
  switch (value) {
    case 0:
      return 'type_0';
    case 1:
      return 'type_1';
    case 2:
      return 'type_2';
    case 3:
      return 'type_3';
    case 4:
      return 'type_4';
    case 5:
      return 'type_5';
    case 6:
      return 'type_6';
    case 7:
      return 'type_7';
    case 8:
      return 'type_8';
    default:
      return 'type_9';
  }
}

//나중에색맞추기
Color getReportStatusColor(int? value) {
  switch (value) {
    case 0:
      return blueColor;
    case 1:
      return iconColor;
    case 2:
      return BackgroundColor;
    case 3:
      return textColor;
    case 4:
      return RedColor;
    case 5:
      return yellowColor;
    case 6:
      return BorderColor;
    case 7:
      return shadowHigh;
    case 8:
      return shadowLow;
    default:
      return itemRegistrationCardShadowColor;
  }
}

class ReportFeedbackModel {
  final String id;
  final String targetUserId;
  final String targetUserNickname;
  final String reportCode;
  final String reportCodeName;
  final String? itemId;
  final String? itemTitle;
  final String content;
  final int status;
  final DateTime createdAt;
  final String? feedback;
  final DateTime? feedbackedAt;

  const ReportFeedbackModel({
    required this.id,
    required this.targetUserId,
    required this.targetUserNickname,
    required this.reportCode,
    required this.reportCodeName,
    required this.itemId,
    required this.itemTitle,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.feedback,
    required this.feedbackedAt,
  });
}
