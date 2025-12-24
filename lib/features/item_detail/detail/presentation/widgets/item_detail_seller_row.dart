import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_list_row.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';

class ItemDetailSellerRow extends StatelessWidget {
  const ItemDetailSellerRow({required this.item, super.key});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Selector<ItemDetailViewModel, String?>(
      selector: (_, vm) => vm.sellerProfileImage,
      builder: (context, sellerProfileImage, _) {
        final String avatarUrl = sellerProfileImage ?? '';
        final String sellerNickname = item.sellerTitle.isNotEmpty
            ? item.sellerTitle
            : '닉네임 없음';
        final double sellerRating = item.sellerRating;

        final horizontalPadding = context.screenPadding;
        final spacingSmall = context.spacingSmall;
        final isCompact = context.isSmallScreen(threshold: 360);
        final translateY = isCompact ? -8.0 : -13.0;
        final avatarRadius = context.widthRatio(0.055, min: 18.0, max: 24.0);

        return Transform.translate(
          offset: Offset(0, translateY),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              spacingSmall * 0.4,
              horizontalPadding,
              spacingSmall,
            ),
            child: ItemDetailListRow(
              icon: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: const Color(0xFFF2F4F6),
                backgroundImage: avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl.isEmpty
                    ? Icon(
                        Icons.person,
                        color: const Color(0xFF9CA3AF),
                        size: context.iconSizeSmall,
                      )
                    : null,
              ),
              title: sellerNickname,
              subtitle: '평점 ${sellerRating.toStringAsFixed(1)}',
              onTap: () {
                if (item.sellerId.isEmpty) return;
                context.push('/user/${item.sellerId}');
              },
            ),
          ),
        );
      },
    );
  }
}
