import 'package:bidbird/core/utils/payment/payment_constants.dart';
import 'package:flutter/material.dart';

/// 결제 상태 관련 유틸리티

/// 결제 상태 코드에 따른 텍스트 반환
String getPaymentStatusText(int statusCode, {bool isCompleted = false}) {
  if (statusCode == PaymentStatusCodes.auctionWin) {
    return PaymentStatusTexts.auctionWin;
  } else if (statusCode == PaymentStatusCodes.instantBuy) {
    return PaymentStatusTexts.instantBuy;
  } else if (isCompleted) {
    return PaymentStatusTexts.completed;
  }
  return PaymentStatusTexts.completed;
}

/// 결제 상태 코드에 따른 거래 방식 텍스트 반환
String getPaymentTransactionTypeText(int statusCode) {
  if (statusCode == PaymentStatusCodes.instantBuy) {
    return PaymentStatusTexts.instantBuy;
  } else {
    return PaymentStatusTexts.auctionWin;
  }
}

/// 결제 상태에 따른 색상 반환
Color getPaymentStatusColor(bool isCompleted) {
  return Color(
    isCompleted
        ? PaymentStatusColors.completedText
        : PaymentStatusColors.incompleteText,
  );
}

/// 결제 상태에 따른 배경 색상 반환
Color getPaymentStatusBackgroundColor(bool isCompleted) {
  return Color(
    isCompleted
        ? PaymentStatusColors.completedBackground
        : PaymentStatusColors.incompleteBackground,
  );
}

