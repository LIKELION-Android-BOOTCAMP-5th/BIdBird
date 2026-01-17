import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageManager {
  static final SupabaseStorageManager _shared = SupabaseStorageManager();
  static SupabaseStorageManager get shared => _shared;

  final _supabase = Supabase.instance.client;

  /// Supabase Storage에 파일 업로드
  /// [bucketId]: 업로드할 버킷 이름 (기본값: 'item_documents')
  Future<Map<String, dynamic>?> uploadFile(File file, {String? originalName, String bucketId = 'item_documents'}) async {
    try {
      final fileName = originalName ?? file.path.split('/').last;
      
      // 파일 확장자 추출
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      debugPrint('🔵 Starting Supabase file upload: $uniqueFileName to $bucketId');
      
      final bytes = await file.readAsBytes();
      
      // Supabase Storage 업로드
      await _supabase.storage.from(bucketId).uploadBinary(
            uniqueFileName,
            bytes,
            fileOptions: FileOptions(
              contentType: _getMimeType(fileName),
              upsert: true,
            ),
          );

      // 공개 URL 생성
      final String url = _supabase.storage.from(bucketId).getPublicUrl(uniqueFileName);
      
      debugPrint('✅ Upload successful: $url');
      
      return {
        'url': url,
        'name': fileName,
        'size': bytes.length, // int로 반환
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Supabase Storage Upload Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// 보증서 전용 업로드 함수 (URL, 이름, 크기를 분리된 리스트로 반환)
  Future<(List<String> urls, List<String> names, List<int> sizes)> uploadDocuments(
    List<File> files, {
    List<String>? originalNames,
    List<int>? existingSizes,
    String bucketId = 'item_documents',
  }) async {
    List<String> urls = [];
    List<String> names = [];
    List<int> sizes = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final path = file.path;
      final isRemote = path.startsWith('http');

      if (isRemote) {
        urls.add(path);
        names.add(
          (originalNames != null && originalNames.length > i)
              ? originalNames[i]
              : path.split('/').last,
        );
        sizes.add(
          (existingSizes != null && existingSizes.length > i)
              ? existingSizes[i]
              : 0,
        );
      } else {
        final originalName = (originalNames != null && originalNames.length > i)
            ? originalNames[i]
            : null;
        final info = await uploadFile(file, originalName: originalName, bucketId: bucketId);
        if (info != null) {
          urls.add(info['url'] as String);
          names.add(info['name'] as String);
          sizes.add(info['size'] as int);
        }
      }
    }

    return (urls, names, sizes);
  }

  /// 여러 파일 순차적 업로드
  Future<List<Map<String, dynamic>>> uploadFileList(
    List<File> files, {
    List<String>? originalNames,
    String bucketId = 'item_documents',
  }) async {
    debugPrint('🔵 Uploading ${files.length} files to Supabase...');
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final originalName = (originalNames != null && originalNames.length > i)
          ? originalNames[i]
          : null;
      final fileInfo = await uploadFile(file, originalName: originalName, bucketId: bucketId);
      if (fileInfo != null) {
        result.add(fileInfo);
      }
    }
    debugPrint('✅ Uploaded ${result.length}/${files.length} files successfully');
    return result;
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }
}
