import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:bidbird/features/report/presentation/screens/report_screen.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ItemDetailAppBarSection extends StatelessWidget
    implements PreferredSizeWidget {
  const ItemDetailAppBarSection({
    super.key,
    required this.item,
  });

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemDetailViewModel>(
      builder: (context, viewModel, _) {
        final isMyItem = viewModel.isMyItem;
        final sellerProfile = viewModel.sellerProfile;

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 56,
          leading: _buildBackButton(context),
          title: const SizedBox.shrink(),
          centerTitle: false,
          actions: [
            _buildShareButton(context),
            _buildReportButton(context, isMyItem, sellerProfile),
          ],
        );
      },
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.all(context.spacingSmall),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_back,
            color: chatItemCardBackground,
            size: context.iconSizeSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleShare(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.only(right: context.spacingSmall / 2, top: context.spacingSmall, bottom: context.spacingSmall),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.share_outlined,
            color: chatItemCardBackground,
            size: context.iconSizeSmall,
          ),
        ),
      ),
    );
  }

  Widget _buildReportButton(
    BuildContext context,
    bool isMyItem,
    Map<String, dynamic>? sellerProfile,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleReport(context, isMyItem, sellerProfile),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.only(right: context.spacingSmall, top: context.spacingSmall, bottom: context.spacingSmall),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.warning,
            color: chatItemCardBackground,
            size: context.iconSizeSmall,
          ),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final shareText = '${item.itemTitle}\n현재 입찰가: ${item.currentPrice}원';
    try {
      await Share.share(shareText);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('링크가 클립보드에 복사되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleReport(
    BuildContext context,
    bool isMyItem,
    Map<String, dynamic>? sellerProfile,
  ) {
    if (isMyItem) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('본인의 상품은 신고할 수 없습니다'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (item.sellerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('판매자 정보를 불러올 수 없습니다'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReportScreen(
          itemId: item.itemId,
          itemTitle: item.itemTitle,
          targetUserId: item.sellerId,
          targetNickname: sellerProfile?['nick_name'] as String?,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
