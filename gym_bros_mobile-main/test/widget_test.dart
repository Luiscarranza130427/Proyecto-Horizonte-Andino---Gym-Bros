import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/main.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final weekday = DateTime.now().weekday;
  final initialDay = weekday <= 4 ? weekday : 1;
  testWidgets('el banner asignado abre directamente los ejercicios reales', (
    tester,
  ) async {
    await tester.pumpWidget(GymBrosApp(gymApi: _widgetGymApi()));
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'juan.perez@gmail.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();
    final detail = find.text('VER DETALLE');
    await tester.ensureVisible(detail);
    await tester.tap(detail);
    await tester.pumpAndSettle();
    expect(find.text('DÍA $initialDay · 2 EJERCICIOS'), findsOneWidget);
    expect(find.text('1. Press banca'), findsOneWidget);
    expect(find.byKey(const ValueKey('session-day-4')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inicia con la API y muestra la información real del usuario', (
    tester,
  ) async {
    await tester.pumpWidget(GymBrosApp(gymApi: _widgetGymApi()));

    expect(find.text('USAR DEMO'), findsNothing);
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'juan.perez@gmail.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('HOLA, bro'), findsOneWidget);
    expect(find.text('RUTINA INICIAL'), findsWidgets);
    expect(find.text('TITAN GYM'), findsOneWidget);
    expect(find.text('78.5 KG'), findsOneWidget);
    expect(find.text('18.2 %'), findsOneWidget);
    expect(find.byKey(const ValueKey('linked-company')), findsOneWidget);
    final companyTheme = Theme.of(
      tester.element(find.byKey(const ValueKey('linked-company'))),
    );
    expect(companyTheme.colorScheme.surface, const Color(0xFF2563EB));
    expect(companyTheme.colorScheme.primary, const Color(0xFF111827));

    await tester.ensureVisible(find.byKey(const ValueKey('linked-company')));
    await tester.tap(find.byKey(const ValueKey('linked-company')));
    await tester.pumpAndSettle();
    expect(find.text('Carlos Mendoza'), findsOneWidget);
    expect(find.text('Av. Hoyos Rubio 123'), findsOneWidget);
  });

  testWidgets('muestra null cuando la API no entrega el apodo', (tester) async {
    await tester.pumpWidget(
      GymBrosApp(gymApi: _widgetGymApi(includeNickname: false)),
    );
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'juan.perez@gmail.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();

    expect(find.text('HOLA, null'), findsOneWidget);
  });

  testWidgets('los módulos usan datos reales o informan la ruta faltante', (
    tester,
  ) async {
    await tester.pumpWidget(GymBrosApp(gymApi: _widgetGymApi()));
    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'juan.perez@gmail.com');
    await tester.enterText(fields.at(1), 'password');
    await tester.tap(find.byKey(const ValueKey('login-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('RUTINAS').last);
    await tester.pumpAndSettle();
    expect(find.text('DÍA $initialDay · 2 EJERCICIOS'), findsOneWidget);
    expect(find.text('1. Press banca'), findsOneWidget);

    await tester.tap(find.text('NUTRICIÓN').last);
    await tester.pumpAndSettle();
    expect(find.text('Sin plan disponible'), findsOneWidget);

    await tester.tap(find.text('PROGRESO').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('current-weight')), findsOneWidget);
    expect(find.text('78.5 kg'), findsWidgets);

    await tester.tap(find.text('PERFIL').last);
    await tester.pumpAndSettle();
    expect(find.text('JUAN PEREZ RAMIREZ'), findsOneWidget);
    expect(find.text('MIEMBRO DE ÉLITE'), findsOneWidget);
    expect(find.text('juan.perez@gmail.com'), findsNothing);

    await tester.tap(find.text('DATOS PERSONALES'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-personal-data')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('edit-personal-data'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const ValueKey('training-profile')));
    await tester.tap(find.byKey(const ValueKey('training-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('edit-training-profile')), findsOneWidget);
    expect(find.text('Ganancia muscular'), findsNothing);
    Navigator.of(
      tester.element(find.byKey(const ValueKey('edit-training-profile'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('physical-evaluation')),
    );
    await tester.tap(find.byKey(const ValueKey('physical-evaluation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('register-measurements')), findsOneWidget);
    expect(find.byKey(const ValueKey('edit-measurements')), findsOneWidget);
    expect(
      find.text(
        'La evaluación y el historial corporal se consultan en el módulo Progreso.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el login tolera una altura inicial de cero', (tester) async {
    final originalSize = tester.view.physicalSize;
    final originalRatio = tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.physicalSize = originalSize;
      tester.view.devicePixelRatio = originalRatio;
    });
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 0);

    await tester.pumpWidget(GymBrosApp(gymApi: _widgetGymApi()));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
  });
}

GymApi _widgetGymApi({bool includeNickname = true}) {
  return GymApi(
    mediaBaseUri: Uri.parse('http://192.168.1.56/'),
    client: MockClient((request) async {
      final ruta = request.url.path;
      if (ruta == '/api/auth/login') {
        return http.Response(
          '{"data":{"token":"1|token-de-prueba","token_type":"Bearer"}}',
          200,
        );
      }
      // Todo lo privado exige el token: antes varias peticiones no lo enviaban
      // y solo funcionaban porque la API estaba abierta.
      if (request.headers['Authorization'] != 'Bearer 1|token-de-prueba') {
        return http.Response('{"message":"Sesion no valida o expirada."}', 401);
      }
      if (ruta == '/api/usuarios' || ruta == '/api/empresas') {
        fail('La app no debe descargar listados completos: $ruta');
      }
      if (ruta == '/api/auth/me') {
        final usuarios = jsonDecode(_usuariosJson(includeNickname)) as Map;
        return http.Response(
          jsonEncode({'data': (usuarios['data'] as List).first}),
          200,
        );
      }
      if (ruta == '/api/empresas/1') {
        final empresas = jsonDecode(_empresasJson) as Map;
        return http.Response(
          jsonEncode({'data': (empresas['data'] as List).first}),
          200,
        );
      }
      if (request.url.path.contains('/sesiones/')) {
        final day = int.parse(request.url.pathSegments.last);
        expect(request.url.path, '/api/usuarios/1/rutinas/1/sesiones/$day');
        final body = jsonDecode(
          File('test/fixtures/routine_session.json').readAsStringSync(),
        );
        body['data']['dia'] = day;
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      final path = request.url.pathSegments.last;
      final body = switch (path) {
        'perfil' => '{"data":{"id_usuarios":1,"id_evaluacion":8,"fecha_evaluacion":"2026-09-02"}}',
        'evaluacionesfisicas' => '{"data":[{"id":8,"fecha_evaluacion":"2026-09-02","peso":78.5,"altura":175,"porcentaje_grasa":18.2,"masa_muscular":35.2,"cintura":90,"pecho":100,"brazo":33,"muslo":55,"cadera":96}]}',
        'rutinas' => '{"data":[{"id":1,"nombre":"Rutina Inicial","descripcion":"Rutina general","objetivo":"perdida_peso","dias_semana":4,"duracion_estimada":60,"fecha_inicio":"2026-08-01","fecha_fin":"2026-09-01","estado":1,"id_usuarios":1}]}',
        'progresos' => '{"data":[{"id":1,"fecha":"2026-08-01","peso":"82.50","altura":"1.75","porcentaje_grasa":"25.40","masa_muscular":"35.20","cintura":"94.00","pecho":"102.00","brazo":"34.00","muslo":"57.00","cadera":"98.00","notas":"Medición inicial","id_usuarios":1}]}',
        'peso-grasa' => '{"data":{"id_usuarios":1,"id_evaluacion":8,"fecha_evaluacion":"2026-09-02","peso":78.5,"porcentaje_grasa":18.2}}',
        'notificaciones' => '{"data":[{"id":1,"tipo":"rutina","titulo":"Nueva rutina","mensaje":"Disponible","fecha_envio":"2026-08-25 08:00:00","leida":0,"id_usuarios":1}]}',
        'sensaciones' => '{"data":[{"id":1,"fecha":"2026-08-01","energia":8,"dificultad":5,"fatiga":4,"dolor":1,"comentario":"Buena energía","id_usuarios":1,"id_rutinas":1}]}',
        _ => '{"data":[]}',
      };
      return http.Response(body, 200);
    }),
  );
}

String _usuariosJson(bool includeNickname) =>
    '{"data":[{"id":1,"nombres":"Juan","apellidos":"Perez Ramirez","correo":"juan.perez@gmail.com","tipo_documento":"DNI","numero_documento":"70123456","telefono":"987654321","direccion":"Jr. Los Pinos 123","foto_perfil":"gym-bros/storage/app/public/usuario/prueba_gym.webp","fecha_registro":"2026-01-10","fecha_nacimiento":"1998-05-15","asistencia_semanal":"2026-08-24 08:30:00","tipo_usuario":"Usuario","id_empresas":1${includeNickname ? ',"apodo":"bro"' : ''}}]}';

const _empresasJson =
    '{"data":[{"id":1,"nombre":"titan gym","nombre_gerente":"Carlos Mendoza","region":"Cajamarca","direccion":"Av. Hoyos Rubio 123","telefono":"976123456","correo":"contacto@gymbros.pe","enlace_web":"https://gymbros.pe","logo":"gym-bros/storage/app/public/empresas/titan_gym.webp","estado":1,"color_1":"#2563EB","color_2":"#111827"}]}';
