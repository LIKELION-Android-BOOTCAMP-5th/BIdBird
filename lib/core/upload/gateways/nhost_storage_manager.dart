import 'dart:io';
import 'package:bidbird/core/managers/nhost_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:nhost_storage_dart/nhost_storage_dart.dart';

class NhostStorageManager {
  static final NhostStorageManager _shared = NhostStorageManager();
  static NhostStorageManager get shared => _shared;

  final _nhost = NhostManager.shared;

  Future<Map<String, String>?> uploadFile(File file, {String? originalName, String bucketId = 'default'}) async {
    try {
      final fileName = originalName ?? file.path.split('/').last;
      final mimeType = _getMimeType(fileName);
      
      // Enforce PDF-only policy as per user request
      // Be lenient: Allow if extension is .pdf OR if it came from our trusted picker
      final bool hasPdfExtension = fileName.toLowerCase().endsWith('.pdf');
      final isAllowed = mimeType == 'application/pdf' || 
                        (mimeType == 'application/octet-stream' && hasPdfExtension) ||
                        (originalName != null && hasPdfExtension);

      if (!isAllowed && !hasPdfExtension) {
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
      
      return {
        'url': url,
        'name': fileName,
        'size': bytes.length.toString(),
      };
    } catch (e, stackTrace) {
      debugPrint('❌ Nhost Storage Upload Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<Map<String, String>>> uploadFileList(
    List<File> files, {
    List<String>? originalNames,
    String bucketId = 'default',
  }) async {
    debugPrint('🔵 Uploading ${files.length} files...');
    List<Map<String, String>> result = [];
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
