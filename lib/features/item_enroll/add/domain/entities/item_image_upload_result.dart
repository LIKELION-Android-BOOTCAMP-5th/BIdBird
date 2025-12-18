/// 아이템 이미지 업로드 결과
class ItemImageUploadResult {
  ItemImageUploadResult({
    required this.imageUrls,
    required this.thumbnailUrl,
  });

  /// 업로드된 이미지 URL 목록
  final List<String> imageUrls;
  
  /// 업로드된 썸네일 URL
  final String thumbnailUrl;
}

