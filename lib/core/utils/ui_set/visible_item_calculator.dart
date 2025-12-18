import 'package:flutter/material.dart';
import 'responsive_constants.dart';

/// 화면에 보이는 아이템 개수를 계산하는 유틸리티
class VisibleItemCalculator {
  /// 화면에 보이는 아이템 개수를 계산합니다
  /// 
  /// [context] BuildContext
  /// [estimatedItemHeight] 각 아이템의 예상 높이 (기본값: 90.0)
  /// [appBarHeight] AppBar 높이 (기본값: AppBar().preferredSize.height)
  /// [additionalHeight] 추가로 제외할 높이 (예: ActionHub, Summary 등)
  /// [bufferCount] 여유를 두고 추가로 로드할 개수 (기본값: 2)
  /// 
  /// Returns: 로드해야 할 아이템 개수
  static int calculateVisibleItemCount(
    BuildContext context, {
    double estimatedItemHeight = 90.0,
    double? appBarHeight,
    double additionalHeight = 0.0,
    int bufferCount = 2,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final effectiveAppBarHeight = appBarHeight ?? AppBar().preferredSize.height;
    
    // 사용 가능한 높이 계산
    final availableHeight = screenHeight - 
        effectiveAppBarHeight - 
        safeAreaTop - 
        safeAreaBottom - 
        additionalHeight;
    
    // 보이는 개수 계산
    final visibleItemCount = (availableHeight / estimatedItemHeight).ceil();
    
    // 여유를 두고 추가 개수 반환
    return visibleItemCount + bufferCount;
  }
  
  /// 채팅 리스트용 화면에 보이는 아이템 개수 계산
  /// 
  /// [context] BuildContext
  /// [verticalPadding] 수직 패딩 (기본값: context.vPadding * 2)
  /// 
  /// Returns: 로드해야 할 채팅방 개수
  static int calculateChatListVisibleCount(
    BuildContext context, {
    double? verticalPadding,
  }) {
    final padding = verticalPadding ?? (context.vPadding * 2);
    return calculateVisibleItemCount(
      context,
      estimatedItemHeight: 90.0,
      additionalHeight: padding,
      bufferCount: 2,
    );
  }
  
  /// 현재 거래 내역용 화면에 보이는 아이템 개수 계산
  /// 
  /// [context] BuildContext
  /// [actionHubHeight] ActionHub 높이 (기본값: 120.0)
  /// [verticalPadding] 수직 패딩 (기본값: context.vPadding * 2)
  /// 
  /// Returns: 로드해야 할 거래 내역 개수
  static int calculateTradeHistoryVisibleCount(
    BuildContext context, {
    double actionHubHeight = 120.0,
    double? verticalPadding,
  }) {
    final padding = verticalPadding ?? (context.vPadding * 2);
    return calculateVisibleItemCount(
      context,
      estimatedItemHeight: 100.0,
      additionalHeight: actionHubHeight + padding,
      bufferCount: 2,
    );
  }
}

