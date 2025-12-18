import 'package:bidbird/features/item_detail/detail/presentation/widgets/item_detail_list_row.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ItemDetailSellerRow extends StatelessWidget {
  const ItemDetailSellerRow({required this.item, super.key});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Selector<ItemDetailViewModel, Map<String, dynamic>?>(
      selector: (_, vm) => vm.sellerProfile,
      builder: (context, sellerProfile, _) {
        final String avatarUrl = (sellerProfile?['profile_image_url'] as String?) ?? '';
        final String rawNickname =
            (sellerProfile?['nick_name'] as String?)?.trim() ?? '';
        final String sellerNickname =
            rawNickname.isNotEmpty ? rawNickname : '닉네임 없음';
        final double sellerRating =
            (sellerProfile?['rating'] as num?)?.toDouble() ?? item.sellerRating;

        return Transform.translate(
          offset: const Offset(0, -13),
          child: Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8, top: 0),
            child: ItemDetailListRow(
            icon: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFFF2F4F6),
              backgroundImage:
                  avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF9CA3AF), size: 20)
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

