

/// 가격 포맷터: 10000 -> 10,000원
String formatPrice(int value, {String suffix = '원'}) {
  // 숫자에 3자리마다 콤마 추가
  final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  return '$formatted$suffix';
}
