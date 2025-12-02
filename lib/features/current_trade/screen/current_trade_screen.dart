import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/ui_set/border_radius.dart';
import '../../../core/utils/ui_set/icons.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('현재 거래 내역'),
            Image.asset(
              'assets/icons/alarm_icon.png',
              width: iconSize.width,
              height: iconSize.height,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedTabIndex == 0
                ? _buildSaleHistoryList()
                : _buildBidHistoryList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildTabButton(index: 0, label: '판매 내역'),
          const SizedBox(width: 8),
          _buildTabButton(index: 1, label: '입찰 내역'),
        ],
      ),
    );
  }

  Widget _buildTabButton({required int index, required String label}) {
    final bool isSelected = _selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? blueColor : Colors.white,
            borderRadius: BorderRadius.circular(defaultRadius),
            border: Border.all(color: blueColor),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: buttonFontStyle.fontSize,
              fontWeight: buttonFontStyle.fontWeight,
              color: isSelected ? Colors.white : blueColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBidHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _bidHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _bidHistory[index];
        return _HistoryCard(
          title: item['title'] ?? '',
          priceLabel: '입찰가',
          price: item['price'] ?? '',
          date: item['date'] ?? '',
          status: item['status'] ?? '',
          onTap: () {
            // TODO: 실제 아이템 ID를 사용해서 상세 화면으로 이동하도록 수정
            context.push('/item/item_1');
          },
        );
      },
    );
  }

  Widget _buildSaleHistoryList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _saleHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = _saleHistory[index];
        return _HistoryCard(
          title: item['title'] ?? '',
          priceLabel: '최종 금액',
          price: item['price'] ?? '',
          date: item['date'] ?? '',
          status: item['status'] ?? '',
          onTap: () {
            // TODO: 실제 아이템 ID를 사용해서 상세 화면으로 이동하도록 수정
            context.push('/item/item_1');
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.priceLabel,
    required this.price,
    required this.date,
    required this.status,
    this.onTap,
  });

  final String title;
  final String priceLabel;
  final String price;
  final String date;
  final String status;
  final VoidCallback? onTap;

  Color _statusColor() {
    if (status.contains('최고입찰 중') ||
        status.contains('즉시 구매') ||
        status == '낙찰') {
      return Colors.green;
    }
    if (status.contains('상위 입찰 발생')) {
      return Colors.orange;
    }
    if (status.contains('유찰') ||
        status.contains('패찰') ||
        status.contains('입찰 제한')) {
      return Colors.redAccent;
    }
    if (status.contains('입찰 없음')) {
      return Colors.grey;
    }
    return Colors.black54;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: defaultBorder,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 96,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(defaultRadius),
                  bottomLeft: Radius.circular(defaultRadius),
                ),
              ),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(defaultRadius),
                    ),
                    // todo: 이미지 교체
                    child: const Icon(
                      Icons.image,
                      size: 32,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '$priceLabel: $price',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: defaultBorder,
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO: 더미 데이터 (Supabase 연동 후 삭제 예정)
final List<Map<String, String>> _bidHistory = [
  {
    'title': '판매 내역 1',
    'price': '3,000,000원',
    'date': '11월 25일 오후 01:07',
    'status': '최고입찰 중',
  },
  {
    'title': '판매 내역 2',
    'price': '2,350,000원',
    'date': '11월 25일 오전 11:05',
    'status': '상위 입찰 발생',
  },
  {
    'title': '판매 내역 3',
    'price': '175,000원',
    'date': '11월 25일 오전 08:05',
    'status': '낙찰',
  },
  {
    'title': '판매 내역 4',
    'price': '95,000원',
    'date': '11월 25일 오후 12:05',
    'status': '패찰',
  },
  {
    'title': '판매 내역 5',
    'price': '350,000원',
    'date': '11월 24일 오후 09:30',
    'status': '입찰 제한',
  },
];

final List<Map<String, String>> _saleHistory = [
  {
    'title': '입찰 내역 1',
    'price': '1,150,000원',
    'date': '11월 20일 오후 09:10',
    'status': '낙찰',
  },
  {
    'title': '입찰 내역 2',
    'price': '530,000원',
    'date': '11월 18일 오후 06:30',
    'status': '즉시 구매',
  },
  {
    'title': '입찰 내역 3',
    'price': '210,000원',
    'date': '11월 15일 오후 02:10',
    'status': '입찰 없음',
  },
  {
    'title': '입찰 내역 4',
    'price': '95,000원',
    'date': '11월 10일 오후 05:40',
    'status': '유찰',
  },
  {
    'title': '입찰 내역 5',
    'price': '1,050,000원',
    'date': '11월 08일 오후 08:20',
    'status': '입찰 제한',
  },
];
