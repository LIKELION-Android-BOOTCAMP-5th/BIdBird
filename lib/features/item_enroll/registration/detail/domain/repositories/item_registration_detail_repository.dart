abstract class ItemRegistrationDetailRepository {
  Future<String> fetchTermsText();
  Future<void> confirmRegistration(String itemId);
  Future<void> deleteItem(String itemId);
  Future<String?> fetchFirstImageUrl(String itemId);
}



