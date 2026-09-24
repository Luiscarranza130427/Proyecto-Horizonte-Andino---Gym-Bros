import 'package:flutter_test/flutter_test.dart';
import 'package:gym_bros/models/gym_session.dart';

void main() {
  test('elige el banner por objetivo y codifica los espacios de la ruta', () {
    final cases = {
      'perdida_peso': 'rutina-de-perdida-de-peso.webp',
      'ganancia_muscular': 'rutina-de-ganancia-muscular.webp',
      'recomposicion': 'rutina-de-recomposicion-fisica.webp',
      'aumento fuerza': 'rutina-de-fuerza.webp',
      ' AUMENTO_FUERZA ': 'rutina-de-fuerza.webp',
      'hipertrofia': 'rutina-de-hipertrofia.webp',
      'salud': 'rutina%20de%20salud.webp',
      'resistencia': 'rutina%20de%20salud.webp',
      '': 'rutina%20de%20salud.webp',
    };
    for (final entry in cases.entries) {
      final routine = GymRoutine.fromJson({
        'id': 1,
        'id_usuarios': 7,
        'objetivo': entry.key,
      });
      expect(routine.bannerImagePath, 'storage/panel_rutinas/${entry.value}');
    }
  });
}
