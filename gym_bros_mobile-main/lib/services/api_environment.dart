import 'package:flutter/foundation.dart';

/// Dirección de la API por entorno.
///
/// - `--dart-define=API_BASE_URL=https://api.ejemplo.com` manda siempre.
/// - En desarrollo, sin definirla: el emulador de Android llega al equipo
///   anfitrión por `10.0.2.2`; escritorio y web usan `localhost`. Un teléfono
///   físico necesita la IP LAN del equipo:
///   `flutter run --dart-define=API_BASE_URL=http://<ip-del-equipo>:8000`.
/// - Fuera de desarrollo se exige HTTPS.
///
/// Antes había una IP LAN fija (192.168.1.38) que dejaba de existir al
/// cambiar de red.
class ApiEnvironment {
  static const name = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const configuredUrl = String.fromEnvironment('API_BASE_URL');
  static bool get development => kDebugMode && name == 'development';

  static String get _developmentDefault =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://localhost:8000';

  static Uri get server {
    final raw = configuredUrl.isNotEmpty
        ? configuredUrl
        : development
        ? _developmentDefault
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
