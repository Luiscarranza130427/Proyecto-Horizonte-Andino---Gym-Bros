import 'gym_company.dart';

class GymSessionData {
  const GymSessionData({
    required this.user,
    required this.company,
    required this.routines,
    required this.progress,
    required this.notifications,
    required this.sensations,
    this.weightFatEvaluation,
    this.trainingProfile,
  });

  final GymUser user;
  final GymCompany company;
  final List<GymRoutine> routines;
  final List<GymProgress> progress;
  final List<GymNotification> notifications;
  final List<GymSensation> sensations;
  final GymWeightFatEvaluation? weightFatEvaluation;
  final GymTrainingProfile? trainingProfile;

  GymSessionData copyWith({
    GymUser? user,
    GymCompany? company,
    List<GymRoutine>? routines,
    List<GymProgress>? progress,
    List<GymNotification>? notifications,
    List<GymSensation>? sensations,
    GymWeightFatEvaluation? weightFatEvaluation,
    GymTrainingProfile? trainingProfile,
  }) {
    return GymSessionData(
      user: user ?? this.user,
      company: company ?? this.company,
      routines: routines ?? this.routines,
      progress: progress ?? this.progress,
      notifications: notifications ?? this.notifications,
      sensations: sensations ?? this.sensations,
      weightFatEvaluation: weightFatEvaluation ?? this.weightFatEvaluation,
      trainingProfile: trainingProfile ?? this.trainingProfile,
    );
  }
}

class GymTrainingProfile {
  const GymTrainingProfile({
    required this.userId,
    required this.evaluationId,
    required this.date,
    required this.goal,
    required this.experience,
    required this.dailyActivity,
    required this.daysPerWeek,
    required this.availableDays,
    required this.minutesPerSession,
    required this.restrictions,
  });

  final int userId, evaluationId, daysPerWeek, minutesPerSession;
  final String date, goal, experience, dailyActivity, restrictions;
  final List<String> availableDays;

  factory GymTrainingProfile.fromJson(Map<String, dynamic> json) {
    final rawDays = json['eleccion_dias'];
    return GymTrainingProfile(
      userId: _requiredId(json['id_usuarios'], 'usuario del perfil'),
      evaluationId: _requiredId(json['id_evaluacion'], 'evaluación del perfil'),
      date: _text(json['fecha_evaluacion']),
      goal: _text(json['objetivo']),
      experience: _text(json['nivel_experiencia']),
      dailyActivity: _text(json['actividad_diaria']),
      daysPerWeek: _integer(json['dias_semana']),
      availableDays: rawDays is List
          ? rawDays
                .map(_text)
                .where((day) => day.isNotEmpty)
                .toList(growable: false)
          : const [],
      minutesPerSession: _integer(json['tiempo_sesion_min']),
      restrictions: _text(json['restricciones']),
    );
  }
}

class GymWeightFatEvaluation {
  const GymWeightFatEvaluation({
    required this.userId,
    required this.evaluationId,
    required this.date,
    required this.weight,
    required this.bodyFat,
  });

  final int userId;
  final int evaluationId;
  final String date;
  final double weight;
  final double bodyFat;

  factory GymWeightFatEvaluation.fromJson(Map<String, dynamic> json) {
    return GymWeightFatEvaluation(
      userId: _requiredId(json['id_usuarios'], 'usuario de la evaluación'),
      evaluationId: _requiredId(json['id_evaluacion'], 'evaluación'),
      date: _text(json['fecha_evaluacion']),
      weight: _decimal(json['peso']),
      bodyFat: _decimal(json['porcentaje_grasa']),
    );
  }
}

class GymUser {
  const GymUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.documentType,
    required this.documentNumber,
    required this.phone,
    required this.address,
    required this.registrationDate,
    required this.birthDate,
    required this.weeklyAttendance,
    required this.userType,
    required this.companyId,
    this.nickname = '',
    this.profilePhotoUrl = '',
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String documentType;
  final String documentNumber;
  final String phone;
  final String address;
  final String registrationDate;
  final String birthDate;
  final String weeklyAttendance;
  final String userType;
  final int companyId;
  final String nickname;
  final String profilePhotoUrl;

  GymUser copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? documentType,
    String? documentNumber,
    String? phone,
    String? address,
    String? registrationDate,
    String? birthDate,
    String? weeklyAttendance,
    String? userType,
    int? companyId,
    String? nickname,
    String? profilePhotoUrl,
  }) {
    return GymUser(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      registrationDate: registrationDate ?? this.registrationDate,
      birthDate: birthDate ?? this.birthDate,
      weeklyAttendance: weeklyAttendance ?? this.weeklyAttendance,
      userType: userType ?? this.userType,
      companyId: companyId ?? this.companyId,
      nickname: nickname ?? this.nickname,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombres': firstName,
      'apellidos': lastName,
      'correo': email,
      'tipo_documento': documentType,
      'numero_documento': documentNumber,
      'telefono': phone,
      'direccion': address,
      'fecha_registro': registrationDate,
      'fecha_nacimiento': birthDate,
      'asistencia_semanal': weeklyAttendance,
      'tipo_usuario': userType,
      'id_empresas': companyId,
      'apodo': nickname,
      'foto_perfil': profilePhotoUrl,
    };
  }

  String get fullName {
    final value = '$firstName $lastName'.trim();
    return value.isEmpty ? email : value;
  }

  MembershipStatus membershipStatus(DateTime today) {
    final registeredAt = DateTime.tryParse(registrationDate);
    if (registeredAt == null || registeredAt.isAfter(today)) {
      return const MembershipStatus(
        title: 'NUEVO MIEMBRO',
        message: 'Tu historia en el gym comienza hoy.',
      );
    }

    var months =
        (today.year - registeredAt.year) * 12 +
        today.month -
        registeredAt.month;
    if (today.day < registeredAt.day) months--;

    return switch (months) {
      < 1 => const MembershipStatus(
        title: 'RECLUTA DE HIERRO',
        message: 'Cada leyenda comienza con su primera repetición.',
      ),
      < 3 => const MembershipStatus(
        title: 'PROMESA DEL GYM',
        message: 'La disciplina ya empieza a marcar tu camino.',
      ),
      < 6 => const MembershipStatus(
        title: 'GUERRERO CONSTANTE',
        message: 'Tu constancia pesa más que cualquier excusa.',
      ),
      < 12 => const MembershipStatus(
        title: 'MIEMBRO DE ÉLITE',
        message: 'La disciplina ya forma parte de ti.',
      ),
      < 24 => const MembershipStatus(
        title: 'VETERANO DE ACERO',
        message: 'Un año de esfuerzo habla por sí solo.',
      ),
      < 36 => const MembershipStatus(
        title: 'MAESTRO DE LA DISCIPLINA',
        message: 'Tu ejemplo inspira a quienes recién comienzan.',
      ),
      < 60 => const MembershipStatus(
        title: 'LEYENDA DEL GYM',
        message: 'Años de constancia construyeron tu legado.',
      ),
      _ => const MembershipStatus(
        title: 'TITÁN ETERNO',
        message: 'Tu legado ya es parte de la historia del gym.',
      ),
    };
  }

  factory GymUser.fromJson(
    Map<String, dynamic> json, {
    required Uri mediaBaseUri,
  }) {
    return GymUser(
      id: _requiredId(json['id'], 'usuario'),
      firstName: _text(json['nombres'] ?? json['nombre']),
      lastName: _text(json['apellidos']),
      email: _text(json['correo']),
      documentType: _text(json['tipo_documento']),
      documentNumber: _text(json['numero_documento']),
      phone: _text(json['telefono']),
      address: _text(json['direccion']),
      registrationDate: _text(json['fecha_registro']),
      birthDate: _text(json['fecha_nacimiento']),
      weeklyAttendance: _text(json['asistencia_semanal']),
      userType: _text(json['tipo_usuario']),
      companyId: _requiredId(json['id_empresas'], 'empresa del usuario'),
      nickname: _text(json['apodo']),
      profilePhotoUrl: _resolveMediaUrl(json['foto_perfil'], mediaBaseUri),
    );
  }

  static String resolveMediaUrl(Object? value, Uri baseUri) =>
      _resolveMediaUrl(value, baseUri);
}

class MembershipStatus {
  const MembershipStatus({required this.title, required this.message});

  final String title;
  final String message;
}

String _resolveMediaUrl(Object? value, Uri baseUri) {
  var raw = _text(value).replaceAll('\\', '/').trim();
  if (raw.isEmpty) return '';
  final parsed = Uri.tryParse(raw);
  if (parsed != null && parsed.hasScheme) return parsed.toString();

  if (raw.endsWith('.web')) {
    raw = '${raw}p';
  }

  final storageAppPublicIndex = raw.indexOf('storage/app/public/');
  if (storageAppPublicIndex != -1) {
    raw =
        'storage/${raw.substring(storageAppPublicIndex + 'storage/app/public/'.length)}';
  } else {
    final storageIndex = raw.indexOf('/storage/');
    if (storageIndex != -1) {
      raw = raw.substring(storageIndex + 1);
    } else if (!raw.startsWith('storage/')) {
      if (raw.startsWith('usuario/') ||
          raw.startsWith('usuarios/') ||
          raw.startsWith('empresas/') ||
          raw.startsWith('logos/') ||
          raw.startsWith('banners/')) {
        raw = 'storage/$raw';
      }
    }
  }

  while (raw.startsWith('/')) {
    raw = raw.substring(1);
  }

  return baseUri.resolve(raw).toString();
}

class GymRoutine {
  const GymRoutine({
    required this.id,
    required this.name,
    required this.description,
    required this.goal,
    required this.daysPerWeek,
    required this.estimatedMinutes,
    required this.startDate,
    required this.endDate,
    required this.active,
    required this.userId,
  });

  final int id;
  final String name;
  final String description;
  final String goal;

  String get bannerImagePath {
    final normalized = goal.trim().toLowerCase().replaceAll(
      RegExp(r'[\s-]+'),
      '_',
    );
    final filename = switch (normalized) {
      'perdida_peso' => 'rutina-de-perdida-de-peso.webp',
      'ganancia_muscular' => 'rutina-de-ganancia-muscular.webp',
      'recomposicion' => 'rutina-de-recomposicion-fisica.webp',
      'aumento_fuerza' => 'rutina-de-fuerza.webp',
      'hipertrofia' => 'rutina-de-hipertrofia.webp',
      'resistencia' || 'salud' => 'rutina de salud.webp',
      _ => 'rutina de salud.webp',
    };
    return 'storage/panel_rutinas/${Uri.encodeComponent(filename)}';
  }

  final int daysPerWeek;
  final int estimatedMinutes;
  final String startDate;
  final String endDate;
  final bool active;
  final int userId;

  factory GymRoutine.fromJson(Map<String, dynamic> json) {
    return GymRoutine(
      id: _requiredId(json['id'], 'rutina'),
      name: _text(json['nombre']),
      description: _text(json['descripcion']),
      goal: _text(json['objetivo']),
      daysPerWeek: _integer(json['dias_semana']),
      estimatedMinutes: _integer(json['duracion_estimada']),
      startDate: _text(json['fecha_inicio']),
      endDate: _text(json['fecha_fin']),
      active: _boolean(json['estado']),
      userId: _requiredId(json['id_usuarios'], 'usuario de la rutina'),
    );
  }
}

class GymProgress {
  const GymProgress({
    this.isEvaluation = false,
    required this.id,
    required this.date,
    required this.weight,
    required this.height,
    required this.bodyFat,
    required this.muscleMass,
    required this.waist,
    required this.chest,
    required this.arm,
    required this.thigh,
    required this.hip,
    required this.notes,
    required this.userId,
  });

  final int id;
  final String date;
  final double weight;
  final double height;
  final double bodyFat;
  final double muscleMass;
  final double waist;
  final double chest;
  final double arm;
  final double thigh;
  final double hip;
  final bool isEvaluation;
  final String notes;
  final int userId;

  factory GymProgress.fromJson(Map<String, dynamic> json) {
    return GymProgress(
      isEvaluation: json.containsKey('fecha_evaluacion'),
      id: _requiredId(json['id'], 'progreso'),
      date: _text(json['fecha_evaluacion'] ?? json['fecha']),
      weight: _decimal(json['peso']),
      height: _decimal(json['altura']),
      bodyFat: _decimal(json['porcentaje_grasa']),
      muscleMass: _decimal(json['masa_muscular']),
      waist: _decimal(json['cintura']),
      chest: _decimal(json['pecho']),
      arm: _decimal(json['brazo']),
      thigh: _decimal(json['muslo']),
      hip: _decimal(json['cadera']),
      notes: _text(json['notas']),
      userId: _requiredId(json['id_usuarios'], 'usuario del progreso'),
    );
  }
}

class GymNotification {
  const GymNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.read,
    required this.userId,
  });

  final int id;
  final String type;
  final String title;
  final String message;
  final String sentAt;
  final bool read;
  final int userId;

  factory GymNotification.fromJson(Map<String, dynamic> json) {
    return GymNotification(
      id: _requiredId(json['id'], 'notificación'),
      type: _text(json['tipo']),
      title: _text(json['titulo']),
      message: _text(json['mensaje']),
      sentAt: _text(json['fecha_envio']),
      read: _boolean(json['leida']),
      userId: _requiredId(json['id_usuarios'], 'usuario de la notificación'),
    );
  }
}

class GymSensation {
  const GymSensation({
    required this.id,
    required this.date,
    required this.energy,
    required this.difficulty,
    required this.fatigue,
    required this.pain,
    required this.comment,
    required this.userId,
    required this.routineId,
  });

  final int id;
  final String date;
  final int energy;
  final int difficulty;
  final int fatigue;
  final int pain;
  final String comment;
  final int userId;
  final int routineId;

  factory GymSensation.fromJson(Map<String, dynamic> json) {
    return GymSensation(
      id: _requiredId(json['id'], 'sensación'),
      date: _text(json['fecha']),
      energy: _integer(json['energia']),
      difficulty: _integer(json['dificultad']),
      fatigue: _integer(json['fatiga']),
      pain: _integer(json['dolor']),
      comment: _text(json['comentario']),
      userId: _requiredId(json['id_usuarios'], 'usuario de la sensación'),
      routineId: _requiredId(json['id_rutinas'], 'rutina de la sensación'),
    );
  }
}

String _text(Object? value) => value?.toString().trim() ?? '';

int _requiredId(Object? value, String field) {
  final id = value is num ? value.toInt() : int.tryParse(_text(value));
  if (id == null) throw FormatException('Falta el identificador de $field.');
  return id;
}

int _integer(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(_text(value)) ?? 0;
}

double _decimal(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(_text(value)) ?? 0;
}

bool _boolean(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return const {'1', 'true', 'activo'}.contains(_text(value).toLowerCase());
}
