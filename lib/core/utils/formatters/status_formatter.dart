import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

/// 거래 상태 라벨/색상 매퍼
class TradeStatusFormatter {
  static Color color(String status) {
    // 기존 getTradeStatusColor와 일치하도록 기본 색상 매핑
    switch (status) {
      case '경매 대기':
        return yellowColor;
      case '거래 진행':
        return blueColor;
      case '거래 완료':
        return Colors.green;
      case '취소됨':
        return Colors.red;
      default:
        return textColor;
    }
  }

  static String labelFromCode(int? code) {
    if (code == null) return '알 수 없음';
    switch (code) {
      case 410:
        return '입찰';
      case 411:
        return '상위 입찰';
      case 430:
        return '낙찰';
      case 431:
        return '즉시 구매 낙찰';
      default:
        return '기록';
    }
  }
}
