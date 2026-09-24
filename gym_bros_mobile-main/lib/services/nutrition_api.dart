part of 'gym_api.dart';

class NutritionApiException implements Exception {
  const NutritionApiException(
    this.message, {
    this.status,
    this.errors = const {},
  });
  final String message;
  final int? status;
  final Map<String, List<String>> errors;
  @override
  String toString() => [
    message,
    ...errors.entries.expand((e) => e.value.map((v) => '${e.key}: $v')),
  ].join('\n');
}

extension NutritionApi on GymApi {
  Future<Json?> editableFoodProfile(int userId) async {
    try {
      final data = nutritionObject(
        await _nutritionRequest('usuarios/$userId/perfil-alimentario'),
      );
      if (nutritionId(data['id_usuarios']) != userId) {
        throw const NutritionApiException(
          'El perfil no corresponde al usuario actual.',
        );
      }
      return data;
    } on NutritionApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  /// Catálogo de alimentos para el perfil. La API ya no expone
  /// `restriccionesalimentarias` (las restricciones son preferencias por
  /// alimento), así que ambas variantes leen `alimentos`; antes `true`
  /// terminaba en un 404.
  Future<List<Json>> foodProfileCatalog({required bool restrictions}) =>
      _nutritionParse(
        () async => nutritionList(
          await _nutritionRequest('alimentos'),
          (j) => {
            'id': nutritionId(j['id']),
            'nombre': nutritionText(j['nombre']),
          },
        ),
      );

  Future<FoodProfile> saveFoodProfile(int userId, Json input) =>
      _nutritionParse(() async {
        final result = FoodProfile(
          nutritionObject(
            await _nutritionRequest(
              'usuarios/$userId/perfil-alimentario',
              body: input,
              method: 'PUT',
            ),
          ),
        );
        if (result.userId != userId) {
          throw const FormatException('Perfil ajeno.');
        }
        return result;
      });

  Future<List<NutritionSummary>> nutritionPlans(int userId) async {
    if (!ApiEnvironment.development) {
      throw const NutritionApiException(
        'La consulta del listado global está deshabilitada fuera del entorno de pruebas. Puedes consultar un plan por su ID o generar uno.',
      );
    }
    return _nutritionParse(
      () async => nutritionList(
        await _nutritionRequest('planesalimentacion'),
        NutritionSummary.new,
      ).where((p) => p.userId == userId).toList(),
    );
  }

  Future<NutritionPlan> nutritionPlan(int userId, int planId) =>
      _nutritionParse(() async {
        final plan = NutritionPlan(
          nutritionObject(
            await _nutritionRequest(
              'usuarios/$userId/planesalimentacion/$planId',
            ),
          ),
        );
        if (plan.userId != userId || plan.id != planId) {
          throw const FormatException('Plan ajeno a la solicitud.');
        }
        return plan;
      });

  Future<FoodProfile> foodProfile(int userId) => _nutritionParse(() async {
    final profile = FoodProfile(
      nutritionObject(
        await _nutritionRequest('usuarios/$userId/perfil-alimentario'),
      ),
    );
    if (profile.userId != userId) {
      throw const FormatException('Perfil ajeno a la solicitud.');
    }
    return profile;
  });

  Future<NutritionPlan> generateNutrition(
    int userId,
    NutritionGeneration input,
  ) => _nutritionParse(() async {
    final plan = NutritionPlan(
      nutritionObject(
        await _nutritionRequest(
          'planesalimentacion/generar/$userId',
          body: input.toJson(),
        ),
      ),
    );
    if (plan.userId != userId) {
      throw const FormatException('Plan ajeno a la solicitud.');
    }
    return plan;
  });

  Future<T> _nutritionParse<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FormatException {
      throw const NutritionApiException(
        'El servidor devolvió datos incompletos o inválidos del plan alimentario.',
      );
    } on TypeError {
      throw const NutritionApiException(
        'El servidor devolvió datos incompletos o inválidos del plan alimentario.',
      );
    }
  }

  Future<Object?> _nutritionRequest(
    String path, {
    Json? body,
    String? method,
  }) async {
    try {
      final request = http.Request(
        method ?? (body == null ? 'GET' : 'POST'),
        apiBaseUri.resolve(path),
      )..headers['Accept'] = 'application/json';
      _authorize(request);
      if (body != null) {
        request.headers['Content-Type'] = 'application/json';
        request.body = jsonEncode(body);
      }
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(Duration(seconds: body == null ? 15 : 60));
      Json? decoded;
      try {
        final value = jsonDecode(utf8.decode(response.bodyBytes));
        if (value is Json) decoded = value;
      } on FormatException {
        if (response.statusCode < 400) {
          throw const NutritionApiException(
            'Respuesta inválida del servidor alimentario.',
          );
        }
      }
      final status = response.statusCode;
      if (status == 401) await clearAuthToken();
      if (status != (body == null || method == 'PUT' ? 200 : 201)) {
        final fallback = switch (status) {
          401 => 'Tu sesión no está autorizada. Vuelve a iniciar sesión.',
          403 => 'No tienes permiso para consultar o modificar este recurso.',
          404 =>
            path.endsWith('perfil-alimentario')
                ? 'No hay perfil alimentario registrado para este usuario.'
                : 'El plan solicitado no está disponible para este usuario.',
          422 => 'Revisa los datos del formulario y del perfil alimentario.',
          503 => 'El módulo de alimentación no está disponible temporalmente.',
          >= 500 =>
            'El servidor tuvo un error interno al procesar alimentación.',
          _ =>
            'No se pudo completar la consulta de alimentación (HTTP $status).',
        };
        // Never expose Laravel debug exceptions, HTML or stack traces.
        String? safe(Object? value) {
          if (value is! String ||
              value.contains('<') ||
              value.contains('\\') ||
              value.length > 1200) {
            return null;
          }
          return value.trim().isEmpty ? null : value;
        }

        final errors = <String, List<String>>{};
        if (status == 422 && decoded?['errors'] is Map) {
          for (final entry in (decoded!['errors'] as Map).entries) {
            final values = entry.value is List
                ? entry.value as List
                : [entry.value];
            errors[entry.key.toString()] = values
                .map(safe)
                .whereType<String>()
                .toList();
          }
        }
        throw NutritionApiException(
          status >= 500 && status != 503
              ? fallback
              : safe(decoded?['message']) ?? fallback,
          status: status,
          errors: errors,
        );
      }
      if (decoded == null || !decoded.containsKey('data')) {
        throw const NutritionApiException(
          'La respuesta alimentaria no contiene data.',
        );
      }
      return decoded['data'];
    } on TimeoutException {
      throw NutritionApiException(
        body == null
            ? 'La consulta tardó demasiado. Puedes reintentar.'
            : method == 'PUT'
            ? 'No se pudo confirmar el guardado. Consulta tu perfil antes de volver a guardar.'
            : 'No se pudo confirmar la generación por tiempo de espera. Consulta tus planes antes de volver a generar para evitar duplicados.',
      );
    } on io.SocketException {
      throw const NutritionApiException(
        'No se pudo conectar con el servidor. Revisa tu red Wi-Fi.',
      );
    } on http.ClientException {
      throw const NutritionApiException(
        'Se interrumpió la conexión. Consulta tus planes antes de repetir una generación.',
      );
    }
  }
}
