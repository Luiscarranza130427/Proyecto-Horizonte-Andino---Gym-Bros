import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/nutrition_plan.dart';
import 'package:gym_bros/theme/app_theme.dart';
import 'package:gym_bros/widgets/generate_nutrition_sheet.dart';

/// Abre la hoja como lo hace `NutritionScreen._generate` y devuelve el tamaño
/// lógico de la pantalla.
Future<Size> _abrirHoja(
  WidgetTester tester, {
  required double ancho,
  double escalaTexto = 1,
}) async {
  tester.view.physicalSize = Size(ancho * 3, 780 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(escalaTexto)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showModalBottomSheet<NutritionPlan>(
                context: context,
                isScrollControlled: true,
                isDismissible: false,
                enableDrag: false,
                backgroundColor: Colors.transparent,
                builder: (_) => GenerateNutritionSheet(
                  generate: (_) => Completer<NutritionPlan>().future,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return Size(ancho, 780);
}

void main() {
  for (final ancho in [320.0, 360.0, 390.0]) {
    for (final escala in [1.0, 1.3]) {
      testWidgets(
        'la hoja de generar plan cabe en $ancho px con texto x$escala',
        (tester) async {
          final pantalla = await _abrirHoja(
            tester,
            ancho: ancho,
            escalaTexto: escala,
          );

          expect(tester.takeException(), isNull);
          final controles = <Finder>[
            find.byKey(const ValueKey('nutrition-start')),
            find.byType(DropdownButtonFormField<int>),
            find.byKey(const ValueKey('meal-time-desayuno')),
            find.byKey(const ValueKey('meal-time-cena')),
            find.byKey(const ValueKey('submit-nutrition')),
            find.text('Cerrar'),
            find.text('08:00'),
          ];
          for (final control in controles) {
            for (final elemento in control.evaluate()) {
              final caja = tester.getRect(find.byWidget(elemento.widget));
              expect(
                caja.left,
                greaterThanOrEqualTo(16),
                reason: '$control pegado al borde izquierdo',
              );
              expect(
                caja.right,
                lessThanOrEqualTo(pantalla.width - 16),
                reason: '$control se sale por la derecha ($caja)',
              );
            }
          }
          // Los dos selectores no se montan: antes la etiqueta «Comidas por
          // día» quedaba encima del borde del campo de arriba.
          final dias = tester.getRect(
            find.byKey(const ValueKey('nutrition-days')),
          );
          final comidas = tester.getRect(
            find.byKey(const ValueKey('nutrition-meals')),
          );
          expect(dias.overlaps(comidas), isFalse);
        },
      );
    }
  }
}
