import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/models/nutrition_plan.dart';
import 'package:gym_bros/widgets/food_profile_sheet.dart';

http.Response response(Object? data) => http.Response(
  jsonEncode({'data': data}),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Json profile() => {
  'id_usuarios': 7,
  'sexo_calculo': 'masculino',
  'embarazo': false,
  'lactancia': false,
  'requiere_plan_clinico': false,
  'apto_plan_general': true,
  'revision_profesional': 'Revisión de prueba',
  'revisado_en': formatCalendarDate(DateTime.now()),
  'restricciones': [
    {'id_restricciones_alimentarias': 3, 'tipo': 'alergia'},
  ],
  'preferencias': [
    {'id_alimentos': 9, 'tipo': 'rechazado'},
  ],
};
void main() {
  test('PUT usa usuario, JSON y respuesta 200; rechaza otro usuario', () async {
    final api = GymApi(
      client: MockClient((r) async {
        expect(r.method, 'PUT');
        expect(r.url.path, '/api/usuarios/7/perfil-alimentario');
        expect(r.headers['Accept'], 'application/json');
        expect(jsonDecode(r.body)['alergias'], [3]);
        return response(profile());
      }),
    );
    expect(
      (await api.saveFoodProfile(7, {
        'alergias': [3],
      })).userId,
      7,
    );
    final other = GymApi(client: MockClient((r) async => response(profile())));
    await expectLater(
      other.saveFoodProfile(8, {}),
      throwsA(isA<NutritionApiException>()),
    );
  });
  test('perfil ausente habilita creación; 422 conserva errores', () async {
    final api = GymApi(
      client: MockClient(
        (r) async => r.method == 'GET'
            ? http.Response('{}', 404)
            : http.Response(
                jsonEncode({
                  'message': 'Datos inválidos',
                  'errors': {
                    'revisado_en': ['Revisión vencida'],
                  },
                }),
                422,
                headers: {'content-type': 'application/json; charset=utf-8'},
              ),
      ),
    );
    expect(await api.editableFoodProfile(7), isNull);
    await expectLater(
      api.saveFoodProfile(7, {}),
      throwsA(
        isA<NutritionApiException>().having(
          (e) => e.errors['revisado_en'],
          'errors',
          ['Revisión vencida'],
        ),
      ),
    );
  });
  testWidgets('editar conserva selecciones y no duplica PUT', (tester) async {
    final pending = Completer<http.Response>();
    int calls = 0;
    final api = GymApi(
      client: MockClient((r) async {
        if (r.method == 'PUT') {
          calls++;
          final body = jsonDecode(r.body);
          expect(body['alergias'], [3]);
          expect(body['intolerancias'], isEmpty);
          expect(body['preferencias'], [
            {'id_alimentos': 9, 'tipo': 'rechazado'},
            {'id_alimentos': 10, 'tipo': 'rechazado'},
          ]);
          return pending.future;
        }
        if (r.url.path.endsWith('restriccionesalimentarias')) {
          return response([
            {'id': 3, 'nombre': 'Prueba alergia'},
          ]);
        }
        if (r.url.path.endsWith('/alimentos')) {
          return response([
            {'id': 9, 'nombre': 'Prueba alimento'},
            {'id': 10, 'nombre': 'Otro alimento'},
          ]);
        }
        return response(profile());
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodProfileSheet(api: api, userId: 7, isCurrent: () => true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final section = find.text('Preferencias e intolerancias');
    await tester.ensureVisible(section);
    await tester.tap(section);
    await tester.pumpAndSettle();
    final existing = find.byKey(const ValueKey('food-choice-9'));
    final fresh = find.byKey(const ValueKey('food-choice-10'));
    expect(tester.widget<CheckboxListTile>(existing).value, false);
    expect(tester.widget<CheckboxListTile>(fresh).value, true);
    expect(tester.getTopLeft(existing).dy, tester.getTopLeft(fresh).dy);
    expect(
      tester.getTopLeft(existing).dx,
      lessThan(tester.getTopLeft(fresh).dx),
    );
    await tester.ensureVisible(fresh);
    await tester.tap(fresh);
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(fresh).value, false);
    final save = find.text('GUARDAR DATOS ALIMENTARIOS');
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.tap(save);
    await tester.pump();
    expect(calls, 1);
    pending.complete(
      http.Response(
        jsonEncode({
          'message': 'Revisar fecha',
          'errors': {
            'revisado_en': ['Fecha vencida'],
          },
        }),
        422,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Fecha vencida'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('nuevos datos no asignan aptitud ni revisión automáticamente', (
    tester,
  ) async {
    int writes = 0;
    final api = GymApi(
      client: MockClient((r) async {
        if (r.method != 'GET') writes++;
        if (r.url.path.endsWith('perfil-alimentario')) {
          return http.Response('{}', 404);
        }
        return response([]);
      }),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FoodProfileSheet(api: api, userId: 7, isCurrent: () => true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('GUARDAR DATOS ALIMENTARIOS'));
    await tester.tap(find.text('GUARDAR DATOS ALIMENTARIOS'));
    await tester.pumpAndSettle();
    expect(writes, 0);
    expect(find.text('Selecciona una opción.'), findsWidgets);
    expect(find.text('Revisión profesional'), findsNothing);
  });
}
