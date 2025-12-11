import 'dart:async';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ItemImageCacheManager extends CacheManager {
  static const String key = 'itemImageCache';

  static final ItemImageCacheManager instance = ItemImageCacheManager._internal();

  ItemImageCacheManager._internal()
      : super(
          Config(
            key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 200,
          ),
        );

  @override
  Stream<FileResponse> getFileStream(
    String url, {
    String? key,
    Map<String, String>? headers,
    bool withProgress = false,
  }) {
    return super.getFileStream(
      url,
      key: key,
      headers: headers,
      withProgress: withProgress,
    );
  }
}
