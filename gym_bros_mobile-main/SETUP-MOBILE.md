# Entorno móvil GYM-BROS

Proyecto extraído de Downloads/gym_bros_mobile-main.zip, sin crear una app nueva.

## Herramientas
- Flutter stable 3.47.2: C:\Users\pimpi\develop\flutter
- Dart 3.13.2 incluido en Flutter.
- Android SDK: C:\Users\pimpi\AppData\Local\Android\Sdk
- Platform API 36, Build Tools 36.0.0, Platform Tools, Command-line Tools y NDK 28.2.13676358.
- JDK 17: C:\Program Files\Java\jdk-17
- Git y VS Code existentes; extensiones Dart y Flutter 3.142.0 instaladas.
- PATH, JAVA_HOME, ANDROID_HOME y ANDROID_SDK_ROOT configurados a nivel de usuario.
- .vscode/settings.json, .vscode/launch.json y android/local.properties ajustados a este equipo.

## Verificaciones realizadas
- flutter doctor -v: Flutter y Android correctos; falta Visual Studio solo para destino Windows.
- flutter clean: exit 0.
- flutter pub get: exit 0.
- flutter analyze: No issues found, exit 0.
- flutter test: 7 tests passed, exit 0. Aviso SVG: unhandled element <filter/>.
- API y media conservan http://192.168.1.70:8000/api/ y http://192.168.1.70:8000/.
- AndroidManifest contiene INTERNET y usesCleartextTraffic=true.
- curl.exe --noproxy '*' -o NUL -w '%{http_code}' http://192.168.1.70:8000/api/usuarios: 200 desde el PC.
- Backend PHP detectado en C:\laragon\www\gym-bros, escuchando en 192.168.1.70:8000.
- La conexión Wi-Fi de Windows tiene perfil Public. No se ha modificado el firewall.
- adb devices -l: lista vacía. flutter devices: solo Windows, Chrome y Edge.

## Depuración en teléfono
Conectar por USB, activar Opciones de desarrollador y Depuración USB, y aceptar la huella RSA. Mantener Wi-Fi 192.168.1.x y desactivar temporalmente datos móviles/VPN.

En una terminal nueva de VS Code:

```powershell
cd C:\Users\pimpi\Downloads\gym_bros_mobile-main
adb devices -l
flutter devices
flutter run -d <ID_ANDROID>
```

También puede usarse F5 con GYM-BROS (dispositivo Flutter) y el Android seleccionado. Guardar activa Hot Reload; Hot Restart reinicia estado. Detener y ejecutar otra vez tras cambios de dependencias o configuración nativa.

Solo si aparece INSTALL_FAILED_UPDATE_INCOMPATIBLE, desinstalar la app previa (borra sus datos locales) y volver a ejecutar:

```powershell
adb -s <ID_ANDROID> uninstall com.example.gym_bros
```

Para diagnosticar red desde el teléfono:

```powershell
adb -s <ID_ANDROID> shell ip route get 192.168.1.70
adb -s <ID_ANDROID> shell ip -4 addr show wlan0
adb -s <ID_ANDROID> shell toybox nc --help
```

Usar nc según las opciones disponibles para enviar una petición HTTP a 192.168.1.70:8000. Una ruta rmnet_data indica datos móviles. Si TCP falla con ruta Wi-Fi, revisar el listener y firewall del backend; no atribuirlo a caché. Si fuera necesario cambiar el listener Laravel: php artisan serve --host=0.0.0.0 --port=8000. No iniciar otro servidor sobre el puerto ya ocupado.

## Compilación Android
- flutter build apk --debug --no-pub: exit 0; completó en 434,4 segundos.
- APK: build/app/outputs/flutter-apk/app-debug.apk.
- Instalación y conectividad desde Android pendientes: no hay dispositivo ADB conectado.


## Actualización 2026-09-09
- API y media cambiadas a http://192.168.1.38:8000/api/ y http://192.168.1.38:8000/.
- /api/usuarios: HTTP 200 desde PC.
- flutter analyze: sin incidencias; flutter test: 7 aprobados.
- APK debug recompilado correctamente.
- Android AC3N6R5401002425 (BRP_NX3) apareció autorizado y luego se desconectó. flutter run no pudo encontrarlo; ejecución y prueba LAN desde Android pendientes.


## Ejecución confirmada en Android
- Dispositivo AC3N6R5401002425 / BRP_NX3 autorizado.
- Ruta API: dev wlan0 src 192.168.1.39 hacia 192.168.1.38.
- GET /api/usuarios desde ADB: HTTP/1.1 200 OK.
- flutter run --debug: instalación y conexión Dart VM correctas.
- Flutter resolvió INSTALL_FAILED_UPDATE_INCOMPATIBLE desinstalando únicamente com.example.gym_bros y reinstalando.


## Rutina asignada: sesiones reales
- Banner y VER DETALLE abren RoutineSessionScreen.
- GET usuarios/{usuario}/rutinas/{rutina}/sesiones/{dia}, IDs dinámicos y selector de días.
- Ejercicios ordenados, parámetros, instrucciones, notas y grupo muscular; carga/error/reintento y respuesta vacía.
- flutter analyze: sin incidencias; flutter test: 11 aprobados.
- Compilado, instalado y verificado en BRP_NX3: Press banca y Remo con polea visibles con datos reales.
- Imágenes de ejemplo no disponibles; enlaces de video devueltos por la API usan videos.test.


## Videos de ejercicios
- Botón Ver ejercicio abre popup de YouTube mediante youtube_player_iframe 6.0.2.
- enlace_video acepta URL completa watch, youtu.be, shorts, live y embed.
- Reproductor se crea al abrir el popup y se libera al cerrar; pausa al pasar la app a segundo plano.
- Análisis sin incidencias; 13 pruebas aprobadas; compilado e instalado en BRP_NX3.
- Popup de enlace inválido verificado en teléfono. Reproducción real pendiente: API aún devuelve videos.test para ambos ejercicios.

