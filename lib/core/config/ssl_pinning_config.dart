import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class SslPinningConfig {
  static bool get isDevelopmentMode => kDebugMode;

  static const String supabaseDomain = 'mdwelwjletorehxsptqa.supabase.co';

  static const List<String> certificatePins = [
    'PzfKSv758ttsdJwUCkGhW/oxG9Wk1Y4N+NMkB5I7RXc=',
  ];
  static bool validateCertificate(X509Certificate cert, String host) {
    if (isDevelopmentMode) {
      debugPrint('[SSL Pinning] DEV MODE - Bypassing validation for $host');
      return true;
    }

    if (host != supabaseDomain) {
      return true;
    }

    try {
      final certDer = cert.der;
      
      final certHash = sha256.convert(certDer);
      final certHashBase64 = base64.encode(certHash.bytes);
      
      debugPrint('[SSL Pinning] Validating: $host');
      debugPrint('[SSL Pinning] Cert Hash: $certHashBase64');
      
      final isValid = certificatePins.contains(certHashBase64);
      
      if (!isValid) {
        debugPrint('[SSL Pinning] REJECTED - Certificate not in pin list');
        debugPrint('[SSL Pinning] Expected: $certificatePins');
      } else {
        debugPrint('[SSL Pinning] ACCEPTED - Certificate matches pin');
      }
      
      return isValid;
      
    } catch (e) {
      debugPrint('[SSL Pinning] ERROR: $e');
      return false;
    }
  }
}
