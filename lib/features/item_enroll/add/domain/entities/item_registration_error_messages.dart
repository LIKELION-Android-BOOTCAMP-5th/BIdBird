import 'package:bidbird/core/utils/item/item_price_utils.dart';

/// 아이템 등록 관련 에러 메시지

/// 일반 에러 메시지
class ItemRegistrationErrorMessages {
  /// 로그인 관련
  static const String loginRequired = '로그인 정보가 없습니다. 다시 로그인 해주세요.';
  static const String loginRequiredShort = '로그인 정보가 없습니다.';

  /// 제목 관련
  static String get titleRequired => '제목을 입력해주세요.';
  static String titleMaxLength(int maxLength) => '제목은 $maxLength자 이하로 입력해주세요.';
  static String titleMaxLengthForException(int maxLength) => '제목은 $maxLength자 이하여야 합니다.';

  /// 카테고리 관련
  static const String categoryRequired = '카테고리를 선택해주세요.';
  static String categoryLoadError(Object error) => '카테고리를 불러오는 중 오류가 발생했습니다: $error';

  /// 가격 관련
  static const String startPriceInvalidNumber = '시작가를 숫자로 입력해주세요.';
  static String startPriceRange(int minPrice, int maxPrice) => 
      '시작가는 ${formatPrice(minPrice)}원 이상 ${formatPrice(maxPrice)}원 이하로 입력해주세요.';
  static String startPriceMinForException(int minPrice) => 
      '시작 가격은 $minPrice원 이상이어야 합니다.';

  static const String instantPriceInvalidNumber = '즉시 입찰가를 숫자로 입력해주세요.';
  // static String instantPriceRange(int minPrice, int maxPrice) => 
  //     '즉시 입찰가는 ${formatPrice(minPrice)}원 이상 ${formatPrice(maxPrice)}원 이하로 입력해주세요.';
  // static String instantPriceMustBeHigher = '즉시 입찰가는 시작가보다 높아야 합니다.';
  // static String instantPriceMustBeHigherForException = '즉시 구매가는 시작 가격보다 커야 합니다.';
  // static String buyNowPriceRange(int minPrice, int maxPrice) => 
  //     '즉시 구매가는 ${formatPrice(minPrice)}원 이상 ${formatPrice(maxPrice)}원 이하만 가능합니다.';

  /// 이미지 관련
  static const String imageMinRequired = '상품 이미지를 최소 1장 이상 선택해주세요.';
  static const String imageMinRequiredForException = '이미지는 최소 1장이 필요합니다.';
  static String imageMaxCount(int maxCount) => 
      '이미지는 최대 $maxCount장까지 등록 가능합니다.';
  static const String imageUploadFailed = '이미지 업로드에 실패했습니다. 다시 시도해주세요.';

  /// 설명 관련
  static const String descriptionRequired = '상품 설명을 입력해주세요.';
  static String descriptionMaxLength(int maxLength) => 
      '상품 설명은 $maxLength자 이하로 입력해주세요.';
  static String descriptionMaxLengthForException(int maxLength) => 
      '본문은 $maxLength자 이하여야 합니다.';

  /// 경매 기간 관련
  static const String auctionDurationRequired = '경매 기간을 설정해주세요.';

  /// 등록/수정 관련
  static String registrationError(Object error) => '등록 중 오류가 발생했습니다: $error';
  static String deletionError(Object error) => '삭제 중 오류가 발생했습니다: $error';
}

/// 입찰 관련 에러 메시지
class BidErrorMessages {
  /// 입찰 제한 관련
  static const String bidRestricted = '결제 3회 이상 실패하여 입찰이 제한되었습니다.';
  static String bidRestrictionCheckFailed(Object error) => 
      '입찰 제한 정보를 확인하지 못했습니다. 잠시 후 다시 시도해주세요.\n$error';
  
  /// 입찰 처리 관련
  static const String bidProcessingFailed = '입찰 처리에 실패했습니다. 다시 시도해주세요.';
  static const String bidProcessingFailedDefault = '입찰 처리에 실패했습니다.';
}

