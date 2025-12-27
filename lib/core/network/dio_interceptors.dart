import 'package:dio/dio.dart';
import 'dart:math' as math;

/// Dio Interceptor for Retry with Exponential Backoff
/// 
/// 네트워크 오류 시 지수 백오프로 재시도
/// - 4xx 오류: 재시도 안 함 (클라이언트 오류)
/// - 5xx 오류: 재시도 (서버 오류)
/// - 네트워크 오류: 재시도
class RetryInterceptor extends Interceptor {
  final int maxRetries;
  final Duration initialDelay;
  final Dio dio;

  RetryInterceptor({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    required this.dio,
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] ?? 0;

    // 재시도 가능 여부 확인
    if (!_shouldRetry(err) || retryCount >= maxRetries) {
      print('[RetryInterceptor] Not retrying: ${err.message}');
      return handler.next(err);
    }

    // 지수 백오프 계산 (jitter 포함)
    final delaySeconds = _calculateDelay(retryCount);
    print('[RetryInterceptor] Retry ${retryCount + 1}/$maxRetries after ${delaySeconds}s');

    await Future.delayed(Duration(seconds: delaySeconds));

    // 재시도
    try {
      final options = err.requestOptions;
      options.extra['retryCount'] = retryCount + 1;

      final response = await dio.fetch(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  /// 재시도 가능 여부 판단
  bool _shouldRetry(DioException err) {
    // 네트워크 오류는 재시도
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }

    // HTTP 상태 코드 확인
    final statusCode = err.response?.statusCode;
    if (statusCode == null) return true; // 응답 없음 = 네트워크 오류

    // 5xx 오류만 재시도 (서버 오류)
    // 4xx 오류는 재시도 안 함 (클라이언트 오류)
    return statusCode >= 500 && statusCode < 600;
  }

  /// 지수 백오프 + Jitter 계산
  int _calculateDelay(int retryCount) {
    // 2^retryCount * initialDelay
    final exponentialDelay = math.pow(2, retryCount) * initialDelay.inSeconds;

    // Jitter: ±20% 랜덤 변동
    final jitter = (math.Random().nextDouble() * 0.4 - 0.2) * exponentialDelay;

    return (exponentialDelay + jitter).toInt();
  }
}

/// Dio Interceptor for Logging (디버그용)
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('[Request] ${options.method} ${options.uri}');
    print('[Request] Headers: ${options.headers}');
    if (options.data != null) {
      print('[Request] Body: ${options.data}');
    }
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('[Response] ${response.statusCode} ${response.requestOptions.uri}');
    print('[Response] Data: ${response.data}');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('[Error] ${err.requestOptions.method} ${err.requestOptions.uri}');
    print('[Error] ${err.message}');
    if (err.response != null) {
      print('[Error] Status: ${err.response?.statusCode}');
      print('[Error] Data: ${err.response?.data}');
    }
    super.onError(err, handler);
  }
}
