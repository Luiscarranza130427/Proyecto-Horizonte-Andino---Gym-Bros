import 'package:flutter/foundation.dart';

class ApiEnvironment {
  static const name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const configuredUrl = String.fromEnvironment('API_BASE_URL');
  static bool get development => kDebugMode && name == 'development';
  static Uri get server {
    final raw = configuredUrl.isNotEmpty
        ? configuredUrl
        : development
        ? 'http://192.168.1.38:8000'
        : '';
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !uri.hasAuthority ||
        !['http', 'https'].contains(uri.scheme) ||
        (!development && uri.scheme != 'https')) {
      throw StateError('Configura API_BASE_URL con HTTPS para este entorno.');
    }
    return Uri.parse(raw.endsWith('/') ? raw : '$raw/');
  }
}

