import 'package:intl/intl.dart';

/// 가격 포맷터: 10000 -> 10,000원
String formatPrice(int value, {String suffix = '원'}) {
  final formatter = NumberFormat('#,###');
  final formatted = formatter.format(value);
  return '$formatted$suffix';
}
