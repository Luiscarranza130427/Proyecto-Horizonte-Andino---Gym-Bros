import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/widgets/new_measurements_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const measures = {
  'peso': '72,35',
  'altura': '170',
  'porcentaje_grasa': '18.75',
  'masa_muscular': '30',
  'cintura': '80',
  'pecho': '90',
  'brazo': '30',
  'muslo': '50',
  'cadera': '90',
};
const profile = GymTrainingProfile(
  userId: 42,
  evaluationId: 7,
  date: '2026-09-09',
  goal: 'ganancia_muscular',
  experience: '4a8meses',
  dailyActivity: 'moderadamente_activo',
  daysPerWeek: 3,
  availableDays: ['Lunes', 'Miercoles', 'Viernes'],
  minutesPerSession: 60,
  restrictions: 'sin-restricciones',
);

Future<void> openForm(
  WidgetTester tester,
  Future<GymProgress> Function(Map<String, dynamic>) submit, {
  VoidCallback? onSaved,
  Map<String, dynamic>? initialEvaluation,
}) async {
  final user = GymUser.fromJson({
    'id': 42,
    'id_empresas': 1,
    'fecha_nacimiento': '1996-04-15',
  }, mediaBaseUri: Uri.parse('http://localhost/'));
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => NewMeasurementsSheet(
                user: user,
                profile: profile,
                initialEvaluation: initialEvaluation,
                onSubmit: submit,
                onSaved: onSaved ?? () {},
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Abrir'));
  await tester.pumpAndSettle();
}

Future<void> fillMeasures(WidgetTester tester) async {
  for (final entry in measures.entries) {
    final field = find.byKey(ValueKey('measurement-${entry.key}'));
    await tester.ensureVisible(field);
    await tester.enterText(field, entry.value);
  }
}

Future<void> save(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('save-measurements'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Guardar envía el contrato completo y cierra al recibir 201', (
    tester,
  ) async {
    var requests = 0;
    var saved = false;
    final api = GymApi(
      client: MockClient((request) async {
        requests++;
        expect(request.method, 'POST');
        expect(request.url.path, '/api/usuarios/42/evaluaciones');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['peso'], 72.35);
        expect(body['nivel_experiencia'], '4a8meses');
        expect(body['objetivo'], 'ganancia_muscular');
        expect(body['edad'], isA<int>());
        expect(body['dias_semana'], 3);
        expect(body['eleccion_dias'], profile.availableDays);
        expect(body['fecha_evaluacion'], matches(r'^\d{4}-\d{2}-\d{2}$'));
        expect(body.containsKey('fecha'), isFalse);
        expect(
          body.keys,
          containsAll([
            ...measures.keys,
            'actividad_diaria',
            'restricciones',
            'tiempo_sesion_min',
          ]),
        );
        return http.Response(
          jsonEncode({
            'data': {...body, 'id': 123, 'id_usuarios': 42},
          }),
          201,
        );
      }),
    );
    await openForm(tester, (values) async {
      final result = await api.createEvaluation(userId: 42, values: values);
      expect(result.date, values['fecha_evaluacion']);
      expect(result.weight, 72.35);
      return result;
    }, onSaved: () => saved = true);
    await fillMeasures(tester);
    await save(tester);
    expect(requests, 1);
    expect(saved, isTrue);
    expect(find.byType(NewMeasurementsSheet), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    '422 visible dentro del formulario conserva medidas y permite reintentar',
    (tester) async {
      final api = GymApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': 'Datos inválidos',
              'errors': {
                'altura': ['Revisa la altura.'],
              },
            }),
            422,
            headers: {'content-type': 'application/json; charset=utf-8'},
          ),
        ),
      );
      await openForm(
        tester,
        (values) => api.createEvaluation(userId: 42, values: values),
      );
      await fillMeasures(tester);
      await save(tester);
      expect(find.byKey(const ValueKey('measurement-error')), findsOneWidget);
      expect(find.textContaining('Revisa la altura.'), findsOneWidget);
      expect(find.text('GUARDAR MEDIDAS'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('measurement-peso')),
            )
            .controller!
            .text,
        '72,35',
      );
    },
  );

  testWidgets('No envía campos incompletos ni números inválidos', (
    tester,
  ) async {
    var requests = 0;
    await openForm(tester, (_) {
      requests++;
      throw StateError('No enviar');
    });
    await save(tester);
    expect(requests, 0);
    await fillMeasures(tester);
    final weight = find.byKey(const ValueKey('measurement-peso'));
    await tester.ensureVisible(weight);
    await tester.enterText(weight, 'abc');
    await save(tester);
    expect(find.text('Ingresa un número válido'), findsOneWidget);
    expect(requests, 0);
  });

  testWidgets('Bloquea envíos duplicados mientras se guarda', (tester) async {
    final pending = Completer<GymProgress>();
    var requests = 0;
    await openForm(tester, (_) {
      requests++;
      return pending.future;
    });
    await fillMeasures(tester);
    await save(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('save-measurements')));
    await tester.tap(find.byKey(const ValueKey('save-measurements')));
    await tester.pump();
    expect(requests, 1);
    pending.completeError(const GymApiException('Error de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('GUARDAR MEDIDAS'), findsOneWidget);
  });
}
