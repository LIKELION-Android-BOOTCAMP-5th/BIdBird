import 'package:bidbird/features/item/user_profile/model/user_profile_entity.dart';

class UserProfileDatasource {
  Future<UserProfile> fetchUserProfile(String userId) async {
    // TODO: 실제 API/Supabase 연동으로 교체
    await Future.delayed(const Duration(milliseconds: 200));
    return dummyUserProfile;
  }

  Future<List<UserTradeSummary>> fetchUserTrades(String userId) async {
    // TODO: 실제 userId 별 거래내역 조회로 교체
    await Future.delayed(const Duration(milliseconds: 200));
    return dummyUserProfile.trades;
  }
}
