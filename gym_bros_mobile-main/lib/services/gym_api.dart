import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/gym_company.dart';
import '../models/gym_session.dart';
import '../models/routine_session.dart';
import '../models/nutrition_plan.dart';
import 'api_environment.dart';

part 'nutrition_api.dart';

class GymApi {
  GymApi({
    http.Client? client,
    Uri? apiBaseUri,
    Uri? mediaBaseUri,
    FlutterSecureStorage? secureStorage,
  }) : _client = client ?? http.Client(),
       apiBaseUri = apiBaseUri ?? ApiEnvironment.server.resolve('api/'),
       mediaBaseUri = mediaBaseUri ?? ApiEnvironment.server,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final http.Client _client;
  final Uri apiBaseUri;
  final Uri mediaBaseUri;
  final FlutterSecureStorage _secureStorage;
  String? _authToken;

  Future<void> login({required String email, required String password}) async {
    final request = http.Request('POST', apiBaseUri.resolve('auth/login'))
      ..headers.addAll(_headers(json: true))
      ..body = jsonEncode({'correo': email.trim(), 'password': password});
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      final body = _decodeJsonObject(response.bodyBytes);
      if (response.statusCode == 401) await clearAuthToken();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GymApiException(
          _apiErrorMessage(
            body,
            response.statusCode,
            fallback: 'No se pudo iniciar sesión.',
          ),
          statusCode: response.statusCode,
        );
      }
      final data = body?['data'];
      final token = data is Map ? data['token']?.toString() : null;
      if (token == null || token.trim().isEmpty) {
        throw const GymApiException(
          'La respuesta de inicio de sesión no es válida.',
        );
      }
      _authToken = token;
      await _secureStorage.write(key: 'auth_token', value: token);
    } on GymApiException {
      rethrow;
    } on TimeoutException {
      throw const GymApiException('El inicio de sesión tardó demasiado.');
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo conectar con el servidor. Revisa la red Wi-Fi.',
      );
    } on http.ClientException {
      throw const GymApiException('No se pudo conectar con el servidor.');
    } on FormatException {
      throw const GymApiException(
        'El servidor no devolvió una respuesta válida.',
      );
    }
  }

  /// Solicita al backend un enlace de recuperación. El backend mantiene una
  /// respuesta genérica para no revelar si el correo está registrado.
  Future<String> forgotPassword(String email) async {
    final request =
        http.Request('POST', apiBaseUri.resolve('auth/forgot-password'))
          ..headers.addAll(const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({'correo': email.trim()});

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      final body = _decodeJsonObject(response.bodyBytes);
      if (response.statusCode == 401) {
        await clearAuthToken();
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GymApiException(
          _apiErrorMessage(
            body,
            response.statusCode,
            fallback: 'No se pudo solicitar la recuperación de contraseña.',
          ),
          statusCode: response.statusCode,
        );
      }
      final message = body?['message']?.toString().trim();
      if (message == null || message.isEmpty) {
        throw const GymApiException(
          'La solicitud fue recibida. Revisa tu correo para continuar.',
        );
      }
      return message;
    } on GymApiException {
      rethrow;
    } on TimeoutException {
      throw const GymApiException(
        'La solicitud tardó demasiado. Inténtalo nuevamente.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo conectar con el servidor. Revisa tu conexión Wi-Fi.',
      );
    } on http.ClientException {
      throw const GymApiException('No se pudo conectar con el servidor.');
    } on FormatException {
      throw const GymApiException(
        'El servidor no devolvió una respuesta válida.',
      );
    }
  }

  Future<void> clearAuthToken() async {
    _authToken = null;
    await _secureStorage.delete(key: 'auth_token');
  }

  Map<String, String> _headers({bool json = false}) => {
    'Accept': 'application/json',
    if (json) 'Content-Type': 'application/json',
    if (_authToken != null && _authToken!.isNotEmpty)
      'Authorization': 'Bearer $_authToken',
  };

  Map<String, dynamic>? _decodeJsonObject(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  String _apiErrorMessage(
    Map<String, dynamic>? body,
    int statusCode, {
    required String fallback,
  }) {
    final message = body?['message']?.toString().trim();
    final errors = body?['errors'];
    final details = errors is Map
        ? errors.entries
              .map(
                (entry) =>
                    '${entry.key}: ${entry.value is List ? (entry.value as List).join(' ') : entry.value}',
              )
              .join('\n')
        : '';
    if (message != null && message.isNotEmpty) {
      return details.isEmpty ? message : '$message\n$details';
    }
    switch (statusCode) {
      case 422:
        return details.isEmpty ? 'Revisa los datos ingresados.' : details;
      case 429:
        return 'Demasiadas solicitudes. Espera unos minutos e inténtalo nuevamente.';
      case 503:
        return 'El servicio no está disponible temporalmente. Inténtalo más tarde.';
      default:
        return fallback;
    }
  }

  Future<Map<String, dynamic>> routineGenerationStatus(int userId) async {
    return _generationRequest(userId, generate: false);
  }

  Future<GymRoutine> generateRoutine(int userId) async {
    final data = await _generationRequest(userId, generate: true);
    final routine = GymRoutine.fromJson(data);
    if (routine.userId != userId) {
      throw const GymApiException(
        'La rutina recibida no pertenece al usuario.',
      );
    }
    return routine;
  }

  Future<Map<String, dynamic>> _generationRequest(
    int userId, {
    required bool generate,
  }) async {
    try {
      final request = http.Request(
        generate ? 'POST' : 'GET',
        apiBaseUri.resolve(
          'rutinas/generar/$userId${generate ? '' : '/estado'}',
        ),
      )..headers['Accept'] = 'application/json';
      if (generate) {
        request.headers['Content-Type'] = 'application/json';
        request.body = '{}';
      }
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 60));
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GymApiException(
          body is Map
              ? '${body['message'] ?? 'No se pudo generar la rutina.'}'
              : 'No se pudo generar la rutina.',
        );
      }
      if (body is! Map<String, dynamic> ||
          body['data'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      return body['data'] as Map<String, dynamic>;
    } on GymApiException {
      rethrow;
    } on Exception {
      throw const GymApiException(
        'No se pudo confirmar la operación. Revisa tu conexión y consulta Rutinas antes de volver a generar.',
      );
    }
  }

  Future<GymProgress> createEvaluation({
    required int userId,
    required Map<String, dynamic> values,
  }) async => GymProgress.fromJson(
    await _saveEvaluation(userId: userId, values: values),
  );

  Future<Map<String, dynamic>> updateLatestEvaluation({
    required int userId,
    required Map<String, dynamic> values,
  }) => _saveEvaluation(userId: userId, values: values, editing: true);

  Future<Map<String, dynamic>> fetchLatestEvaluation(int userId) async {
    final profile = await _getTrainingProfile(userId);
    if (profile == null) {
      throw const GymApiException(
        'Todavía no tienes una evaluación física registrada.',
      );
    }
    // The scoped profile identifies the latest evaluation. The existing index
    // provides its complete measurements; progress records belong to another table.
    final evaluations = await _getDataList('evaluacionesfisicas');
    final data = _findFirst(
      evaluations,
      (item) => _id(item['id']) == profile.evaluationId,
    );
    if (data == null ||
        (data['id_usuarios'] != null && _id(data['id_usuarios']) != userId)) {
      throw const GymApiException(
        'No se encontraron las medidas de tu última evaluación.',
      );
    }
    return {...data, 'id_usuarios': userId};
  }

  Future<Map<String, dynamic>> _saveEvaluation({
    required int userId,
    required Map<String, dynamic> values,
    bool editing = false,
  }) async {
    final uri = apiBaseUri.resolve(
      'usuarios/$userId/evaluaciones${editing ? '/ultima' : ''}',
    );
    try {
      final request = http.Request(editing ? 'PUT' : 'POST', uri)
        ..headers.addAll(const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        })
        ..body = jsonEncode(values);
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 && response.statusCode != 201) {
        var detail = '';
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            detail = ': ${decoded['message']}';
            final errors = decoded['errors'];
            if (errors is Map) {
              detail +=
                  '\n${errors.entries.map((entry) => '${entry.key}: ${(entry.value is List ? (entry.value as List).join(' ') : entry.value)}').join('\n')}';
            }
          }
        } on FormatException {
          detail = ': El servidor no devolvió detalles en formato JSON.';
        }
        throw GymApiException(
          'No se pudo ${editing ? 'actualizar' : 'registrar'} la evaluación (HTTP ${response.statusCode})$detail',
        );
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final data = decoded is Map<String, dynamic>
          ? (decoded['data'] is Map<String, dynamic>
                ? decoded['data'] as Map<String, dynamic>
                : decoded['evaluacion'] is Map<String, dynamic>
                ? decoded['evaluacion'] as Map<String, dynamic>
                : decoded)
          : null;
      if (data == null) throw const FormatException();
      final progress = GymProgress.fromJson(data);
      if (progress.userId != userId) throw const FormatException();
      return data;
    } on TimeoutException {
      throw const GymApiException(
        'El registro de medidas tardó demasiado en responder.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo alcanzar el servidor. Revisa tu conexión Wi-Fi.',
      );
    } on http.ClientException {
      throw const GymApiException('No se pudo conectar con el servidor.');
    } on FormatException {
      throw const GymApiException(
        'La respuesta del registro no tiene el formato esperado.',
      );
    }
  }

  Future<RoutineSession> fetchRoutineSession({
    required int userId,
    required int routineId,
    required int day,
  }) async {
    try {
      final response = await _client
          .get(
            apiBaseUri.resolve(
              'usuarios/$userId/rutinas/$routineId/sesiones/$day',
            ),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw GymApiException(
          response.statusCode == 404
              ? 'La sesión no está disponible o aún no tiene ejercicios asignados.'
              : 'No se pudo cargar la sesión (HTTP ${response.statusCode}).',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic> ||
          body['data'] is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final session = RoutineSession.fromJson(
        body['data'] as Map<String, dynamic>,
        mediaBaseUri,
      );
      if (session.userId != userId ||
          session.routineId != routineId ||
          session.day != day) {
        throw const FormatException(
          'La sesión recibida no corresponde a la solicitud.',
        );
      }
      return session;
    } on TimeoutException {
      throw const GymApiException(
        'La sesión tardó demasiado en cargar. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo alcanzar el servidor. Revisa tu conexión Wi-Fi.',
      );
    } on http.ClientException {
      throw const GymApiException(
        'No se pudo conectar con el servidor. Inténtalo de nuevo.',
      );
    } on FormatException {
      throw const GymApiException(
        'La respuesta de la sesión no tiene el formato esperado.',
      );
    }
  }

  Future<GymUser> uploadProfilePhoto({
    required GymUser user,
    required String localPhotoPath,
  }) async {
    if (kIsWeb) {
      throw const GymApiException(
        'La actualización de foto no está disponible en esta plataforma.',
      );
    }
    final file = io.File(localPhotoPath);
    if (!await file.exists()) {
      throw const GymApiException('No se encontró la imagen seleccionada.');
    }

    final request =
        http.MultipartRequest(
            'POST',
            apiBaseUri.resolve('usuarios/${user.id}/foto-perfil'),
          )
          ..headers['Accept'] = 'application/json'
          ..files.add(
            await http.MultipartFile.fromPath('foto_perfil', localPhotoPath),
          );

    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200 &&
          response.statusCode != 201 &&
          response.statusCode != 202) {
        var detail = '';
        try {
          final decoded = jsonDecode(utf8.decode(response.bodyBytes));
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            detail = ': ${decoded['message']}';
          }
        } catch (_) {}
        throw GymApiException(
          'No se pudo actualizar la foto (${response.statusCode})$detail',
        );
      }

      String? uploadedPhoto;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final candidates = <Object?>[
            decoded['usuario'],
            decoded['data'],
            decoded,
          ];
          for (final candidate in candidates) {
            if (candidate is Map<String, dynamic>) {
              final value =
                  candidate['foto_perfil'] ??
                  candidate['foto'] ??
                  candidate['url'] ??
                  candidate['ruta'];
              if (value != null && value.toString().trim().isNotEmpty) {
                uploadedPhoto = GymUser.resolveMediaUrl(value, mediaBaseUri);
                break;
              }
            }
          }
        }
      } catch (_) {}

      return user.copyWith(profilePhotoUrl: uploadedPhoto ?? localPhotoPath);
    } on GymApiException {
      rethrow;
    } on Exception catch (error) {
      throw GymApiException('No se pudo actualizar la foto: $error');
    }
  }

  Future<GymUser> updateUserData(GymUser user, {String? localPhotoPath}) async {
    final uri = apiBaseUri.resolve('usuarios/${user.id}');
    final fields = <String, String>{
      'nombres': user.firstName,
      'apellidos': user.lastName,
      'apodo': user.nickname,
      'correo': user.email,
      'telefono': user.phone,
      'direccion': user.address,
      'fecha_nacimiento': user.birthDate,
      'tipo_documento': user.documentType,
      'numero_documento': user.documentNumber,
    };
    final hasPhoto =
        !kIsWeb &&
        localPhotoPath != null &&
        localPhotoPath.isNotEmpty &&
        !localPhotoPath.startsWith('http') &&
        !localPhotoPath.startsWith('assets/');
    final request = hasPhoto
        ? http.MultipartRequest('POST', uri)
        : http.Request('PUT', uri);
    request.headers['Accept'] = 'application/json';
    if (request is http.MultipartRequest) {
      request.fields.addAll(fields);
      request.fields['_method'] = 'PUT';
      final file = io.File(localPhotoPath!);
      if (file.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('foto_perfil', localPhotoPath),
        );
      }
    } else {
      request.headers['Content-Type'] = 'application/json';
      (request as http.Request).body = jsonEncode(fields);
    }

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200 && response.statusCode != 201) {
        String detail = '';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic> && decoded['message'] != null) {
            detail = ': ${decoded['message']}';
          }
        } catch (_) {}
        throw GymApiException(
          'El servidor respondió con error (${response.statusCode})$detail',
        );
      }

      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        final userData = (body['usuario'] is Map<String, dynamic>)
            ? body['usuario'] as Map<String, dynamic>
            : (body['data'] is Map<String, dynamic>)
            ? body['data'] as Map<String, dynamic>
            : body;

        final rawPhoto = userData['foto_perfil'] ?? userData['foto'];
        final resolvedPhotoUrl =
            (rawPhoto != null && rawPhoto.toString().trim().isNotEmpty)
            ? GymUser.resolveMediaUrl(rawPhoto, mediaBaseUri)
            : ((localPhotoPath != null && localPhotoPath.isNotEmpty)
                  ? localPhotoPath
                  : user.profilePhotoUrl);

        return user.copyWith(
          firstName: userData['nombre'] != null
              ? _text(userData['nombre'])
              : (userData['nombres'] != null
                    ? _text(userData['nombres'])
                    : user.firstName),
          lastName: userData['apellidos'] != null
              ? _text(userData['apellidos'])
              : user.lastName,
          nickname: userData['apodo'] != null
              ? _text(userData['apodo'])
              : user.nickname,
          email: userData['correo'] != null
              ? _text(userData['correo'])
              : user.email,
          phone: userData['telefono'] != null
              ? _text(userData['telefono'])
              : user.phone,
          address: userData['direccion'] != null
              ? _text(userData['direccion'])
              : user.address,
          birthDate: userData['fecha_nacimiento'] != null
              ? _text(userData['fecha_nacimiento'])
              : user.birthDate,
          documentType: userData['tipo_documento'] != null
              ? _text(userData['tipo_documento'])
              : user.documentType,
          documentNumber: userData['numero_documento'] != null
              ? _text(userData['numero_documento'])
              : user.documentNumber,
          profilePhotoUrl: resolvedPhotoUrl,
        );
      }
      return user.copyWith(
        profilePhotoUrl: (localPhotoPath != null && localPhotoPath.isNotEmpty)
            ? localPhotoPath
            : user.profilePhotoUrl,
      );
    } on GymApiException {
      rethrow;
    } on Exception catch (error) {
      throw GymApiException('No se pudo conectar con el servidor: $error');
    }
  }

  Future<GymSessionData> fetchUserData(String emailOrDni) async {
    final users = await _getDataList('usuarios');
    final normalized = emailOrDni.trim().toLowerCase();
    final userJson = _findFirst(users, (item) {
      final email = _text(item['correo']).toLowerCase();
      final dni = _text(item['numero_documento']).toLowerCase();
      return email == normalized || dni == normalized;
    });

    if (userJson == null) {
      throw const GymApiException(
        'No encontramos un usuario vinculado con ese correo o DNI.',
      );
    }

    try {
      final user = GymUser.fromJson(userJson, mediaBaseUri: mediaBaseUri);
      final weightFatEvaluationFuture = _getWeightFatEvaluation(user.id);
      final trainingProfileFuture = _getTrainingProfile(user.id);
      final responses = await Future.wait([
        _getDataList('empresas'),
        _getDataList('rutinas'),
        _getDataList('progresos'),
        _getDataList('notificaciones'),
        _getDataList('sensaciones'),
      ]);

      final companyJson = _findFirst(
        responses[0],
        (item) => _id(item['id']) == user.companyId,
      );
      if (companyJson == null) {
        throw const GymApiException(
          'La empresa vinculada no está disponible en la API.',
        );
      }

      final routines =
          _related(
              responses[1],
              user.id,
            ).map(GymRoutine.fromJson).toList(growable: false)
            ..sort((a, b) => b.id.compareTo(a.id));
      final progress =
          _related(
              responses[2],
              user.id,
            ).map(GymProgress.fromJson).toList(growable: false)
            ..sort((a, b) => a.date.compareTo(b.date));
      final notifications =
          _related(
              responses[3],
              user.id,
            ).map(GymNotification.fromJson).toList(growable: false)
            ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      final sensations =
          _related(
              responses[4],
              user.id,
            ).map(GymSensation.fromJson).toList(growable: false)
            ..sort((a, b) => b.date.compareTo(a.date));
      final weightFatEvaluation = await weightFatEvaluationFuture;
      final trainingProfile = await trainingProfileFuture;

      return GymSessionData(
        user: user,
        company: GymCompany.fromJson(companyJson, mediaBaseUri: mediaBaseUri),
        routines: routines,
        progress: progress,
        notifications: notifications,
        sensations: sensations,
        weightFatEvaluation: weightFatEvaluation,
        trainingProfile: trainingProfile,
      );
    } on GymApiException {
      rethrow;
    } on FormatException catch (error) {
      throw GymApiException(error.message);
    }
  }

  Future<GymWeightFatEvaluation?> _getWeightFatEvaluation(int userId) async {
    try {
      final response = await _client
          .get(
            apiBaseUri.resolve('usuarios/$userId/evaluaciones/peso-grasa'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw GymApiException(
          'No se pudo cargar la evaluación de peso y grasa '
          '(HTTP ${response.statusCode}).',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      final data = body['data'];
      if (data == null || data is List && data.isEmpty) return null;
      if (data is! Map<String, dynamic>) throw const FormatException();
      final evaluation = GymWeightFatEvaluation.fromJson(data);
      if (evaluation.userId != userId) throw const FormatException();
      return evaluation;
    } on TimeoutException {
      throw const GymApiException(
        'La evaluación de peso y grasa tardó demasiado en responder.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo alcanzar la evaluación de peso y grasa.',
      );
    } on http.ClientException {
      throw const GymApiException(
        'No se pudo conectar con la evaluación de peso y grasa.',
      );
    } on FormatException {
      throw const GymApiException(
        'La evaluación de peso y grasa no tiene el formato esperado.',
      );
    }
  }

  Future<GymTrainingProfile?> _getTrainingProfile(int userId) async {
    try {
      final response = await _client
          .get(
            apiBaseUri.resolve('usuarios/$userId/evaluaciones/perfil'),
            headers: _headers(),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw GymApiException(
          'No se pudo cargar el perfil de entrenamiento (HTTP ${response.statusCode}).',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) throw const FormatException();
      final data = body['data'];
      if (data == null || data is List && data.isEmpty) return null;
      if (data is! Map<String, dynamic>) throw const FormatException();
      final profile = GymTrainingProfile.fromJson(data);
      if (profile.userId != userId) throw const FormatException();
      return profile;
    } on TimeoutException {
      throw const GymApiException(
        'El perfil de entrenamiento tardó demasiado en responder.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo alcanzar el perfil de entrenamiento.',
      );
    } on http.ClientException {
      throw const GymApiException(
        'No se pudo conectar con el perfil de entrenamiento.',
      );
    } on FormatException {
      throw const GymApiException(
        'El perfil de entrenamiento no tiene el formato esperado.',
      );
    }
  }

  List<Map<String, dynamic>> _related(List<dynamic> items, int userId) {
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => _id(item['id_usuarios']) == userId)
        .toList(growable: false);
  }

  Map<String, dynamic>? _findFirst(
    List<dynamic> items,
    bool Function(Map<String, dynamic>) matches,
  ) {
    for (final item in items.whereType<Map<String, dynamic>>()) {
      if (matches(item)) return item;
    }
    return null;
  }

  Future<List<dynamic>> _getDataList(String path) async {
    try {
      final response = await _client
          .get(apiBaseUri.resolve(path), headers: _headers())
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await clearAuthToken();
        }
        throw GymApiException(
          'La API respondió con el estado ${response.statusCode}.',
          statusCode: response.statusCode,
        );
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic> || body['data'] is! List) {
        throw const FormatException();
      }
      return body['data'] as List<dynamic>;
    } on TimeoutException {
      throw const GymApiException(
        'La API tardó demasiado en responder. Revisa la red Wi-Fi y el servidor.',
      );
    } on io.SocketException {
      throw const GymApiException(
        'No se pudo alcanzar la API. Revisa la IP configurada y la red Wi-Fi.',
      );
    } on http.ClientException {
      throw const GymApiException(
        'No se pudo conectar con la API. Revisa la red Wi-Fi y el servidor.',
      );
    } on FormatException {
      throw const GymApiException(
        'La respuesta de la API no tiene el formato esperado.',
      );
    }
  }

  int? _id(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(_text(value));
  }

  String _text(Object? value) => value?.toString().trim() ?? '';
}

class GymApiException implements Exception {
  const GymApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
