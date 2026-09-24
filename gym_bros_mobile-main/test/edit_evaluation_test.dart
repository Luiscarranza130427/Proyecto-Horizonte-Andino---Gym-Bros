import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/widgets/new_measurements_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'create_evaluation_test.dart' show openForm, save;

const evaluation = <String, dynamic>{
  'id': 19,
  'id_usuarios': 42,
  'fecha_evaluacion': '2026-09-04',
  'peso': '72.35',
  'altura': '170.00',
  'porcentaje_grasa': '18.75',
  'masa_muscular': '30.00',
  'cintura': '80.00',
  'pecho': '90.00',
  'brazo': '30.00',
  'muslo': '50.00',
  'cadera': '90.00',
  'nivel_experiencia': '1ano',
  'actividad_diaria': 'moderadamente_activo',
  'objetivo': 'salud',
  'edad': 29,
  'dias_semana': 3,
  'eleccion_dias': ['Lunes', 'Miercoles', 'Viernes'],
  'tiempo_sesion_min': 60,
  'restricciones': 'sin-restricciones',
};

http.Response response(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  test('Carga la evaluación que identifica el perfil del usuario, no el último elemento del índice', () async {
    final paths = <String>[];
    final api = GymApi(
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/perfil')) {
          return response({
            'data': {...evaluation, 'id_evaluacion': 19},
          });
        }
        final indexRecord = Map<String, dynamic>.of(evaluation)
          ..remove('id_usuarios');
        return response({
          'data': [
            indexRecord,
            {...indexRecord, 'id': 99, 'peso': 200},
          ],
        });
      }),
    );
    final latest = await api.fetchLatestEvaluation(42);
    expect(latest['id'], 19);
    expect(latest['id_usuarios'], 42);
    expect(latest['peso'], '72.35');
    expect(paths, [
      '/api/usuarios/42/evaluaciones/perfil',
      '/api/evaluacionesfisicas',
    ]);
  });

  test('Sin evaluación informa el 404 y no consulta medidas ajenas', () async {
    var requests = 0;
    final api = GymApi(
      client: MockClient((_) async {
        requests++;
        return response({}, 404);
      }),
    );
    await expectLater(
      api.fetchLatestEvaluation(42),
      throwsA(isA<GymApiException>()),
    );
    expect(requests, 1);
  });

  testWidgets(
    'Precarga medidas y PUT envía solo cambios conservando fecha y perfil',
    (tester) async {
      var requests = 0;
      var saved = false;
      final api = GymApi(
        client: MockClient((request) async {
          requests++;
          expect(request.method, 'PUT');
          expect(request.url.path, '/api/usuarios/42/evaluaciones/ultima');
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body, {'peso': 70.5});
          return response({
            'data': {...evaluation, ...body},
          });
        }),
      );
      await openForm(
        tester,
        (values) async {
          final result = await api.updateLatestEvaluation(
            userId: 42,
            values: values,
          );
          expect(result['id'], 19);
          expect(result['fecha_evaluacion'], '2026-09-04');
          expect(result['edad'], 29);
          return GymProgress.fromJson(result);
        },
        initialEvaluation: evaluation,
        onSaved: () => saved = true,
      );
      final weight = find.byKey(const ValueKey('measurement-peso'));
      expect(tester.widget<TextFormField>(weight).controller!.text, '72.35');
      expect(find.byKey(const ValueKey('measurement-edad')), findsNothing);
      await tester.ensureVisible(weight);
      await tester.enterText(weight, '70,5');
      await save(tester);
      expect(requests, 1);
      expect(saved, isTrue);
      expect(find.byType(NewMeasurementsSheet), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('No envía PUT vacío si no se modifican medidas', (tester) async {
    var requests = 0;
    await openForm(tester, (_) async {
      requests++;
      return GymProgress.fromJson(evaluation);
    }, initialEvaluation: evaluation);
    await save(tester);
    expect(requests, 0);
    expect(find.textContaining('Modifica al menos una medida'), findsOneWidget);
  });

  testWidgets('Un 422 al editar conserva cambios y muestra el detalle', (
    tester,
  ) async {
    final api = GymApi(
      client: MockClient(
        (_) async => response({
          'message': 'Datos inválidos',
          'errors': {
            'peso': ['Revisa el peso.'],
          },
        }, 422),
      ),
    );
    await openForm(
      tester,
      (values) async => GymProgress.fromJson(
        await api.updateLatestEvaluation(userId: 42, values: values),
      ),
      initialEvaluation: evaluation,
    );
    final weight = find.byKey(const ValueKey('measurement-peso'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, '70,5');
    await save(tester);
    expect(find.textContaining('Revisa el peso.'), findsOneWidget);
    expect(tester.widget<TextFormField>(weight).controller!.text, '70,5');
    expect(find.text('GUARDAR CAMBIOS'), findsOneWidget);
  });
}
