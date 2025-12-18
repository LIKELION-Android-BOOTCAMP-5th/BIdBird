class ReportTypeEntity {
  final String reportType;
  final String description;

  ReportTypeEntity({
    required this.reportType,
    required this.description,
  });

  factory ReportTypeEntity.fromJson(Map<String, dynamic> json) {
    return ReportTypeEntity(
      reportType: json['report_type'] as String? ?? '',
      description: json['text'] as String? ?? '',
    );
  }

  // 대분류 추출 (예: communication_report_01 -> communication)
  String get category {
    if (reportType.contains('_')) {
      return reportType.split('_')[0];
    }
    return reportType;
  }

  // 대분류 한글명
  String get categoryName {
    switch (category) {
      case 'communication':
        return '소통 관련';
      case 'item':
        return '상품 관련';
      case 'policy':
        return '정책 관련';
      case 'transaction':
        return '거래 관련';
      case 'user':
        return '사용자 관련';
      default:
        return category;
    }
  }
}



