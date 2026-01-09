import 'package:bidbird/core/widgets/unified_empty_state.dart';
import 'package:flutter/material.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';
import 'package:bidbird/core/utils/ui_set/responsive_constants.dart';
import 'package:bidbird/features/item_detail/detail/domain/entities/item_detail_entity.dart';
import 'package:bidbird/features/item_detail/detail/data/datasources/item_detail_datasource.dart';
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: UnifiedEmptyState(
        title: '등록된 보증서가 없습니다',
        subtitle: '판매자가 보증서를 업로드하지 않았습니다',
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
      onTap: () async {
        if (document.fileType.toLowerCase() == 'pdf') {
          // Supabase에서 최신 URL 조회
          try {
            final datasource = ItemDetailDatasource();
            final latestUrl = await datasource.fetchDocumentUrl(
              item.itemId,
              document.documentId,
            );
            
            final urlToUse = latestUrl ?? document.documentUrl;
            
            if (!context.mounted) return;
            
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PDFViewerScreen(
                  title: document.documentName,
                  url: urlToUse,
                ),
                fullscreenDialog: true,
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF를 불러오는데 실패했습니다.')),
            );
          }
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
