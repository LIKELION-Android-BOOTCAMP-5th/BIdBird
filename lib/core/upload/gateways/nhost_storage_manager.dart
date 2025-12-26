import 'dart:io';
import 'package:bidbird/core/managers/nhost_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

class NhostStorageManager {
  static final NhostStorageManager _shared = NhostStorageManager();
  static NhostStorageManager get shared => _shared;

  final _nhost = NhostManager.shared;

  Future<String?> uploadFile(File file, {String bucketId = 'default'}) async {
    try {
      final fileName = file.path.split('/').last;
      final mimeType = _getMimeType(fileName);
      
      // Enforce PDF-only policy as per user request
      if (mimeType != 'application/pdf') {
        debugPrint('⚠️ Nhost Storage Policy: Only PDF files are allowed. Blocked: $fileName ($mimeType)');
        throw Exception('Nhost Storage only accepts PDF files.');
      }

      // Ensure Nhost is initialized before proceeding
      if (!_nhost.isInitialized) {
        debugPrint('🟡 Nhost not initialized. Initializing for storage upload...');
        await _nhost.initialize();
      }
      
      final bytes = await file.readAsBytes();
      
      debugPrint('🔵 Starting file upload: $fileName (${bytes.length} bytes)');
      
      // Use FileData constructor with bytes for Nhost SDK 2.2.0
      final fileData = FileData(
        bytes,
        filename: fileName,
        contentType: mimeType,
      );
      
      final fileMetadataList = await _nhost.nhostClient.storage.uploadFiles(
        files: [fileData],
        bucketId: bucketId,
      );

      if (fileMetadataList.isEmpty) {
        debugPrint('❌ Upload failed: no metadata returned');
        throw Exception('File upload failed: no metadata returned');
      }

      final fileMetadata = fileMetadataList.first;
      final fileId = fileMetadata.id;
      
      // Construct public URL - standard Nhost pattern
      final subdomain = _nhost.nhostClient.subdomain!.subdomain;
      final region = _nhost.nhostClient.subdomain!.region;
      
      final url = 'https://$subdomain.storage.$region.nhost.run/v1/files/$fileId';
      debugPrint('✅ Upload successful: $url');
      
      return url;
    } catch (e, stackTrace) {
      debugPrint('❌ Nhost Storage Upload Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<String>> uploadFileList(List<File> files, {String bucketId = 'default'}) async {
    debugPrint('🔵 Uploading ${files.length} files...');
    List<String> urls = [];
    for (var file in files) {
      final url = await uploadFile(file, bucketId: bucketId);
      if (url != null) {
        urls.add(url);
      }
    }
    debugPrint('✅ Uploaded ${urls.length}/${files.length} files successfully');
    return urls;
  }

  String _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }
}
