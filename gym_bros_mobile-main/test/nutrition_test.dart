import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:gym_bros/services/nutrition_plan_reference.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gym_bros/models/nutrition_plan.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/screens/nutrition_screen.dart';
import 'package:gym_bros/widgets/generate_nutrition_sheet.dart';
import 'package:gym_bros/theme/app_theme.dart';

import 'fixtures/nutrition_fixture.dart';

http.Response envelope(Object? value, [int status = 200]) => http.Response(
  jsonEncode({'data': value}),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
NutritionGeneration input({
  int meals = 3,
  int days = 7,
  String? date,
  Map<String, String>? times,
}) => NutritionGeneration(
  start: date ?? formatCalendarDate(DateTime.now()),
  days: days,
  meals: meals,
  times:
      times ??
      {
        for (final name in NutritionGeneration.types(meals))
          name: {
            'desayuno': '08:00',
            'media_manana': '10:00',
            'almuerzo': '13:00',
            'media_tarde': '16:00',
            'cena': '20:00',
          }[name]!,
      },
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('404 invalida referencia y no vuelve a consultar al reabrir', (
    tester,
  ) async {
    final refs = NutritionPlanReference();
    final api = GymApi(
      client: MockClient((r) async {
        if (r.url.path.endsWith('perfil-alimentario')) {
          return envelope({
            'id_usuarios': 7,
            'apto_plan_general': true,
            'requiere_plan_clinico': false,
          });
        }
        expect(r.url.path, '/api/usuarios/7/planesalimentacion/12');
        return http.Response('{}', 404);
      }),
    );
    await refs.save(api.apiBaseUri, 7, 12);
    Widget page() => MaterialApp(
      home: Scaffold(body: NutritionScreen(userId: 7, api: api)),
    );
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();
    expect(find.text('Sin plan disponible'), findsOneWidget);
    expect(await refs.read(api.apiBaseUri, 7), isNull);
    await tester.pumpWidget(const SizedBox());
    final noDetail = GymApi(
      client: MockClient((r) async {
        expect(r.url.path.endsWith('perfil-alimentario'), true);
        return envelope({
          'id_usuarios': 7,
          'apto_plan_general': true,
          'requiere_plan_clinico': false,
        });
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NutritionScreen(userId: 7, api: noDetail)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin plan disponible'), findsOneWidget);
  });
  test('referencias separadas por usuario y servidor', () async {
    final refs = NutritionPlanReference();
    final server = GymApi().apiBaseUri;
    await refs.save(server, 7, 12);
    await refs.save(server, 8, 19);
    expect(await refs.read(server, 7), 12);
    expect(await refs.read(server, 8), 19);
    expect(await refs.read(Uri.parse('https://example.test/api/'), 7), isNull);
    await refs.invalidate(server, 7, 11);
    expect(await refs.read(server, 7), 12);
  });
  testWidgets(
    'GET puede reintentarse y completar después de dispose sin errores',
    (tester) async {
      var calls = 0;
      await NutritionPlanReference().save(GymApi().apiBaseUri, 7, 12);
      final pending = Completer<http.Response>();
      final api = GymApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('perfil-alimentario')) {
            return envelope({
              'id_usuarios': 7,
              'apto_plan_general': true,
              'requiere_plan_clinico': false,
              'revision_profesional': null,
            });
          }
          calls++;
          if (calls == 1) throw const SocketException('offline');
          return pending.future;
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NutritionScreen(userId: 7, api: api)),
        ),
      );
      await tester.pumpAndSettle();
      final retry = find.text('Reintentar consulta');
      await tester.ensureVisible(retry);
      await tester.tap(retry);
      await tester.pump();
      expect(calls, 2);
      await tester.pumpWidget(const SizedBox());
      pending.complete(envelope([]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    '201 muestra el detalle recibido y conserva su ID sin GET de último plan',
    (tester) async {
      var posts = 0, details = 0;
      final api = GymApi(
        client: MockClient((r) async {
          if (r.method == 'POST') {
            posts++;
            return envelope(planFixture(), 201);
          }
          if (r.url.path.endsWith('perfil-alimentario')) {
            return envelope({
              'id_usuarios': 7,
              'apto_plan_general': true,
              'requiere_plan_clinico': false,
              'revision_profesional': null,
            });
          }
          if (r.url.path.endsWith('planesalimentacion')) return envelope([]);
          details++;
          return envelope(planFixture());
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: NutritionScreen(userId: 7, api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(posts, 0);
      await tester.tap(find.byKey(const ValueKey('new-nutrition')));
      await tester.pumpAndSettle();
      final submit = find.byKey(const ValueKey('submit-nutrition'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(posts, 1);
      expect(details, 0);
      expect(find.text('Plan de prueba'), findsOneWidget);
      expect(find.byType(GenerateNutritionSheet), findsNothing);
      expect(await NutritionPlanReference().read(api.apiBaseUri, 7), 12);
      expect(await NutritionPlanReference().read(api.apiBaseUri, 8), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: NutritionScreen(userId: 7, api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(details, 1);
      expect(find.text('Plan de prueba'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test('Detalle tipado ordena días/comidas y conserva porción y nutrientes guardados', () {
    final p = NutritionPlan(planFixture());
    expect(p.days.map((d) => d.day), [1, 2]);
    expect(p.days.first.meals.map((m) => m.order), [1, 2]);
    expect(p.start, '2026-09-11');
    expect(p.targets.fiber, isNull);
    final food = p.days.first.meals.first.foods.first;
    expect(food.quantity, 150.75);
    expect(food.snapshot.baseQuantity, 100);
    expect(food.snapshot.nutrients.calories, 500.25);
    expect(food.notes, isNull);
    expect(p.totals.calories, 9000);
  });
  test('No convierte obligatorios ausentes/nulos o infinitos a cero', () {
    for (final key in [
      'id',
      'id_usuarios',
      'calculo',
      'dias',
      'totales_plan',
      'advertencias',
    ]) {
      expect(
        () => NutritionPlan({...planFixture(), key: null}),
        throwsA(anyOf(isA<FormatException>(), isA<TypeError>())),
      );
    }
    for (final value in [null, 'NaN', 'Infinity', -3, 'texto']) {
      expect(
        () => Nutrients(nutrients(calories: value ?? 'null')),
        throwsFormatException,
      );
    }
    expect(() => calendarDate('2026-02-31'), throwsFormatException);
    expect(calendarDate('2026-09-11T00:00:00+14:00'), '2026-09-11');
    expect(
      () => NutritionPlan({'id': 1, 'id_usuarios': 7, 'nombre': 'Resumen'}),
      throwsFormatException,
    );
  });
  test('Validación de fechas, duración y horarios para 3/4/5 comidas', () {
    for (final count in [3, 4, 5]) {
      final data = input(meals: count).toJson();
      expect((data['horarios'] as Map).length, count);
      expect(data.keys.toSet(), {
        'fecha_inicio',
        'duracion_dias',
        'cantidad_comidas',
        'horarios',
      });
    }
    for (final days in [0, 15]) {
      expect(() => input(days: days).toJson(), throwsFormatException);
    }
    for (final offset in [-1, 31]) {
      expect(
        () => input(
          date: formatCalendarDate(DateTime.now().add(Duration(days: offset))),
        ).toJson(),
        throwsFormatException,
      );
    }
    expect(
      input(
        days: 14,
        date: formatCalendarDate(DateTime.now().add(const Duration(days: 30))),
      ).toJson()['duracion_dias'],
      14,
    );
    for (final time in ['08:00', '07:59', '25:00', '8:30']) {
      expect(
        () => input(
          times: {'desayuno': '08:00', 'almuerzo': time, 'cena': '20:00'},
        ).toJson(),
        throwsFormatException,
      );
    }
  });
  test('Listado es resumen, filtra usuario y acepta lista vacía', () async {
    final api = GymApi(
      client: MockClient(
        (r) async => envelope([
          {'id': '1', 'id_usuarios': 7, 'nombre': 'Mío'},
          {'id': 2, 'id_usuarios': 8, 'nombre': 'Otro'},
        ]),
      ),
    );
    expect((await api.nutritionPlans(7)).single.name, 'Mío');
    expect(await api.nutritionPlans(9), isEmpty);
  });
  test(
    'GET detalle usa los dos IDs y rechaza respuesta de otro usuario',
    () async {
      final api = GymApi(
        client: MockClient((r) async {
          expect(r.url.path, '/api/usuarios/7/planesalimentacion/12');
          expect(r.method, 'GET');
          expect(r.headers['Accept'], 'application/json');
          return envelope(planFixture(user: 8));
        }),
      );
      await expectLater(
        api.nutritionPlan(7, 12),
        throwsA(isA<NutritionApiException>()),
      );
    },
  );
  test(
    'POST solo contrato permitido, devuelve id y no llama otra ruta',
    () async {
      var calls = 0;
      final api = GymApi(
        client: MockClient((r) async {
          calls++;
          expect(r.method, 'POST');
          expect(r.url.path, '/api/planesalimentacion/generar/7');
          expect(r.headers['content-type'], 'application/json');
          expect((jsonDecode(r.body) as Map).keys.toSet(), {
            'fecha_inicio',
            'duracion_dias',
            'cantidad_comidas',
            'horarios',
          });
          return envelope(planFixture(), 201);
        }),
      );
      expect((await api.generateNutrition(7, input())).id, 12);
      expect(calls, 1);
    },
  );
  test('422 conserva message/errors y nunca reintenta POST', () async {
    var calls = 0;
    final api = GymApi(
      client: MockClient((r) async {
        calls++;
        return http.Response(
          jsonEncode({
            'message': 'No hay alimentos verificados',
            'errors': {
              'alimentos': ['Falta catálogo verificado'],
            },
            'trace': 'privado',
          }),
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    await expectLater(
      api.generateNutrition(7, input()),
      throwsA(
        isA<NutritionApiException>().having(
          (e) => e.toString(),
          'texto',
          contains('Falta catálogo verificado'),
        ),
      ),
    );
    expect(calls, 1);
  });
  for (final status in [404, 503, 500]) {
    test('HTTP $status sin HTML ni trazas', () async {
      final api = GymApi(
        client: MockClient(
          (r) async => http.Response('<html>trace secreto</html>', status),
        ),
      );
      await expectLater(
        api.nutritionPlan(7, 12),
        throwsA(
          isA<NutritionApiException>()
              .having((e) => e.status, 'HTTP', status)
              .having(
                (e) => e.toString(),
                'limpio',
                isNot(contains('secreto')),
              ),
        ),
      );
    });
  }
  test('Timeout y conexión muestran error consultable', () async {
    for (final error in [
      TimeoutException('timeout'),
      const SocketException('offline'),
      http.ClientException('offline'),
    ]) {
      final api = GymApi(client: MockClient((r) async => throw error));
      await expectLater(
        api.nutritionPlan(7, 12),
        throwsA(isA<NutritionApiException>()),
      );
    }
  });
  testWidgets(
    'Carga automática del plan único, navegación diaria y totales diarios',
    (tester) async {
      await NutritionPlanReference().save(GymApi().apiBaseUri, 7, 12);
      tester.view.physicalSize = const Size(900, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var posts = 0;
      final api = GymApi(
        client: MockClient((r) async {
          if (r.method == 'POST') posts++;
          if (r.url.path.endsWith('perfil-alimentario')) {
            return http.Response('{"message":"Perfil ausente"}', 404);
          }
          if (r.url.path.endsWith('planesalimentacion')) {
            return envelope([
              {'id': 12, 'id_usuarios': 7, 'nombre': 'Elegir plan'},
            ]);
          }
          return envelope(planFixture());
        }),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(body: NutritionScreen(userId: 7, api: api)),
        ),
      );
      await tester.pumpAndSettle();
      expect(posts, 0);
      expect(find.text('Plan de prueba'), findsOneWidget);
      expect(find.text('SELECCIONA UN PLAN'), findsNothing);
      expect(find.text('Consultar plan por ID'), findsNothing);
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('nutrition-day-selector')),
      );
      await tester.tap(find.byKey(const ValueKey('nutrition-day-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Día 1').last);
      await tester.pumpAndSettle();
      expect(find.text('Energía: 500.0 / 2000.0 kcal'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('nutrition-day-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Día 2').last);
      await tester.pumpAndSettle();
      expect(find.text('Energía: 1000.0 / 2000.0 kcal'), findsOneWidget);
      expect(find.text('Comida 2-1'), findsOneWidget);
      expect(find.text('Comida 1-1'), findsNothing);
      expect(find.textContaining('9000.0'), findsNothing);
      expect(posts, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Cambio de usuario descarta GET pendiente y no actualiza tras dispose',
    (tester) async {
      await NutritionPlanReference().save(GymApi().apiBaseUri, 7, 12);
      final pending = Completer<http.Response>();
      final api = GymApi(
        client: MockClient((r) async {
          if (r.url.path.endsWith('perfil-alimentario')) {
            return http.Response('{}', 404);
          }
          if (r.url.path.endsWith('planesalimentacion')) {
            return envelope([
              {'id': 12, 'id_usuarios': 7, 'nombre': 'Elegir plan'},
            ]);
          }
          return pending.future;
        }),
      );
      Widget page(int user) => MaterialApp(
        home: Scaffold(
          body: NutritionScreen(userId: user, api: api),
        ),
      );
      await tester.pumpWidget(page(7));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      await tester.pumpWidget(page(8));
      await tester.pumpAndSettle();
      pending.complete(envelope(planFixture()));
      await tester.pumpAndSettle();
      expect(find.text('Plan de prueba'), findsNothing);
      expect(find.text('Elegir plan'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Formulario bloquea doble pulsación y muestra 422 sin cerrar', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<NutritionPlan>();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: GenerateNutritionSheet(
            generate: (i) {
              calls++;
              return pending.future;
            },
          ),
        ),
      ),
    );
    final button = find.byKey(const ValueKey('submit-nutrition'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    pending.completeError(
      const NutritionApiException(
        'No hay perfil',
        status: 422,
        errors: {
          'perfil': ['Debe registrarse'],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Debe registrarse'), findsOneWidget);
    expect(find.byType(GenerateNutritionSheet), findsOneWidget);
    expect(calls, 1);
  });
}
