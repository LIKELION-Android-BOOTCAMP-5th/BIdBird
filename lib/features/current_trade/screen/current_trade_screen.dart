import 'package:bidbird/core/utils/ui_set/colors.dart';
import 'package:bidbird/core/utils/ui_set/fonts.dart';
import 'package:bidbird/core/supabase_manager.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/current_trade_data.dart';
import '../widgets/history_card.dart';
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
  late Future<List<Map<String, String>>> _bidHistoryFuture;

  final TradeHistoryRepository _repository = TradeHistoryRepository();

  @override
  void initState() {
    super.initState();
    _supabase = SupabaseManager.shared.supabase;
    _saleHistoryFuture = _fetchMySaleHistory();
    _bidHistoryFuture = _fetchMyBidHistory();
  }

  Future<List<Map<String, String>>> _fetchMyBidHistory() async {
    try {
      return await _repository.fetchBidHistory();
    } catch (e) {
      debugPrint('[_fetchMyBidHistory] error: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('현재 거래 내역'),
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

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _bidHistoryFuture = _fetchMyBidHistory();
            });
            await _bidHistoryFuture;
          },
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: data.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = data[index];
              return HistoryCard(
                title: item['title'] ?? '',
                thumbnailUrl: item['thumbnailUrl'],
                status: item['status'] ?? '',
                date: item['date'],
                onTap: () {
                  final itemId = item['item_id'] ?? '';
                  if (itemId.isNotEmpty) {
                    context.push('/item/$itemId');
                  }
                },
              );
            },
          ),
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
            return HistoryCard(
              title: item['title'] ?? '',
              thumbnailUrl: item['thumbnailUrl'],
              status: item['status'] ?? '',
              date: item['date'],
              onTap: () {
                final itemId = item['item_id'] ?? '';
                debugPrint('[CurrentTradeScreen] 카드 탭: item_id=$itemId');
                if (itemId.isNotEmpty) {
                  context.push('/item/$itemId');
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