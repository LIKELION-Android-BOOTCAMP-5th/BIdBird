import 'dart:ui';

import 'package:flutter/material.dart';

const Color blueColor = Color(0xff0064FF);
const Color iconColor = Color(0xff9E9E9E);
const Color BackgroundColor = Color(0xffF8F8FA);
const Color textColor = Colors.black;
const Color RedColor = Color(0xffFF5252);
const Color yellowColor = Color(0xffFFA726);
const Color BorderColor = Color(0xffBDBDBD);
const Color LightBorderColor = Color(0xFFE6E8EB); // 연한 테두리 색상
const Color shadowHigh = Color(0x1F000000);
const Color shadowLow = Color(0x0A000000);
const Color itemRegistrationCardShadowColor = shadowHigh;
const Color ImageBackgroundColor = Color(0xffE0E0E0);
const Color TopBidderTextColor = Color(0xff757575);

// trade_status_chip 컬러
const Color tradeBidPendingColor = Color(0xffF2994A); // 입찰 중
const Color tradePurchaseDoneColor = Color(0xff4C6FFF); // 구매 완료
const Color tradeSaleDoneColor = Color(0xff27AE60); // 판매 완료
const Color tradeBlockedColor = Color(0xffFF5252); // 거래 정지

// 채팅 화면 색상 체계
const Color brandBlue = Color(0xff2E6AF2); // 핵심 파란색 (전송 버튼, 액션 아이콘)
const Color myMessageBubbleColor = Color(0xff4A7FF0); // 내 메시지 말풍선 (채도 낮춘 파란색)
const Color opponentMessageBubbleColor = Color(0xffE8E9ED); // 상대 메시지 말풍선 (중립색)
const Color chatTopCardBackground = Color(0xffF0F2F5); // 상단 카드 배경
const Color chatTextColor = Color(0xff1F2937); // 채팅 텍스트 색상 (상단 카드, 입력창, 상대 메시지)
const Color chatInputBackground = Color(0xffEFEFF1); // 입력창 배경
const Color chatPlusIconColor = Color(0xff5A86F2); // 플러스 버튼 아이콘 (중명도 파랑)
const Color chatBackgroundColor = Color(0xffF7F8FA); // 채팅 화면 전체 배경
const Color chatTimeTextColor = Color(0xff9CA3AF); // 시간 텍스트 색상
const Color chatItemSectionBackground = Color(0xffF2F3F5); // 매물 정보 섹션 배경
const Color chatItemCardBackground = Color(0xffFFFFFF); // 매물 정보 카드 배경

// 폼 및 입력 필드 색상
const Color PrimaryBlue = Color(0xFF2F5BFF); // 주요 파란색 (커서, 포커스 등)
const Color TextPrimary = Color(0xFF111111); // 주요 텍스트 색상
const Color TextSecondary = Color(0xFF6B7280); // 보조 텍스트 색상

// 역할 구분 색상 (구매/판매)
// 구매 (Buyer)
const Color rolePurchasePrimary = Color(0xFF3B6EF6); // Primary: #3B6EF6
const Color rolePurchaseSub = Color(0xFFE8EEFF); // Sub(연한 톤): #E8EEFF
const Color rolePurchaseText = Color(0xFF1F3FB8); // 텍스트/아이콘 대비용: #1F3FB8

// 판매 (Seller)
const Color roleSalePrimary = Color(0xFF2FAE8E); // Primary: #2FAE8E
const Color roleSaleSub = Color(0xFFE6F6F1); // Sub(연한 톤): #E6F6F1
const Color roleSaleText = Color(0xFF1E7F68); // 텍스트/아이콘 대비용: #1E7F68