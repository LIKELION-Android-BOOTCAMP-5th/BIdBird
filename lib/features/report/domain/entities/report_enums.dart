/// 신고 관련 대분류/상태 코드 Enum 및 매퍼
enum ReportCategory {
  abuse,
  fraud,
  spam,
  other,
}

String reportCategoryLabel(ReportCategory c) {
  switch (c) {
    case ReportCategory.abuse:
      return '욕설/비하';
    case ReportCategory.fraud:
      return '사기/악성';
    case ReportCategory.spam:
      return '스팸/광고';
    case ReportCategory.other:
      return '기타';
  }
}
