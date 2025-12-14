import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 아이템 거래 상태 관련 유틸리티

/// 거래 상태 문자열에 따른 색상을 반환
Color getTradeStatusColor(String status) {
  // 경매 등록: 파란색
  if (status.contains('경매 등록')) {
    return blueColor;
  }

  // 배송 중: 파란색
  if (status == '배송 중') {
    return blueColor;
  }

  // 경매/입찰 진행 중 또는 성공 계열: 초록색
  if (status.contains('경매 진행 중') ||
      status.contains('입찰 중') ||
      status.contains('최고가 입찰') ||
      status.contains('입찰 성공') ||
      status.contains('즉시 구매 진행 중') ||
      status == '낙찰') {
    return Colors.green;
  }

  // 상위 입찰 발생: 주황색
  if (status.contains('상위 입찰 발생')) {
    return Colors.orange;
  }

  // 실패/제한 계열: 빨간색
  if (status.contains('유찰') ||
      status.contains('패찰') ||
      status.contains('입찰 제한') ||
      status.contains('거래정지') ||
      status.contains('결제 실패') ||
      status.contains('결제 실패 횟수 초과') ||
      status.contains('현재가보다 낮은 입찰')) {
    return Colors.redAccent;
  }

  // 종료/완료 계열: 회색
  if (status.contains('경매 종료') ||
      status.contains('경매 종료 후 입찰') ||
      status.contains('즉시 구매 완료') ||
      status.contains('입찰 없음')) {
    return Colors.grey;
  }

  return Colors.black54;
}

