import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';
import 'package:gym_bros/screens/routine_session_screen.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> fixture({int user = 1, int routine = 1, int day = 1}) {
  final body = jsonDecode(
    File('test/fixtures/routine_session.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final data = body['data'] as Map<String, dynamic>;
  data['id_usuarios'] = user;
  data['id_rutinas'] = routine;
  data['dia'] = day;
  return body;
}

http.Response response(Map<String, dynamic> body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

const routine = GymRoutine(
  id: 12,
  userId: 7,
  name: 'Rutina personalizada',
  description: 'Entrenamiento',
  goal: 'ganancia_muscular',
  daysPerWeek: 4,
  estimatedMinutes: 60,
  startDate: '',
  endDate: '',
  active: true,
);

void main() {
  for (var weekday = 1; weekday <= 7; weekday++) {
    testWidgets('selecciona la sesión para el día semanal $weekday', (
      tester,
    ) async {
      final expectedDay = weekday <= routine.daysPerWeek ? weekday : 1;
      final requestedDays = <int>[];
      final api = GymApi(
        client: MockClient((request) async {
          final day = int.parse(request.url.pathSegments.last);
          requestedDays.add(day);
          final body = fixture(user: 7, routine: 12, day: day);
          body['data']['ejercicios'] = [];
          return response(body);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: RoutineSessionScreen(
              routine: routine,
              api: api,
              embedded: true,
              currentDate: () => DateTime(2026, 9, 6 + weekday),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requestedDays, [expectedDay]);
      expect(
        tester
            .widget<Semantics>(find.byKey(ValueKey('session-day-$expectedDay')))
            .properties
            .selected,
        isTrue,
      );
      final otherDay = expectedDay == 1 ? 2 : 1;
      await tester.tap(find.byKey(ValueKey('session-day-$otherDay')));
      await tester.pumpAndSettle();
      expect(requestedDays, [expectedDay, otherDay]);
    });
  }
  test(
    'usa IDs dinámicos, interpreta el contrato real y ordena los ejercicios',
    () async {
      final body = fixture(user: 7, routine: 12, day: 3);
      final data = body['data'] as Map<String, dynamic>;
      data['ejercicios'] = (data['ejercicios'] as List).reversed.toList();
      final api = GymApi(
        client: MockClient((request) async {
          expect(request.url.path, '/api/usuarios/7/rutinas/12/sesiones/3');
          expect(request.headers['Accept'], 'application/json');
          return response(body);
        }),
      );
      final result = await api.fetchRoutineSession(
        userId: 7,
        routineId: 12,
        day: 3,
      );
      expect(result.day, 3);
      expect(result.exercises.map((e) => e.name), [
        'Press banca',
        'Remo con polea',
      ]);
      expect(result.exercises.first.series, '4');
      expect(result.exercises.first.weight, '40.00');
      expect(result.exercises.first.restSeconds, '90');
      expect(result.exercises.first.muscle, 'pecho');
      expect(result.exercises.first.instructions, contains('escapulas'));
    },
  );

  test('rechaza respuestas de otra sesión y formatos incompletos', () async {
    for (final body in [
      fixture(user: 99),
      <String, dynamic>{'data': []},
    ]) {
      final api = GymApi(client: MockClient((_) async => response(body)));
      await expectLater(
        api.fetchRoutineSession(userId: 1, routineId: 1, day: 1),
        throwsA(isA<GymApiException>()),
      );
    }
  });

  testWidgets(
    'carga ejercicios, cambia día sin datos antiguos y permite reintentar',
    (tester) async {
      var attempts = 0;
      final pending = Completer<http.Response>();
      final api = GymApi(
        client: MockClient((request) async {
          final day = int.parse(request.url.pathSegments.last);
          if (day == 2 && attempts++ == 0) return pending.future;
          final body = fixture(user: 7, routine: 12, day: day);
          // Imágenes se prueban mediante su fallback en dispositivo, sin red en este test.
          for (final item in body['data']['ejercicios'] as List) {
            item['ejercicio']['imagen_ejercicio'] = '';
          }
          if (day == 2) body['data']['ejercicios'] = [];
          return response(body);
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: RoutineSessionScreen(
            routine: routine,
            api: api,
            currentDate: () => DateTime(2026, 9, 7),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1. Press banca'), findsOneWidget);
      expect(find.text('Series'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('session-day-2')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('1. Press banca'), findsNothing);
      pending.complete(http.Response('', 503));
      await tester.pumpAndSettle();
      expect(find.textContaining('HTTP 503'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('retry-session')));
      await tester.pumpAndSettle();
      expect(
        find.text('Todavía no hay ejercicios asignados a esta sesión.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
