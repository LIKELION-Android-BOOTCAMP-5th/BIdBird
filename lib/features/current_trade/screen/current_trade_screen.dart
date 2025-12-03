import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/ui_set/border_radius.dart';
import '../../../core/utils/ui_set/icons.dart';
import '../viewmodel/current_trade_viewmodel.dart';

class CurrentTradeScreen extends StatefulWidget {
  const CurrentTradeScreen({super.key});

  @override
  State<CurrentTradeScreen> createState() => _CurrentTradeScreenState();
}

class _CurrentTradeScreenState extends State<CurrentTradeScreen> {
  int _selectedTabIndex = 0;

  late final SupabaseClient _supabase;
  late Future<List<Map<String, String>>> _saleHistoryFuture;
  late Future<List<Map<String, String>>> _bidHistoryFuture;

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseManager.shared.supabase;
    _saleHistoryFuture = _fetchMySaleHistory();
    _bidHistoryFuture = _fetchMyBidHistory();
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
            child: RefreshIndicator(
              color: Colors.blue,
              backgroundColor: Colors.transparent,
              strokeWidth: 2.5,
              onRefresh: _onRefresh,
              child: _selectedTabIndex == 0
                  ? _buildSaleHistoryList()
                  : _buildBidHistoryList(),
            ),
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
    return FutureBuilder<List<Map<String, String>>>(
      future: _bidHistoryFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text('입찰 내역을 불러오는 중 오류가 발생했습니다.'),
          );
        }

        final data = snapshot.data ?? [];

        if (data.isEmpty) {
          return const Center(
            child: Text('입찰 내역이 없습니다.'),
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
              priceLabel: '입찰가',
              price: item['price'] ?? '',
              thumbnailUrl: item['thumbnailUrl'],
              date: item['date'] ?? '',
              status: item['status'] ?? '',
              onTap: () {
                final itemId = item['item_id'] ?? '';
                if (itemId.isNotEmpty) {
                  GoRouter.of(context).push('/item/$itemId');
                }
              },
            );
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
      for (final row in itemRows) {
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

  Future<void> _onRefresh() async {
    setState(() {
      _saleHistoryFuture = _fetchMySaleHistory();
      _bidHistoryFuture = _fetchMyBidHistory();
    });

    await Future.wait([
      _saleHistoryFuture,
      _bidHistoryFuture,
    ]);
  }

  Future<List<Map<String, String>>> _fetchMyBidHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final bidRows = await _supabase
          .from('bid_log')
          .select('item_id, bid_price, created_at, status, bid_user')
          .eq('bid_user', user.id)
          .order('created_at', ascending: false);

      if (bidRows.isEmpty) {
        return [];
      }

      final Map<String, Map<String, dynamic>> latestBidByItem = {};
      for (final row in bidRows) {
        final itemId = row['item_id']?.toString();
        if (itemId == null || itemId.isEmpty) continue;
        if (!latestBidByItem.containsKey(itemId)) {
          latestBidByItem[itemId] = row;
        }
      }

      final List<Map<String, dynamic>> bids = latestBidByItem.values.toList();

      final Set<String> itemIds = {};
      for (final row in bids) {
        final id = row['item_id']?.toString();
        if (id != null && id.isNotEmpty) {
          itemIds.add(id);
        }
      }

      final Map<String, Map<String, dynamic>> itemsById = {};
      final Map<String, String> statusByItemId = {};

      if (itemIds.isNotEmpty) {
        final itemRows = await _supabase
            .from('items')
            .select('id, title, thumbnail_image, current_price')
            .inFilter('id', itemIds.toList());

        for (final row in itemRows) {
          final id = row['id']?.toString();
          if (id != null) {
            itemsById[id] = row;
          }
        }

        final statusRows = await _supabase
            .from('bid_status')
            .select('item_id, text_code')
            .eq('user_id', user.id)
            .inFilter('item_id', itemIds.toList());

        for (final row in statusRows) {
          final id = row['item_id']?.toString();
          if (id != null) {
            statusByItemId[id] = row['text_code']?.toString() ?? '';
          }
        }
      }

      return bids.map<Map<String, String>>((row) {
        final itemId = row['item_id']?.toString() ?? '';
        final item = itemsById[itemId] ?? <String, dynamic>{};
        final bidPrice = row['bid_price'] as int? ?? 0;

        final currentPrice = item['current_price'] as int? ?? 0;
        final rawStatus = statusByItemId[itemId] ?? '';

        String displayStatus;
        final bool isTopBidder = currentPrice > 0 && bidPrice == currentPrice;

        if (rawStatus.contains('입찰 제한') || rawStatus.contains('거래정지')) {
          displayStatus = '거래정지';
        } else if (isTopBidder) {
          displayStatus = '최고가 입찰';
        } else {
          displayStatus = '패찰';
        }

        return <String, String>{
          'item_id': itemId,
          'title': item['title']?.toString() ?? '',
          'price': '',
          'thumbnailUrl': item['thumbnail_image']?.toString() ?? '',
          'date': '',
          'status': displayStatus,
        };
      }).toList();
    } catch (e, st) {
      debugPrint('[_fetchMyBidHistory] error: $e\n$st');
      rethrow;
    }
  }
}

String _formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) return '';
  try {
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return isoString;

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


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: CurrentTradeViewModel.getStatusColor(status),
                          ),
                        ),
                      ),
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
