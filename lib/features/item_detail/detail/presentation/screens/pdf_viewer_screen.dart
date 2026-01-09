import 'dart:io';
import 'package:bidbird/core/managers/nhost_manager.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:bidbird/core/utils/ui_set/colors_style.dart';

class PDFViewerScreen extends StatefulWidget {
  final String title;
  final String url;

  const PDFViewerScreen({
    super.key,
    required this.title,
    required this.url,
  });

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
      final isNhostUrl = widget.url.contains('nhost.run');
      
      if (isNhostUrl) {
        await _downloadWithAuth();
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

  Future<void> _downloadWithAuth() async {
    try {
      final dio = Dio();
      
      String? accessToken;
      if (NhostManager.shared.isInitialized) {
        accessToken = NhostManager.shared.accessToken;
      }

      final response = await dio.get(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            if (accessToken != null) 'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      // URL 해시와 타임스탬프를 사용하여 고유한 파일명 생성
      final urlHash = widget.url.hashCode.abs().toString();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/pdf_${urlHash}_$timestamp.pdf';
      final file = File(filePath);
      
      await file.writeAsBytes(response.data);

      setState(() {
        _localFile = file;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '파일을 찾을 수 없습니다 (${e.response?.statusCode ?? "알 수 없음"})';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

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
