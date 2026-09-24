import 'gym_session.dart';

class RoutineSession {
  const RoutineSession({
    required this.userId,
    required this.routineId,
    required this.day,
    required this.daysPerWeek,
    required this.minutes,
    required this.goal,
    required this.exercises,
  });

  final int userId, routineId, day, daysPerWeek, minutes;
  final String goal;
  final List<SessionExercise> exercises;

  factory RoutineSession.fromJson(Map<String, dynamic> json, Uri mediaBaseUri) {
    final items = json['ejercicios'];
    if (items is! List) {
      throw const FormatException('Faltan los ejercicios de la sesión.');
    }
    final exercises =
        items.map((item) {
          if (item is! Map<String, dynamic>) {
            throw const FormatException('Ejercicio inválido.');
          }
          return SessionExercise.fromJson(item, mediaBaseUri);
        }).toList()..sort((a, b) {
          final order = a.order.compareTo(b.order);
          return order == 0 ? a.id.compareTo(b.id) : order;
        });
    return RoutineSession(
      userId: _id(json['id_usuarios']),
      routineId: _id(json['id_rutinas']),
      day: _id(json['dia']),
      daysPerWeek: _id(json['dias_semana']),
      minutes: _number(json['duracion_estimada']),
      goal: _text(json['objetivo']),
      exercises: List.unmodifiable(exercises),
    );
  }
}

class SessionExercise {
  const SessionExercise({
    required this.id,
    required this.order,
    required this.name,
    required this.series,
    required this.repetitions,
    required this.weight,
    required this.restSeconds,
    required this.timeSeconds,
    required this.notes,
    required this.description,
    required this.instructions,
    required this.level,
    required this.equipment,
    required this.type,
    required this.muscle,
    required this.muscleDescription,
    required this.imageUrl,
    required this.videoUrl,
  });

  final int id, order;
  final String name, series, repetitions, weight, restSeconds, timeSeconds;
  final String notes, description, instructions, level, equipment, type;
  final String muscle, muscleDescription, imageUrl, videoUrl;

  factory SessionExercise.fromJson(Map<String, dynamic> json, Uri base) {
    final exercise = json['ejercicio'];
    if (exercise is! Map<String, dynamic>) {
      throw const FormatException('Falta el detalle del ejercicio.');
    }
    final group = exercise['grupomuscular'];
    return SessionExercise(
      id: _id(json['id']),
      order: _number(json['orden']),
      name: _text(exercise['nombre']),
      series: _text(json['series']),
      repetitions: _text(json['repeticiones']),
      weight: _text(json['peso']),
      restSeconds: _text(json['descanso_segundos']),
      timeSeconds: _text(json['tiempo_segundos']),
      notes: _text(json['notas']),
      description: _text(exercise['descripcion']),
      instructions: _text(exercise['instrucciones']),
      level: _text(exercise['nivel']),
      equipment: _text(exercise['equipamiento']),
      type: _text(exercise['tipo']),
      muscle: group is Map ? _text(group['tipo']) : '',
      muscleDescription: group is Map ? _text(group['descripcion']) : '',
      // `imagen_url` es la URL pública que arma la API; la ruta cruda queda
      // como respaldo para respuestas antiguas.
      imageUrl: GymUser.resolveMediaUrl(
        exercise['imagen_url'] ?? exercise['imagen_ejercicio'],
        base,
      ),
      videoUrl: _text(exercise['enlace_video']),
    );
  }
}

String _text(Object? value) => value?.toString().trim() ?? '';
int _number(Object? value) => int.tryParse(_text(value)) ?? 0;
int _id(Object? value) {
  final result = _number(value);
  if (result < 1) {
    throw const FormatException('Identificador de sesión inválido.');
  }
  return result;
}
