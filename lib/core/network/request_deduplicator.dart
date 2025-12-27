import 'dart:async';
import 'dart:collection';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// In-Flight Request Deduplication Layer
/// 
/// 동일한 요청이 동시에 여러 번 발생하는 것을 방지합니다.
/// 진행 중인 요청은 Future를 캐시에 저장하고, 동일 요청 발생 시 기존 Future를 반환합니다.
class RequestDeduplicator {
  static final RequestDeduplicator _instance = RequestDeduplicator._internal();
  factory RequestDeduplicator() => _instance;
  RequestDeduplicator._internal();

  final Map<String, Future<dynamic>> _inFlightRequests = HashMap();

  /// 요청 signature 생성
  /// method + path + sorted params를 조합하여 고유 키 생성
  String _generateSignature({
    required String method,
    required String path,
    Map<String, dynamic>? params,
  }) {
    final buffer = StringBuffer();
    buffer.write(method.toUpperCase());
    buffer.write('::');
    buffer.write(path);

    if (params != null && params.isNotEmpty) {
      // 파라미터를 정렬하여 일관된 signature 생성
      final sortedKeys = params.keys.toList()..sort();
      buffer.write('?');
      for (var i = 0; i < sortedKeys.length; i++) {
        final key = sortedKeys[i];
        buffer.write('$key=${params[key]}');
        if (i < sortedKeys.length - 1) {
          buffer.write('&');
        }
      }
    }

    // SHA256 해시로 변환 (긴 URL 대응)
    final bytes = utf8.encode(buffer.toString());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 중복 제거된 요청 실행
  /// 
  /// 동일한 signature의 요청이 진행 중이면 기존 Future 반환
  /// 새로운 요청이면 실행 후 완료 시 캐시에서 제거
  Future<T> execute<T>({
    required String method,
    required String path,
    Map<String, dynamic>? params,
    required Future<T> Function() request,
  }) async {
    final signature = _generateSignature(
      method: method,
      path: path,
      params: params,
    );

    // 진행 중인 요청이 있으면 기존 Future 반환
    if (_inFlightRequests.containsKey(signature)) {
      print('[RequestDeduplicator] Deduplicating request: $method $path');
      return _inFlightRequests[signature] as Future<T>;
    }

    // 새로운 요청 실행
    print('[RequestDeduplicator] New request: $method $path');
    final future = request();

    // 캐시에 저장
    _inFlightRequests[signature] = future;

    // 완료 시 캐시에서 제거
    future.whenComplete(() {
      _inFlightRequests.remove(signature);
      print('[RequestDeduplicator] Request completed: $method $path');
    });

    return future;
  }

  /// 특정 signature의 진행 중인 요청 취소 (선택적)
  void cancel(String signature) {
    _inFlightRequests.remove(signature);
  }

  /// 모든 진행 중인 요청 제거 (앱 종료 시 등)
  void clear() {
    _inFlightRequests.clear();
    print('[RequestDeduplicator] All in-flight requests cleared');
  }

  /// 현재 진행 중인 요청 수
  int get inFlightCount => _inFlightRequests.length;
}
