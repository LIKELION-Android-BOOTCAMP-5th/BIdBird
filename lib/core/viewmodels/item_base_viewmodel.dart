import 'dart:async';
import 'package:flutter/material.dart';

/// 아이템 관련 ViewModel의 공통 기능을 제공하는 베이스 클래스
/// 
/// - 로딩 상태 관리 (isLoading)
/// - 에러 상태 관리 (error)
/// - 캐싱 기능 (lastFetchTime, cacheValidDuration)
/// - 중복 요청 방지 (executeOnce)
abstract class ItemBaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  DateTime? _lastFetchTime;
  final Map<String, Completer> _pendingOperations = {};

  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastFetchTime => _lastFetchTime;

  /// 로딩 상태 설정
  void setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  /// 에러 상태 설정
  void setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  /// 캐시 무효화
  void invalidateCache() {
    _lastFetchTime = null;
  }

  /// 캐시가 유효한지 확인
  bool isCacheValid(Duration cacheDuration) {
    if (_lastFetchTime == null) return false;
    return DateTime.now().difference(_lastFetchTime!) < cacheDuration;
  }

  /// 캐시 타임스탬프 업데이트
  void updateCacheTime() {
    _lastFetchTime = DateTime.now();
  }

  /// 로딩 시작 (에러 초기화 포함)
  void startLoading() {
    setError(null);
    setLoading(true);
  }

  /// 로딩 종료
  void stopLoading() {
    setLoading(false);
  }

  /// 에러와 함께 로딩 종료
  void stopLoadingWithError(String error) {
    setError(error);
    setLoading(false);
  }

  /// 중복 요청 방지: 같은 키로 동시에 여러 요청이 들어와도 하나만 실행
  /// 
  /// [key] 요청을 구분하는 고유 키
  /// [operation] 실행할 비동기 작업
  /// Returns: 작업 결과
  /// 
  /// 예시:
  /// ```dart
  /// await executeOnce('loadItemDetail', () async {
  ///   return await _repository.fetchItemDetail(itemId);
  /// });
  /// ```
  Future<T> executeOnce<T>(
    String key,
    Future<T> Function() operation,
  ) async {
    // 이미 진행 중인 작업이 있으면 기다림
    if (_pendingOperations.containsKey(key)) {
      return _pendingOperations[key]!.future as Future<T>;
    }
    
    final completer = Completer<T>();
    _pendingOperations[key] = completer;
    
    try {
      final result = await operation();
      completer.complete(result);
      return result;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pendingOperations.remove(key);
    }
  }

  @override
  void dispose() {
    // 진행 중인 작업 정리
    for (final completer in _pendingOperations.values) {
      if (!completer.isCompleted) {
        completer.completeError('ViewModel disposed');
      }
    }
    _pendingOperations.clear();
    super.dispose();
  }
}

