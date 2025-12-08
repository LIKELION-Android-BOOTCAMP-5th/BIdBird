import 'package:intl/intl.dart';

extension NumberFormatting on num {
  /// 숫자를 세 자리마다 쉼표를 넣어 String으로 반환합니다.
  /// 예: 10000.toCommaString() -> "10,000"
  String toCommaString() {
    // NumberFormat.decimalPattern()을 사용하여 지역 설정에 맞는
    // 쉼표(,)를 포함한 숫자 형식을 만듭니다.
    final formatter = NumberFormat.decimalPattern();

    // int나 double 모두 num 타입이므로 value를 사용합니다.
    return formatter.format(this);
  }
}
