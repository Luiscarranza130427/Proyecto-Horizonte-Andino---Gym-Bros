import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/progress_overview.dart';
import 'package:gym_bros/screens/progress_screen.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:gym_bros/theme/app_theme.dart';

const evaluation = <String, dynamic>{
  'id': 3,
  'id_usuarios': 1,
  'fecha_evaluacion': '2026-09-10',
  'peso': 80,
  'altura': 200,
  'edad': 28,
  'porcentaje_grasa': 25,
  'masa_muscular': 35,
  'cintura': 90,
  'pecho': 100,
  'brazo': 34,
  'muslo': 56,
  'cadera': 96,
};

Widget page(Future<Map<String, dynamic>> Function() load, {Object? revision}) =>
    MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: ProgressScreen(
          userName: 'Usuario de prueba',
          loadLatest: load,
          revision: revision,
          progress: const [],
          sensations: const [],
        ),
      ),
    );

void main() {
  testWidgets('Generar bloquea dobles toques y refleja el cupo del servidor', (
    tester,
  ) async {
    final pending = Completer<void>();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(
          body: ProgressScreen(
            userName: 'Usuario',
            loadLatest: () async => evaluation,
            progress: const [],
            sensations: const [],
            loadGenerationStatus: () async => {
              'permitido': calls == 0,
              'generadas_mes': calls == 0 ? 2 : 3,
              'mensaje': 'Límite mensual',
            },
            onGenerateRoutine: () {
              calls++;
              return pending.future;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final button = find.text('GENERAR NUEVA RUTINA');
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    pending.complete();
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump();
    expect(calls, 1);
    expect(find.textContaining('3 generadas este mes'), findsOneWidget);
  });
  test('Clasifica IMC adulto por límites sin redondear', () {
    for (final entry in <double, String>{
      18.49: 'Bajo peso',
      18.5: 'Peso saludable',
      24.99: 'Peso saludable',
      25: 'Sobrepeso',
      29.99: 'Sobrepeso',
      30: 'Obesidad',
      40: 'Obesidad',
    }.entries) {
      final data = ProgressOverview({
        'peso': entry.key * 4,
        'altura': 200,
        'edad': 20,
      });
      expect(data.bmiClassification, entry.value);
    }
    expect(
      ProgressOverview({...evaluation, 'edad': 19}).bmiClassification,
      'Requiere valoración por edad',
    );
    expect(
      ProgressOverview({...evaluation, 'edad': null}).bmiClassification,
      'Falta registrar la edad',
    );
    expect(
      ProgressOverview({...evaluation, 'altura': null}).bmiClassification,
      isNull,
    );
  });
  test('Calcula con centímetros y omite datos ausentes o inválidos', () {
    final data = ProgressOverview(evaluation);
    expect(data.bmi, 20);
    expect(data.fatKg, 20);
    expect(data.leanKg, 60);
    expect(data.muscle, 35);
    final missing = ProgressOverview({'peso': 80, 'altura': 0});
    expect(missing.bmi, isNull);
    expect(missing.fatKg, isNull);
    expect(missing.muscle, isNull);
    expect(
      ProgressOverview({'peso': 80, 'porcentaje_grasa': 110}).fatKg,
      isNull,
    );
  });

  testWidgets(
    'Muestra la última evaluación con unidades y sin métricas no disponibles',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(page(() async => evaluation));
      await tester.pumpAndSettle();
      expect(find.text('80.0 kg'), findsOneWidget);
      expect(find.text('20.0 kg/m²'), findsOneWidget);
      expect(find.text('Peso saludable'), findsOneWidget);
      expect(find.text('Calculado con peso y altura'), findsNothing);
      expect(find.text('200.0 cm'), findsOneWidget);
      expect(find.text('60.0 kg'), findsOneWidget);
      expect(find.text('Puntuación corporal'), findsNothing);
      expect(find.text('Agua corporal'), findsNothing);
      await tester.ensureVisible(find.text('Cadera'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Datos parciales no se convierten en mediciones cero', (
    tester,
  ) async {
    await tester.pumpWidget(
      page(() async => {'peso': 80, 'fecha_evaluacion': '2026-09-10'}),
    );
    await tester.pumpAndSettle();
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(find.text('IMC'), findsNothing);
    expect(find.text('Grasa corporal'), findsNothing);
    expect(find.text('MEDIDAS CORPORALES'), findsNothing);
  });

  testWidgets('Error visible y reintento recupera datos reales', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      page(() async {
        if (++calls == 1) throw const GymApiException('Servidor no disponible');
        return evaluation;
      }),
    );
    await tester.pumpAndSettle();
    expect(find.text('Servidor no disponible'), findsOneWidget);
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();
    expect(find.text('80.0 kg'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('Editar evaluación refresca datos sin cambiar pestaña', (
    tester,
  ) async {
    await tester.pumpWidget(page(() async => evaluation, revision: 1));
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      page(() async => {...evaluation, 'peso': 79}, revision: 2),
    );
    await tester.pumpAndSettle();
    expect(find.text('79.0 kg'), findsOneWidget);
    expect(find.text('80.0 kg'), findsNothing);
  });
}
