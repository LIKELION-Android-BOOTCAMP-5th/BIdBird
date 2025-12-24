import 'package:bidbird/features/home/domain/entities/keywordType_entity.dart';

/// 키워드 데이터를 전역적으로 캐시하는 서비스
/// 싱글톤 패턴으로 앱 전체에서 공유되는 캐시
class KeywordCacheService {
  static final KeywordCacheService _instance = KeywordCacheService._internal();
  
  KeywordCacheService._internal();
  
  factory KeywordCacheService() {
    return _instance;
  }
  
  List<KeywordType>? _keywords;
  
  /// 키워드가 캐시되어 있는지 확인
  bool hasKeywords() => _keywords != null && _keywords!.isNotEmpty;
  
  /// 캐시된 키워드 반환
  List<KeywordType>? getKeywords() => _keywords;
  
  /// 키워드 캐시 저장
  void setKeywords(List<KeywordType> keywords) {
    _keywords = keywords;
  }
  
  /// 키워드 캐시 초기화
  void clearKeywords() {
    _keywords = null;
  }
}
