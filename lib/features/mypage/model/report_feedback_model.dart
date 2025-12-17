import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

//DB의숫자가뭔지모르겠어서일단이렇게함//enum을쓸필요가있나
String getReportCodeName(String? reportCode) {
  switch (reportCode) {
    case 'communication_report_01':
      return '욕설·비방';
    case 'communication_report_02':
      return '스팸·도배';
    case 'communication_report_03':
      return '사기 유도 메시지';
    case 'communication_report_04':
      return '외부 거래 유도';

    case 'item_report_01':
      return '허위매물';
    case 'item_report_02':
      return '광고';
    case 'item_report_03':
      return '거래 금지 품목';
    case 'item_report_04':
      return '위조품·가품 의심';
    case 'item_report_05':
      return '상품 정보 불일치';
    case 'item_report_06':
      return '이미지 도용';
    case 'item_report_07':
      return '가격 조작 의심';

    case 'policy_report_01':
      return '약관 위반';
    case 'policy_report_02':
      return '운영자 검토 요청';
    case 'policy_report_03':
      return '시스템 오류';

    case 'transaction_report_01':
      return '결제 사기 의심';
    case 'transaction_report_02':
      return '환불 분쟁';
    case 'transaction_report_03':
      return '배송 지연';
    case 'transaction_report_04':
      return '배송 미이행';
    case 'transaction_report_05':
      return '송장 정보 허위';

    case 'user_report_01':
      return '사기 의심';
    case 'user_report_02':
      return '반복 미결제';
    case 'user_report_03':
      return '악의적 입찰';
    case 'user_report_04':
      return '계정 도용 의심';
    case 'user_report_05':
      return '다중 계정 의심';

    default:
      return '';
  }
}

//나중에색맞추기
Color getReportCodeColor(String? reportCode) {
  switch (reportCode) {
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
  final String? targetCi;
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
    required this.targetCi,
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
