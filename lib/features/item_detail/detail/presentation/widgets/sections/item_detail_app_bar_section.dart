import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/viewmodels/item_detail_viewmodel.dart';
import 'package:bidbird/features/report/presentation/screens/report_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ItemDetailAppBarSection extends StatelessWidget
    implements PreferredSizeWidget {
  const ItemDetailAppBarSection({super.key, required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    return Consumer<ItemDetailViewModel>(
      builder: (context, viewModel, _) {
        final isMyItem = viewModel.isMyItem;
        // sellerProfile은 더 이상 사용되지 않음 - itemDetail에 이미 정보 포함

        return AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 56,
          leading: _buildBackButton(context),
          title: const SizedBox.shrink(),
          centerTitle: false,
          actions: [
            _buildShareButton(context),
            const SizedBox(width: 8),
            if (!isMyItem) ...[
              _buildReportButton(context, isMyItem),
              const SizedBox(width: 8),
            ],
            if (!isMyItem) _buildFavoriteButton(context),
            const SizedBox(width: 16), // Right padding
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

  Widget _buildFavoriteButton(BuildContext context) {
    return Selector<ItemDetailViewModel, bool>(
      selector: (_, vm) => vm.isFavorite,
      builder: (context, isFavorite, _) {
        final viewModel = context.read<ItemDetailViewModel>();

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => viewModel.toggleFavorite(),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: EdgeInsets.zero,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : chatItemCardBackground,
                size: context.iconSizeSmall,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleShare(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.zero,
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

  Widget _buildReportButton(BuildContext context, bool isMyItem) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleReport(context, isMyItem),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          margin: EdgeInsets.zero,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Image.asset(
            'assets/icons/report_icon.png',
            color: chatItemCardBackground,
            height: 20,
            width: 20,
          ),
          // Icon(
          //   Icons.warning,
          //   color: chatItemCardBackground,
          //   size: context.iconSizeSmall,
          // ),
        ),
      ),
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    final String deepLink = 'com.bidbird.app://item/${item.itemId}';
    final String shareText =
        '${item.itemTitle}\n현재 입찰가: ${item.currentPrice}원\n$deepLink';

    // 1. 이미지가 없는 경우 텍스트만 공유
    if (item.itemImages.isEmpty) {
      await _shareTextOnly(context, shareText);
      return;
    }

    // 2. 이미지가 있는 경우 이미지 다운로드 후 공유
    try {
      final String imageUrl = item.itemImages.first;
      final tempDir = await getTemporaryDirectory();
      final String fileName =
          'share_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String filePath = '${tempDir.path}/$fileName';

      await Dio().download(imageUrl, filePath);

      final xFile = XFile(filePath);
      await Share.shareXFiles([xFile], text: shareText);
    } catch (e) {
      // 이미지 다운로드/공유 실패 시 텍스트만 공유 시도
      debugPrint('Image share failed: $e');
      await _shareTextOnly(context, shareText);
    }
  }

  Future<void> _shareTextOnly(BuildContext context, String text) async {
    try {
      await Share.share(text);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
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

  void _handleReport(BuildContext context, bool isMyItem) {
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
          targetNickname: item.sellerTitle,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
