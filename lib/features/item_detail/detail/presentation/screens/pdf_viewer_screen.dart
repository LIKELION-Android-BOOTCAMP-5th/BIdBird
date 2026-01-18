import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

class PDFViewerScreen extends StatefulWidget {
  final String title;
  final String url;

  const PDFViewerScreen({
    super.key,
    required this.title,
    required this.url,
    this.filePath,
  });

  final String? filePath;

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  File? _localFile;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      // 로컬 파일 경로가 있으면 바로 로드
      if (widget.filePath != null && widget.filePath!.isNotEmpty) {
        final file = File(widget.filePath!);
        if (await file.exists()) {
          setState(() {
            _localFile = file;
            _isLoading = false;
          });
          return;
        }
      }

      final isSupabaseUrl = widget.url.contains('supabase.co');
      
      if (isSupabaseUrl) {
        // Supabase public URLs can be loaded directly, but if they are private, 
        // they might need auth. For now, we assume network loading works or handle it simply.
        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Removed _downloadWithAuth since we are migrating away from Nhost

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: TextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: TextPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                '보증서를 불러오는데 실패했습니다',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_localFile != null) {
      return SfPdfViewer.file(
        _localFile!,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('보증서를 불러오는데 실패했습니다: ${details.description}')),
          );
        },
      );
    } else {
      return SfPdfViewer.network(
        widget.url,
        onDocumentLoadFailed: (details) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('보증서를 불러오는데 실패했습니다: ${details.description}')),
          );
        },
      );
    }
  }
}
