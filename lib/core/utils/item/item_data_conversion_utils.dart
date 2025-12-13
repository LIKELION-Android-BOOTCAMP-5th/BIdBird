/// Map에서 String 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// [defaultValue] 기본값 (기본: 빈 문자열)
/// Returns: String 값
String getStringFromRow(
  Map<String, dynamic> row,
  String key, [
  String defaultValue = '',
]) {
  return row[key]?.toString() ?? defaultValue;
}

/// Map에서 nullable String 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// Returns: String? 값 (null 가능)
String? getNullableStringFromRow(
  Map<String, dynamic> row,
  String key,
) {
  final value = row[key];
  if (value == null) return null;
  final str = value.toString();
  return str.isEmpty ? null : str;
}

/// Map에서 int 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// [defaultValue] 기본값 (기본: 0)
/// Returns: int 값
int getIntFromRow(
  Map<String, dynamic> row,
  String key, [
  int defaultValue = 0,
]) {
  final value = row[key];
  if (value == null) return defaultValue;
  if (value is num) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}

/// Map에서 nullable int 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// Returns: int? 값 (null 가능)
int? getNullableIntFromRow(
  Map<String, dynamic> row,
  String key,
) {
  final value = row[key];
  if (value == null) return null;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

/// Map에서 double 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// [defaultValue] 기본값 (기본: 0.0)
/// Returns: double 값
double getDoubleFromRow(
  Map<String, dynamic> row,
  String key, [
  double defaultValue = 0.0,
]) {
  final value = row[key];
  if (value == null) return defaultValue;
  if (value is num) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}

/// Map에서 nullable double 값을 안전하게 추출
/// [row] 데이터 행
/// [key] 키 이름
/// Returns: double? 값 (null 가능)
double? getNullableDoubleFromRow(
  Map<String, dynamic> row,
  String key,
) {
  final value = row[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

