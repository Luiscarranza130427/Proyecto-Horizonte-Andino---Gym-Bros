import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/services/gym_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'genera una rutina para el usuario mediante POST y conserva su id',
    () async {
      final api = GymApi(
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.path, '/api/rutinas/generar/7');
          expect(request.body, '{}');
          return http.Response(
            '{"data":{"id":32,"id_usuarios":7,"nombre":"Nueva rutina","estado":1}}',
            201,
          );
        }),
      );
      expect((await api.generateRoutine(7)).id, 32);
    },
  );
  test('propaga el bloqueo del servidor sin volver a generar', () async {
    var calls = 0;
    final api = GymApi(
      client: MockClient((request) async {
        calls++;
        return http.Response('{"message":"Limite mensual alcanzado"}', 422);
      }),
    );
    await expectLater(api.generateRoutine(7), throwsA(isA<GymApiException>()));
    expect(calls, 1);
  });
  test('carga y filtra todos los datos vinculados al usuario', () async {
    final api = _testGymApi();

    final session = await api.fetchUserData('juan.perez@gmail.com');

    expect(session.user.id, 1);
    expect(session.user.fullName, 'Juan Perez Ramirez');
    expect(session.company.name, 'titan gym');
    expect(session.routines.single.name, 'Rutina Inicial');
    expect(session.progress, hasLength(1));
    expect(session.weightFatEvaluation?.userId, 1);
    expect(session.weightFatEvaluation?.weight, 78.5);
    expect(session.weightFatEvaluation?.bodyFat, 18.2);
    expect(session.notifications, hasLength(1));
    expect(session.sensations, hasLength(1));
    expect(session.user.nickname, 'bro');
    expect(
      session.user.profilePhotoUrl,
      'http://192.168.1.56/storage/usuario/prueba_gym.webp',
    );
    expect(session.user.registrationDate, '2026-01-10');
    expect(
      session.user.membershipStatus(DateTime(2026, 1, 20)).title,
      'RECLUTA DE HIERRO',
    );
    expect(
      session.user.membershipStatus(DateTime(2026, 8, 28)).title,
      'MIEMBRO DE ÉLITE',
    );
    expect(
      session.user.membershipStatus(DateTime(2031, 1, 10)).title,
      'TITÁN ETERNO',
    );
    expect(
      session.company.logoUrl,
      'http://192.168.1.56/storage/empresas/titan_gym.webp',
    );
  });

  test('informa cuando el usuario no existe', () async {
    final api = GymApi(
      client: MockClient((_) async => http.Response('{"data":[]}', 200)),
    );

    expect(
      () => api.fetchUserData('nadie@example.com'),
      throwsA(isA<GymApiException>()),
    );
  });

  test('actualiza los datos del usuario en la api', () async {
    final api = GymApi(
      mediaBaseUri: Uri.parse('http://192.168.1.56/'),
      client: MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.headers['content-type'], 'application/json');
        expect(request.body, contains('"nombres":"Juan Actualizado"'));
        expect(request.url.pathSegments.last, '1');
        return http.Response(
          '{"message":"Datos actualizados correctamente","id_usuario":1,"nombre":"Juan Actualizado","apellidos":"Perez Nuevo","apodo":"bro_pro","correo":"juan.nuevo@gmail.com","telefono":"999888777","direccion":"Nueva Calle 123","fecha_nacimiento":"1998-05-15"}',
          200,
        );
      }),
    );

    final baseUser = (await _testGymApi().fetchUserData('juan.perez@gmail.com'))
        .user;
    final updated = await api.updateUserData(
      baseUser.copyWith(
        firstName: 'Juan Actualizado',
        lastName: 'Perez Nuevo',
        nickname: 'bro_pro',
        email: 'juan.nuevo@gmail.com',
        phone: '999888777',
        address: 'Nueva Calle 123',
      ),
    );

    expect(updated.firstName, 'Juan Actualizado');
    expect(updated.lastName, 'Perez Nuevo');
    expect(updated.nickname, 'bro_pro');
    expect(updated.email, 'juan.nuevo@gmail.com');
    expect(updated.phone, '999888777');
    expect(updated.address, 'Nueva Calle 123');
  });

  test(
    'no envía vacíos los campos que la API exige y permite vaciar la dirección',
    () async {
      late Map<String, dynamic> sent;
      final api = GymApi(
        client: MockClient((request) async {
          sent = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{"id_usuario":1,"nombre":"Juan"}', 200);
        }),
      );
      final baseUser = (await _testGymApi().fetchUserData(
        'juan.perez@gmail.com',
      )).user;

      await api.updateUserData(
        baseUser.copyWith(nickname: ' ', birthDate: '', address: ''),
      );

      // `sometimes|required`: un '' daba 422; omitirlo conserva el valor guardado.
      expect(sent.containsKey('apodo'), isFalse);
      expect(sent.containsKey('fecha_nacimiento'), isFalse);
      expect(sent['direccion'], isNull);
      expect(sent['numero_documento'], '70123456');
    },
  );

  test(
    'la foto nueva se sube a su endpoint después de guardar los datos',
    () async {
      final photo = File(
        '${Directory.systemTemp.createTempSync('gymbros').path}/foto.png',
      )..writeAsBytesSync([137, 80, 78, 71]);
      final requests = <http.BaseRequest>[];
      final api = GymApi(
        mediaBaseUri: Uri.parse('http://192.168.1.56/'),
        client: MockClient.streaming((request, bodyStream) async {
          requests.add(request);
          await bodyStream.drain<void>();
          final body = request.url.path.endsWith('/foto-perfil')
              ? '{"foto_perfil":"usuario/nueva.png","foto_url":"http://192.168.1.56/storage/usuario/nueva.png"}'
              : '{"id_usuario":1,"nombre":"Juan"}';
          return http.StreamedResponse(Stream.value(utf8.encode(body)), 200);
        }),
      );
      final baseUser = (await _testGymApi().fetchUserData(
        'juan.perez@gmail.com',
      )).user;

      final saved = await api.updateUserData(
        baseUser,
        localPhotoPath: photo.path,
      );

      // Antes el archivo viajaba dentro del PUT, la API lo ignoraba y la app
      // mostraba la foto local como si estuviera guardada.
      expect(requests.map((r) => '${r.method} ${r.url.path}'), [
        'PUT /api/usuarios/1',
        'POST /api/usuarios/1/foto-perfil',
      ]);
      expect(requests.first.headers['content-type'], 'application/json');
      expect(requests.last, isA<http.MultipartRequest>());
      expect(
        saved.profilePhotoUrl,
        'http://192.168.1.56/storage/usuario/nueva.png',
      );
    },
  );

  test('un 422 al guardar muestra el detalle de cada campo', () async {
    final api = GymApi(
      client: MockClient(
        (request) async => http.Response(
          '{"message":"Revisa los datos.","errors":{"telefono":["Máximo 12 caracteres."]}}',
          422,
          headers: {'content-type': 'application/json; charset=utf-8'},
        ),
      ),
    );
    final baseUser = (await _testGymApi().fetchUserData('juan.perez@gmail.com'))
        .user;

    await expectLater(
      api.updateUserData(baseUser),
      throwsA(
        isA<GymApiException>()
            .having((e) => e.statusCode, 'statusCode', 422)
            .having(
              (e) => e.message,
              'message',
              contains('telefono: Máximo 12 caracteres.'),
            ),
      ),
    );
  });
}

GymApi _testGymApi() {
  return GymApi(
    mediaBaseUri: Uri.parse('http://192.168.1.56/'),
    client: MockClient((request) async {
      final scopedUser = request.url.path == '/api/auth/me';
      final scopedCompany = request.url.path == '/api/empresas/1';
      final path = scopedUser
          ? 'usuarios'
          : scopedCompany
          ? 'empresas'
          : request.url.pathSegments.last;
      if (path == 'peso-grasa') {
        expect(request.url.path, '/api/usuarios/1/evaluaciones/peso-grasa');
      }
      final body = switch (path) {
        'usuarios' => '{"data":[{"id":1,"nombres":"Juan","apellidos":"Perez Ramirez","correo":"juan.perez@gmail.com","tipo_documento":"DNI","numero_documento":"70123456","telefono":"987654321","direccion":"Jr. Los Pinos 123","foto_perfil":"gym-bros\\\\storage\\\\app\\\\public\\\\usuario\\\\prueba_gym.webp","fecha_registro":"2026-01-10","fecha_nacimiento":"1998-05-15","asistencia_semanal":"2026-08-24 08:30:00","tipo_usuario":"Usuario","estado":1,"id_empresas":1,"apodo":"bro"}]}',
        'empresas' => '{"data":[{"id":1,"nombre":"titan gym","nombre_gerente":"Carlos Mendoza","region":"Cajamarca","direccion":"Av. Hoyos Rubio 123","telefono":"976123456","correo":"contacto@gymbros.pe","enlace_web":"https://gymbros.pe","logo":"gym-bros\\\\storage\\\\app\\\\public\\\\empresas\\\\titan_gym.webp","horario_inicio_lunes":"6.00","horario_fin_lunes":"22.00","estado":1,"color_1":"#2563EB","color_2":"#111827"}]}',
        'rutinas' => '{"data":[{"id":1,"nombre":"Rutina Inicial","descripcion":"Rutina general","objetivo":"perdida_peso","dias_semana":4,"duracion_estimada":60,"fecha_inicio":"2026-08-01","fecha_fin":"2026-09-01","estado":1,"id_usuarios":1}]}',
        'progresos' => '{"data":[{"id":1,"fecha":"2026-08-01","peso":"82.50","altura":"1.75","porcentaje_grasa":"25.40","masa_muscular":"35.20","cintura":"94.00","pecho":"102.00","brazo":"34.00","muslo":"57.00","cadera":"98.00","notas":"Medición inicial","id_usuarios":1}]}',
        'peso-grasa' => '{"data":{"id_usuarios":1,"id_evaluacion":8,"fecha_evaluacion":"2026-09-02","peso":78.5,"porcentaje_grasa":18.2}}',
        'notificaciones' => '{"data":[{"id":1,"tipo":"rutina","titulo":"Nueva rutina","mensaje":"Disponible","fecha_envio":"2026-08-25 08:00:00","leida":0,"id_usuarios":1}]}',
        'sensaciones' => '{"data":[{"id":1,"fecha":"2026-08-01","energia":8,"dificultad":5,"fatiga":4,"dolor":1,"comentario":"Buena energía","id_usuarios":1,"id_rutinas":1}]}',
        _ => '{"data":[]}',
      };
      if (scopedUser || scopedCompany) {
        return http.Response(
          jsonEncode({'data': (jsonDecode(body)['data'] as List).first}),
          200,
        );
      }
      return http.Response(body, 200);
    }),
  );
}
