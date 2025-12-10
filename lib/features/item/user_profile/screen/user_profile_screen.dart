import 'package:bidbird/core/utils/ui_set/border_radius_style.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/features/item/user_profile/model/user_profile_entity.dart';
import 'package:bidbird/features/item/user_profile/viewmodel/user_profile_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserProfileViewModel()..loadProfile(userId),
      builder: (context, _) {
        final vm = context.watch<UserProfileViewModel>();
        final profile = vm.profile;

        return Scaffold(
          appBar: AppBar(title: const Text('프로필'), centerTitle: true),
          backgroundColor: BackgroundColor,
          body: SafeArea(
            child: profile == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: BorderColor.withValues(alpha: 0.3),
                            borderRadius: defaultBorder,
                            boxShadow: const [],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: BorderColor,
                                backgroundImage: profile.avatarUrl.isNotEmpty
                                    ? NetworkImage(profile.avatarUrl)
                                    : null,
                                child: profile.avatarUrl.isNotEmpty
                                    ? null
                                    : Text(
                                        profile.nickname.isNotEmpty
                                            ? profile.nickname[0]
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                profile.nickname,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    '평점 ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textColor,
                                    ),
                                  ),
                                  ..._buildStarIcons(profile.rating),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '  (${profile.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: BorderColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GestureDetector(
                          onTap: () {
                            context.push('/user/${profile.userId}/trade');
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: BorderColor.withValues(alpha: 0.3),
                              borderRadius: defaultBorder,
                              boxShadow: const [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text(
                                  '거래내역',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: BorderColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: _UserReviewSection(reviews: profile.reviews),
                        ),
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}

List<Widget> _buildStarIcons(double rating, {double size = 16}) {
  final int fullStars = rating.floor();
  final bool hasHalfStar = (rating - fullStars) >= 0.5;

  return List.generate(5, (index) {
    IconData icon;
    if (index < fullStars) {
      icon = Icons.star;
    } else if (index == fullStars && hasHalfStar) {
      icon = Icons.star_half;
    } else {
      icon = Icons.star_border;
    }

    return Icon(
      icon,
      size: size,
      color: icon == Icons.star || icon == Icons.star_half
          ? yellowColor
          : BorderColor,
    );
  });
}

class _UserReviewSection extends StatelessWidget {
  const _UserReviewSection({required this.reviews});

  final List<UserReview> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '거래 평',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BorderColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(defaultRadius),
            boxShadow: const [],
          ),
          child: reviews.isEmpty
              ? const Text(
                  '아직 받은 거래 평이 없습니다.',
                  style: TextStyle(fontSize: 13, color: textColor),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (review.fromUserId.isNotEmpty) ...[
                              Flexible(
                                child: Text(
                                  review.fromUserNickname.isNotEmpty
                                      ? review.fromUserNickname
                                      : '알 수 없는 사용자',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            ..._buildStarIcons(review.rating),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          review.comment.isNotEmpty
                              ? review.comment
                              : '내용 없는 리뷰입니다.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
