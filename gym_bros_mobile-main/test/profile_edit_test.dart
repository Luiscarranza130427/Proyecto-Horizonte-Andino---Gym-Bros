import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';
import 'package:gym_bros/screens/profile_screen.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _usuario = {
  'id': 1,
  'nombres': 'Ana',
  'apellidos': 'Torres',
  'apodo': 'anita',
  'correo': 'ana@gymbros.test',
  'tipo_documento': 'PASAPORTE',
  'numero_documento': 'PE123456',
  'telefono': '987654321',
  'direccion': 'Av. Principal 101',
  'fecha_nacimiento': '1995-04-12',
  'tipo_usuario': 'Usuario',
  'estado': 1,
  'id_empresas': 1,
};

Future<GymSessionData> _session() {
  final api = GymApi(
    client: MockClient((request) async {
      final data = switch (request.url.path) {
        '/api/auth/me' => _usuario,
        '/api/empresas/1' => {'id': 1, 'nombre': 'Titan Gym', 'estado': 1},
        _ => <Object>[],
      };
      if (request.url.path.contains('/evaluaciones/')) {
        return http.Response('{"message":"Sin evaluación"}', 404);
      }
      return http.Response(jsonEncode({'data': data}), 200);
    }),
  );
  return api.fetchUserData('ana@gymbros.test');
}

Future<void> _abrirEdicion(
  WidgetTester tester,
  GymSessionData session, {
  required Future<void> Function(GymUser) onUpdateUser,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ProfileScreen(
          session: session,
          onLogout: () {},
          onOpenProgress: () {},
          onUpdateUser: onUpdateUser,
        ),
      ),
    ),
  );
  await tester.tap(find.text('DATOS PERSONALES'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('edit-personal-data')));
  await tester.tap(find.byKey(const ValueKey('edit-personal-data')));
  await tester.pumpAndSettle();
}

Finder _campo(String etiqueta) => find.widgetWithText(TextFormField, etiqueta);

Future<void> _guardar(WidgetTester tester) async {
  // PrimaryButton muestra su etiqueta en mayúsculas.
  final boton = find.text('GUARDAR CAMBIOS');
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('el tipo de documento viaja con el valor que acepta la API', (
    tester,
  ) async {
    final session = await tester.runAsync(_session);
    GymUser? enviado;
    await _abrirEdicion(
      tester,
      session!,
      onUpdateUser: (user) async => enviado = user,
    );

    // «PASAPORTE» guardado se muestra como «Pasaporte» sin romper el selector.
    expect(find.text('Pasaporte'), findsOneWidget);
    await _guardar(tester);

    expect(enviado, isNotNull);
    expect(enviado!.documentType, 'PASAPORTE');
  });

  testWidgets(
    'rechaza teléfonos que no caben en la API y envía el número limpio',
    (tester) async {
      final session = await tester.runAsync(_session);
      GymUser? enviado;
      await _abrirEdicion(
        tester,
        session!,
        onUpdateUser: (user) async => enviado = user,
      );

      await tester.enterText(_campo('Teléfono / WhatsApp'), '+51 987 654 3210');
      await _guardar(tester);
      expect(find.text('Usa de 6 a 12 dígitos'), findsOneWidget);
      expect(enviado, isNull);

      await tester.enterText(_campo('Teléfono / WhatsApp'), '987 654-321');
      await _guardar(tester);
      expect(enviado?.phone, '987654321');
    },
  );

  testWidgets('exige apodo y un documento válido para su tipo', (tester) async {
    final session = await tester.runAsync(_session);
    GymUser? enviado;
    await _abrirEdicion(
      tester,
      session!,
      onUpdateUser: (user) async => enviado = user,
    );

    await tester.enterText(_campo('Apodo / Nickname'), '');
    await tester.enterText(_campo('Número de doc.'), 'PE1234567890X');
    await _guardar(tester);

    expect(find.text('Ingresa tu apodo'), findsOneWidget);
    expect(find.text('De 5 a 12 caracteres'), findsOneWidget);
    expect(enviado, isNull);
  });
}
