import 'package:flutter/foundation.dart';

enum AppPlatform { web, android, ios, other }

AppPlatform getAppPlatform() {
  if (kIsWeb) return AppPlatform.web;

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return AppPlatform.android;
    case TargetPlatform.iOS:
      return AppPlatform.ios;
    default:
      return AppPlatform.other;
  }
}

bool get isWebPlatform => kIsWeb;
bool get isAndroidPlatform => getAppPlatform() == AppPlatform.android;
bool get isIOSPlatform => getAppPlatform() == AppPlatform.ios;
bool get isMobilePlatform => isAndroidPlatform || isIOSPlatform;
