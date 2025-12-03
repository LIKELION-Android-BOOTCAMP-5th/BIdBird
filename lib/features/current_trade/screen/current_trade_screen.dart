import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/ui_set/border_radius.dart';
import '../../../core/utils/ui_set/icons.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  int _selectedTabIndex = 0;

  late final SupabaseClient _supabase;
  late Future<List<Map<String, String>>> _saleHistoryFuture;

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseManager.shared.supabase;
    _saleHistoryFuture = _fetchMySaleHistory();
  }

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
    // TODO: 추후 Supabase 연동 후 실제 입찰 내역 리스트로 교체
    if (_bidHistory.isEmpty) {
      return const Center(
        child: Text('입찰 내역이 없습니다.'),
      );
    }

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
            // TODO: _bidHistory에 item_id를 포함해 실제 상세 화면으로 이동하도록 수정
            final itemId = item['item_id'] ?? '';
            if (itemId.isNotEmpty) {
              GoRouter.of(context).push('/item/$itemId');
            }
          },
        );
      },
    );
  }

  Widget _buildSaleHistoryList() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _saleHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('판매 내역을 불러오는 중 오류가 발생했습니다.'),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return const Center(
            child: Text('판매 내역이 없습니다.'),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final item = data[index];
            return _HistoryCard(
              title: item['title'] ?? '',
              priceLabel: '최종 금액',
              price: item['price'] ?? '',
              thumbnailUrl: item['thumbnailUrl'],
              date: item['date'] ?? '',
              status: item['status'] ?? '',
              onTap: () {
                final itemId = item['item_id'] ?? '';
                debugPrint('[CurrentTradeScreen] 카드 탭: item_id=$itemId');
                if (itemId.isNotEmpty) {
                  GoRouter.of(context).push('/item/$itemId');
                } else {
                  debugPrint('[CurrentTradeScreen] item_id가 비어 있어서 이동하지 않습니다.');
                }
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, String>>> _fetchMySaleHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final statusRows = await _supabase
          .from('bid_status')
          .select('item_id, text_code, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (statusRows.isEmpty) {
        return [];
      }

      final List<Map<String, dynamic>> statusList =
          List<Map<String, dynamic>>.from(statusRows);

      final itemRows = await _supabase
          .from('items')
          .select('id, title, current_price, thumbnail_image')
          .eq('seller_id', user.id);

      final Map<String, Map<String, dynamic>> itemsById = {};
      for (final raw in itemRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id']?.toString();
        if (id != null) {
          itemsById[id] = row;
        }
      }

      return statusList.map<Map<String, String>>((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};

        return <String, String>{
          'item_id': itemId,
          'title': item['title']?.toString() ?? '',
          // 판매 내역 카드에서는 금액을 표시하지 않음
          'price': '',
          'thumbnailUrl': item['thumbnail_image']?.toString() ?? '',
          'date': _formatDateTime(row['created_at']?.toString()),
          'status': row['text_code']?.toString() ?? '',
        };
      }).toList();
    } catch (e, st) {
      debugPrint('[_fetchMySaleHistory] error: $e\n$st');
      rethrow;
    }
  }
}

String _formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;

    // 예: 2025-12-03 20:11
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  } catch (_) {
    return isoString;
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.title,
    required this.priceLabel,
    required this.price,
    this.thumbnailUrl,
    required this.date,
    required this.status,
    this.onTap,
  });

  final String title;
  final String priceLabel;
  final String price;
  final String? thumbnailUrl;
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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(defaultRadius),
                    child: (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
                        ? Image.network(
                            thumbnailUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.image,
                              size: 32,
                              color: Colors.grey,
                            ),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (price.isNotEmpty) ...[
                      Text(
                        '$priceLabel: $price',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
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

final List<Map<String, String>> _bidHistory = [];
