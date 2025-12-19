import '../entities/tos_entity.dart';

/// ToS 도메인 리포지토리 인터페이스
abstract class ToSRepository {
  Future<List<ToSEntity>> getToSinfo();
  
  Future<void> tosAgreed();
}


