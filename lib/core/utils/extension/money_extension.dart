import 'package:intl/intl.dart';

extension NumberFormatting on num {
  /// 숫자를 세 자리마다 쉼표를 넣어 String으로 반환합니다.
  /// 예: 10000.toCommaString() -> "10,000"
  String toCommaString() {
    // Core의 계산 방식(price_formatter)과 통일
    final formatter = NumberFormat('#,###');
    return formatter.format(this);
  }
}
