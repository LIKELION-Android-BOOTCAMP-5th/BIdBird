import 'package:bidbird/core/utils/item/item_registration_constants.dart';
import 'package:bidbird/core/utils/item/item_registration_error_messages.dart';

/// 아이템 등록 검증 결과
class ItemRegistrationValidationResult {
  final bool isValid;
  final String? errorMessage;

  ItemRegistrationValidationResult({
    required this.isValid,
    this.errorMessage,
  });

  factory ItemRegistrationValidationResult.success() {
    return ItemRegistrationValidationResult(isValid: true);
  }

  factory ItemRegistrationValidationResult.failure(String message) {
    return ItemRegistrationValidationResult(
      isValid: false,
      errorMessage: message,
    );
  }
}

/// 아이템 등록 관련 검증 유틸리티
class ItemRegistrationValidator {
  /// 제목 검증
  static ItemRegistrationValidationResult? validateTitle(String title) {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.titleRequired,
      );
    }
    if (trimmedTitle.length > ItemTextLimits.maxTitleLength) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.titleMaxLength(ItemTextLimits.maxTitleLength),
      );
    }
    return null;
  }

  /// 설명 검증
  static ItemRegistrationValidationResult? validateDescription(String description) {
    final trimmedDescription = description.trim();
    if (trimmedDescription.isEmpty) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.descriptionRequired,
      );
    }
    if (trimmedDescription.length > ItemTextLimits.maxDescriptionLength) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.descriptionMaxLength(
          ItemTextLimits.maxDescriptionLength,
        ),
      );
    }
    return null;
  }

  /// 카테고리 검증
  static ItemRegistrationValidationResult? validateCategory(int? keywordTypeId) {
    if (keywordTypeId == null || keywordTypeId <= 0) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.categoryRequired,
      );
    }
    return null;
  }

  /// 시작가 검증
  static ItemRegistrationValidationResult? validateStartPrice(int? startPrice) {
    if (startPrice == null) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.startPriceInvalidNumber,
      );
    }
    if (startPrice < ItemPriceLimits.minPrice || startPrice > ItemPriceLimits.maxPrice) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.startPriceRange(
          ItemPriceLimits.minPrice,
          ItemPriceLimits.maxPrice,
        ),
      );
    }
    return null;
  }

  /// 즉시 입찰가 검증
  static ItemRegistrationValidationResult? validateInstantPrice(
    int? instantPrice,
    int startPrice,
    bool isRequired,
  ) {
    if (isRequired && instantPrice == null) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.instantPriceInvalidNumber,
      );
    }

    if (instantPrice != null && instantPrice > 0) {
      if (instantPrice < ItemPriceLimits.minPrice || instantPrice > ItemPriceLimits.maxPrice) {
        return ItemRegistrationValidationResult.failure(
          ItemRegistrationErrorMessages.instantPriceRange(
            ItemPriceLimits.minPrice,
            ItemPriceLimits.maxPrice,
          ),
        );
      }
      if (instantPrice <= startPrice) {
        return ItemRegistrationValidationResult.failure(
          ItemRegistrationErrorMessages.instantPriceMustBeHigher,
        );
      }
    }
    return null;
  }

  /// 이미지 검증
  static ItemRegistrationValidationResult? validateImages(List<dynamic> images) {
    if (images.isEmpty) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.imageMinRequired,
      );
    }
    if (images.length > ItemImageLimits.maxImageCount) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.imageMaxCount(ItemImageLimits.maxImageCount),
      );
    }
    return null;
  }

  /// 경매 기간 검증
  static ItemRegistrationValidationResult? validateAuctionDuration(int auctionDurationHours) {
    if (auctionDurationHours <= 0) {
      return ItemRegistrationValidationResult.failure(
        ItemRegistrationErrorMessages.auctionDurationRequired,
      );
    }
    return null;
  }

  /// 전체 검증 (UI용 - String? 반환)
  static String? validateForUI({
    required String title,
    required String description,
    required int? keywordTypeId,
    required int? startPrice,
    int? instantPrice,
    required bool useInstantPrice,
    required List<dynamic> images,
  }) {
    final titleResult = validateTitle(title);
    if (titleResult != null) return titleResult.errorMessage;

    final descriptionResult = validateDescription(description);
    if (descriptionResult != null) return descriptionResult.errorMessage;

    final categoryResult = validateCategory(keywordTypeId);
    if (categoryResult != null) return categoryResult.errorMessage;

    final startPriceResult = validateStartPrice(startPrice);
    if (startPriceResult != null) return startPriceResult.errorMessage;

    if (useInstantPrice) {
      final instantPriceResult = validateInstantPrice(
        instantPrice,
        startPrice ?? 0,
        true,
      );
      if (instantPriceResult != null) return instantPriceResult.errorMessage;
    }

    final imagesResult = validateImages(images);
    if (imagesResult != null) return imagesResult.errorMessage;

    return null;
  }

  /// 전체 검증 (서버용 - Exception throw)
  static void validateForServer({
    required String title,
    required String description,
    required int keywordTypeId,
    required int startPrice,
    int instantPrice = 0,
    required List<String> imageUrls,
    required int auctionDurationHours,
  }) {
    // 이미지 검증
    if (imageUrls.isEmpty) {
      throw Exception(ItemRegistrationErrorMessages.imageMinRequiredForException);
    }
    if (imageUrls.length > ItemImageLimits.maxImageCount) {
      throw Exception(ItemRegistrationErrorMessages.imageMaxCount(ItemImageLimits.maxImageCount));
    }

    // 제목 검증
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      throw Exception(ItemRegistrationErrorMessages.titleRequired);
    }
    if (trimmedTitle.length > ItemTextLimits.maxTitleLength) {
      throw Exception(
        ItemRegistrationErrorMessages.titleMaxLengthForException(ItemTextLimits.maxTitleLength),
      );
    }

    // 설명 검증
    if (description.isNotEmpty && description.length > ItemTextLimits.maxDescriptionLength) {
      throw Exception(
        ItemRegistrationErrorMessages.descriptionMaxLengthForException(
          ItemTextLimits.maxDescriptionLength,
        ),
      );
    }

    // 시작가 검증
    if (startPrice < ItemPriceLimits.minPrice) {
      throw Exception(
        ItemRegistrationErrorMessages.startPriceMinForException(ItemPriceLimits.minPrice),
      );
    }

    // 즉시 입찰가 검증
    if (instantPrice > 0 && instantPrice <= startPrice) {
      throw Exception(ItemRegistrationErrorMessages.instantPriceMustBeHigherForException);
    }

    // 카테고리 검증
    if (keywordTypeId <= 0) {
      throw Exception(ItemRegistrationErrorMessages.categoryRequired);
    }

    // 경매 기간 검증
    if (auctionDurationHours <= 0) {
      throw Exception(ItemRegistrationErrorMessages.auctionDurationRequired);
    }
  }
}

