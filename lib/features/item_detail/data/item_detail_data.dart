import 'package:flutter/material.dart';

class ItemDetail {
  ItemDetail({
    required this.itemId,
    required this.itemTitle,
    required this.itemImages,
    required this.finishTime,
    required this.sellerTitle,
    required this.buyNowPrice,
    required this.biddingCount,
    required this.itemContent,
    required this.currentPrice,
    required this.bidPrice,
    required this.sellerRating,
    required this.sellerReviewCount,
  });

  final String itemId;
  final String itemTitle;
  final List<String> itemImages; // image url list
  final DateTime finishTime; // 잔여 시간 계산용 종료 시각
  final String sellerTitle; // 판매자 닉네임
  final int buyNowPrice; // 즉시 구매 가격
  final int biddingCount; // 입찰 인원 / 건수
  final String itemContent; // 상품 설명
  final int currentPrice; // 현재 가격
  final int bidPrice; // 1회 호가 금액
  final double sellerRating; // 판매자 평점
  final int sellerReviewCount; // 판매자 리뷰 수
}

// TODO: 더미데이터
final dummyItemDetail = ItemDetail(
  itemId: 'item_1',
  itemTitle: '123123',
  itemImages: [
    'https://via.placeholder.com/600x400',
    'https://via.placeholder.com/600x400',
    'https://via.placeholder.com/600x400',
  ],
  finishTime: DateTime.now().add(const Duration(hours: 11, minutes: 11, seconds: 11)),
  sellerTitle: '김재현',
  buyNowPrice: 2100000,
  biddingCount: 5,
  itemContent: '12312312312312312312312312312312312312312312312312312312312312331231231231231231231231231231231231231231231231231231231231231231123123123123123123123123123123123123123123123123123123123123123',
  currentPrice: 1500000,
  bidPrice: 10000,
  sellerRating: 4.9,
  sellerReviewCount: 120,
);

