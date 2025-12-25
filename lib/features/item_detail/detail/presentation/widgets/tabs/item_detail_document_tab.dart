import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/presentation/screens/pdf_viewer_screen.dart';

class ItemDetailDocumentTab extends StatelessWidget {
  const ItemDetailDocumentTab({super.key, required this.item});

  final ItemDetail item;

  @override
  Widget build(BuildContext context) {
    final hasDocuments =
        item.itemDocuments != null && item.itemDocuments!.isNotEmpty;

    if (!hasDocuments) {
      return _buildEmptyState(context);
    }

    return _buildDocumentList(context);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.screenPadding * 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: context.iconSizeMedium * 2,
              color: const Color(0xFF9CA3AF),
            ),
            SizedBox(height: context.spacingMedium),
            Text(
              '등록된 보증서가 없습니다',
              style: TextStyle(
                fontSize: context.fontSizeLarge,
                fontWeight: FontWeight.w600,
                color: TextPrimary,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: context.spacingSmall),
            Text(
              '판매자가 보증서를 업로드하지 않았습니다',
              style: TextStyle(
                fontSize: context.fontSizeMedium,
                color: TextSecondary,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentList(BuildContext context) {
    final documents = item.itemDocuments!;

    return ListView.separated(
      padding: EdgeInsets.all(context.screenPadding),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: documents.length,
      separatorBuilder: (context, index) =>
          SizedBox(height: context.spacingMedium),
      itemBuilder: (context, index) {
        return _buildDocumentItem(context, documents[index]);
      },
    );
  }

  Widget _buildDocumentItem(BuildContext context, ItemDocument document) {
    return InkWell(
      onTap: () {
        if (document.fileType.toLowerCase() == 'pdf') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PDFViewerScreen(
                title: document.documentName,
                url: document.documentUrl,
              ),
              fullscreenDialog: true,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 PDF 형식만 미리보기가 가능합니다.')),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(context.inputPadding * 1.2),
        decoration: BoxDecoration(
          color: BackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BorderColor, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: blueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _getFileIcon(document.fileType),
                color: blueColor,
                size: context.iconSizeSmall * 1.2,
              ),
            ),
            SizedBox(width: context.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.documentName,
                    style: TextStyle(
                      fontSize: context.fontSizeMedium,
                      fontWeight: FontWeight.w600,
                      color: TextPrimary,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${document.fileType.toUpperCase()} • ${document.fileSizeFormatted}',
                    style: TextStyle(
                      fontSize: context.fontSizeSmall,
                      color: TextSecondary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: blueColor, size: context.iconSizeSmall),
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }
}
