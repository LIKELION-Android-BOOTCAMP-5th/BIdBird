import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:flutter/material.dart';

/// 구매/판매/낙찰 역할을 표시하는 인디케이터 컴포넌트
class RoleBadge extends StatelessWidget {
  const RoleBadge({
    super.key,
    required this.isSeller,
    this.isTopBidder = false,
    this.isOpponentTopBidder = false,
    this.isExpired = false,
    this.fontSize,
    this.padding,
  });

  /// true면 판매자, false면 구매자
  final bool isSeller;
  
  /// true면 내가 낙찰자 (구매자이면서 낙찰자) → "낙찰 물품" 표시
  final bool isTopBidder;
  
  /// true면 상대방이 낙찰자 (내가 판매자이고 상대방이 낙찰자) → "낙찰자" 표시
  final bool isOpponentTopBidder;
  
  /// true면 거래가 만료됨 → 회색으로 표시
  final bool isExpired;
  
  /// 폰트 크기 (기본값: 11)
  final double? fontSize;
  
  /// 패딩 (기본값: EdgeInsets.symmetric(horizontal: 8, vertical: 3))
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    // 만료된 거래는 "만료"로 표시
    if (isExpired) {
      return Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1), // 회색 배경
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '만료',
          style: TextStyle(
            color: iconColor, // 회색 텍스트
            fontSize: fontSize ?? 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // 내가 구매자이고 낙찰자인 경우: "낙찰 물품" (노란색)
    if (!isSeller && isTopBidder) {
      return Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD), // 노란색 배경
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '낙찰 물품',
          style: TextStyle(
            color: const Color(0xFF856404), // 노란색 텍스트
            fontSize: fontSize ?? 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // 내가 판매자이고 상대방이 낙찰자인 경우: "낙찰자" (노란색)
    if (isSeller && isOpponentTopBidder) {
      return Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD), // 노란색 배경
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '낙찰자',
          style: TextStyle(
            color: const Color(0xFF856404), // 노란색 텍스트
            fontSize: fontSize ?? 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    
    // 기본 역할 색상 결정
    final roleSubColor = isSeller ? roleSaleSub : rolePurchaseSub;
    final roleTextColor = isSeller ? roleSaleText : rolePurchaseText;
    final roleLabel = isSeller ? '판매' : '구매';

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: roleSubColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        roleLabel,
        style: TextStyle(
          color: roleTextColor,
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

