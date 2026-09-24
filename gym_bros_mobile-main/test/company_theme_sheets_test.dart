import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/screens/app_shell.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _acentoEmpresa = Color(0xFF00AEEF);

const _evaluacion = {
  'id': 3,
  'id_usuarios': 1,
  'fecha_evaluacion': '2026-09-10',
  'peso': 74.5,
  'altura': 165,
  'edad': 28,
  'porcentaje_grasa': 15,
  'masa_muscular': 45,
  'cintura': 80,
  'pecho': 110,
  'brazo': 38,
  'muslo': 50,
  'cadera': 90,
};

GymApi _api() => GymApi(
  client: MockClient((request) async {
    final ruta = request.url.path;
    Object? data = <Object>[];
    if (ruta == '/api/auth/me') {
      data = {
        'id': 1,
        'nombres': 'Juan',
        'apellidos': 'Perez',
        'correo': 'juan@gymbros.test',
        'tipo_usuario': 'Usuario',
        'estado': 1,
        'id_empresas': 1,
      };
    } else if (ruta == '/api/empresas/1') {
      data = {
        'id': 1,
        'nombre': 'Titan Gym',
        'estado': 1,
        'color_1': '#111111',
        'color_2': '#00AEEF',
      };
    } else if (ruta.endsWith('/evaluaciones/perfil')) {
      data = {
        'id_usuarios': 1,
        'id_evaluacion': 3,
        'fecha_evaluacion': '2026-09-10',
      };
    } else if (ruta.endsWith('/evaluaciones/peso-grasa')) {
      return http.Response('{"message":"Sin datos"}', 404);
    } else if (ruta == '/api/evaluacionesfisicas') {
      data = [_evaluacion];
    }
    return http.Response(jsonEncode({'data': data}), 200);
  }),
);

Color? _fondoBoton(WidgetTester tester, Key clave) {
  final boton = tester.widget<FilledButton>(
    find.descendant(of: find.byKey(clave), matching: find.byType(FilledButton)),
  );
  return boton.style?.backgroundColor?.resolve(<WidgetState>{});
}

/// Fuentes reales de la app: con la fuente de relleno de las pruebas (más
/// ancha) aparecerían desbordes que en el teléfono no existen.
Future<void> _cargarFuentes() async {
  for (final (familia, ruta) in [
    ('Inter', 'assets/fonts/Inter-Variable.ttf'),
    ('Montserrat', 'assets/fonts/Montserrat-Variable.ttf'),
  ]) {
    final bytes = File(ruta).readAsBytesSync();
    await (FontLoader(
      familia,
    )..addFont(Future.value(ByteData.view(bytes.buffer)))).load();
  }
}

void main() {
  setUpAll(_cargarFuentes);

  testWidgets(
    'la hoja de editar medidas usa el color de la empresa, no el rojo por defecto',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final api = _api();
      final session = await tester.runAsync(
        () => api.fetchUserData('juan@gymbros.test'),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: AppShell(session: session!, gymApi: api),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('PROGRESO'));
      await tester.pumpAndSettle();

      final editar = find.byKey(const ValueKey('progress-edit-bottom'));
      await tester.ensureVisible(editar);
      await tester.tap(editar);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();

      final guardar = find.byKey(const ValueKey('save-measurements'));
      expect(guardar, findsOneWidget);
      expect(find.text('GUARDAR CAMBIOS'), findsOneWidget);
      expect(
        _fondoBoton(tester, const ValueKey('save-measurements')),
        _acentoEmpresa,
      );
    },
  );
}
