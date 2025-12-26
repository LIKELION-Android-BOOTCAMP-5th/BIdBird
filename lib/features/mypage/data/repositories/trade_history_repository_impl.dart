import '../../domain/entities/trade_history_entity.dart';
import '../../domain/repositories/trade_history_repository.dart';
import '../datasources/trade_history_remote_data_source.dart';
import '../models/trade_history_dto.dart';

class TradeHistoryRepositoryImpl implements TradeHistoryRepository {
  TradeHistoryRepositoryImpl({TradeHistoryRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? TradeHistoryRemoteDataSource();

  final TradeHistoryRemoteDataSource _remoteDataSource;

  @override
  Future<TradeHistoryPageEntity> fetchHistory({
    required TradeRole role,
    int? statusCode,
    required int page,
    required int pageSize,
  }) async {
    final List<TradeHistoryDto> allItems = role == TradeRole.seller
        ? await _fetchSellerHistory()
        : await _fetchBuyerHistory();

    final filtered = statusCode == null
        ? allItems
        : allItems.where((item) => item.statusCode == statusCode).toList();

    final start = (page - 1) * pageSize;
    if (start >= filtered.length) {
      return const TradeHistoryPageEntity(items: [], hasMore: false);
    }

    final pageItems = filtered.skip(start).take(pageSize).toList();
    final hasMore = start + pageSize < filtered.length;
    return TradeHistoryPageEntity(
      items: pageItems.map((dto) => dto.toEntity()).toList(),
      hasMore: hasMore,
    );
  }

  Future<List<TradeHistoryDto>> _fetchSellerHistory() async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final rows = await _remoteDataSource.fetchSellerHistory(userId);

    if (rows.isEmpty) return [];

    final List<TradeHistoryDto> results = [];
    for (final row in rows) {
      final itemId = row['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;

      final auction = _firstMap(row['auctions']);
      final price = (auction?['current_price'] as num?)?.toInt() ?? 0;
      final auctionCode = auction?['auction_status_code'] as int?;
      final tradeCode = auction?['trade_status_code'] as int?;
      final statusCode = tradeCode ?? auctionCode ?? 0;
      final endAt = DateTime.tryParse(
        auction?['auction_end_at']?.toString() ?? '',
      );

      results.add(
        TradeHistoryDto(
          itemId: itemId,
          role: TradeRole.seller,
          title: row['title']?.toString() ?? '',
          currentPrice: price,
          statusCode: statusCode,
          buyNowPrice: (row['buy_now_price'] as num?)?.toInt(),
          thumbnailUrl: row['thumbnail_image']?.toString(),
          createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
          endAt: endAt,
        ),
      );
    }

    final nowUtc = DateTime.now().toUtc();
    results.sort((a, b) => _compareHistory(a, b, nowUtc: nowUtc));

    return results;
  }

  Future<List<TradeHistoryDto>> _fetchBuyerHistory() async {
    final userId = _remoteDataSource.currentUserId;
    if (userId == null) {
      throw Exception('로그인 정보가 없습니다.');
    }

    final logRows = await _remoteDataSource.fetchBuyerHistory(userId);

    if (logRows.isEmpty) return [];

    // 아이템별 최신 로그만
    final Map<String, Map<String, dynamic>> latestLogByItem = {};
    for (final row in logRows) {
      final auction = _asMap(row['auction']) ?? _asMap(row['auctions']);
      final itemId = auction?['item_id']?.toString();
      if (itemId == null || itemId.isEmpty) continue;
      final created = _parseDate(row['created_at']);
      final prevCreated = _parseDate(latestLogByItem[itemId]?['created_at']);
      if (prevCreated == null ||
          (created != null && created.isAfter(prevCreated))) {
        latestLogByItem[itemId] = row;
      }
    }

    final List<TradeHistoryDto> results = [];
    final nowUtc = DateTime.now().toUtc();

    for (final entry in latestLogByItem.entries) {
      final itemId = entry.key;
      final logRow = entry.value;
      final auction =
          _asMap(logRow['auction']) ??
          _asMap(logRow['auctions']) ??
          <String, dynamic>{};
      final item =
          _firstMap(auction['items_detail']) ?? _asMap(auction['items_detail']);
      final tradeRow = _firstMap(item?['trade_status']);

      // trade_status가 있으면 우선 사용
      if (tradeRow != null &&
          (tradeRow['buyer_id'] == null ||
              tradeRow['buyer_id']?.toString() == userId)) {
        final endAt = _parseDate(auction['auction_end_at']);
        final tradeCode = tradeRow['trade_status_code'] as int?;
        results.add(
          TradeHistoryDto(
            itemId: itemId,
            role: TradeRole.buyer,
            title: item?['title']?.toString() ?? '',
            currentPrice: (tradeRow['price'] as num?)?.toInt() ?? 0,
            statusCode: tradeCode ?? 0,
            buyNowPrice: (item?['buy_now_price'] as num?)?.toInt(),
            thumbnailUrl: item?['thumbnail_image']?.toString(),
            createdAt: _parseDate(tradeRow['created_at']),
            endAt: endAt,
          ),
        );
        continue;
      }

      // 거래가 없으면 로그 기반으로 상태 계산
      final lastBidUserId = auction['last_bid_user_id']?.toString();
      final logCode = logRow['auction_log_code'] as int?;
      final createdAt = _parseDate(logRow['created_at']);
      final auctionStatus = auction['auction_status_code'] as int?;
      const endedStatusCodes = {321, 322};
      final endAt = _parseDate(auction['auction_end_at']);
      final endAtUtc = endAt?.toUtc();
      final isEndedByTime =
          endAtUtc != null &&
          endAtUtc.isBefore(nowUtc); //상태코드로하는게더맞을거같은데어차피그것도크론으로정해질듯
      final isEndedByCode =
          auctionStatus != null && endedStatusCodes.contains(auctionStatus);
      final isEnded = isEndedByTime || isEndedByCode;
      final isWinner = lastBidUserId != null && lastBidUserId == userId;
      final statusCode = (!isWinner && isEnded) ? 433 : (logCode ?? 0);

      results.add(
        TradeHistoryDto(
          itemId: itemId,
          role: TradeRole.buyer,
          title: item?['title']?.toString() ?? '',
          currentPrice: (logRow['bid_price'] as num?)?.toInt() ?? 0,
          statusCode: statusCode,
          buyNowPrice: (item?['buy_now_price'] as num?)?.toInt(),
          thumbnailUrl: item?['thumbnail_image']?.toString(),
          createdAt: createdAt,
          endAt: endAt,
        ),
      );
    }

    results.sort((a, b) => _compareHistory(a, b, nowUtc: nowUtc));

    return results;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    return null;
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is List &&
        value.isNotEmpty &&
        value.first is Map<String, dynamic>) {
      return value.first as Map<String, dynamic>;
    }
    return null;
  }

  int _compareHistory(
    TradeHistoryDto a,
    TradeHistoryDto b, {
    required DateTime nowUtc,
  }) {
    final endA = a.endAt?.toUtc();
    final endB = b.endAt?.toUtc();
    final aEnded = endA != null && endA.isBefore(nowUtc);
    final bEnded = endB != null && endB.isBefore(nowUtc);

    // 진행 중 > 종료 여부는 유지, 진행 중은 endAt 오름차순, 종료는 endAt 내림차순
    if (!aEnded && bEnded) return -1;
    if (aEnded && !bEnded) return 1;

    // 둘 다 진행 중
    if (!aEnded && !bEnded) {
      final va =
          endA?.millisecondsSinceEpoch ??
          DateTime.now()
              .add(const Duration(days: 365 * 100))
              .millisecondsSinceEpoch;
      final vb =
          endB?.millisecondsSinceEpoch ??
          DateTime.now()
              .add(const Duration(days: 365 * 100))
              .millisecondsSinceEpoch;
      return va.compareTo(vb); // 가까운 종료일 먼저
    }

    // 둘 다 종료
    final va = endA?.millisecondsSinceEpoch ?? 0;
    final vb = endB?.millisecondsSinceEpoch ?? 0;
    return vb.compareTo(va); // 최근 종료 먼저
  }
}
