// Synthetic contract fixtures, exclusively for automated tests. Never imported by lib/.
Map<String, dynamic> nutrients({Object calories = '500.25'}) => {
  'calorias': calories,
  'proteinas': '25.50',
  'carbohidratos': 60,
  'grasas': 15.5,
  'fibra': 8,
};
Map<String, dynamic> planFixture({int user = 7, int id = 12}) => {
  'id': id,
  'id_usuarios': user,
  'id_evaluaciones_fisicas': 6,
  'nombre': 'Plan de prueba',
  'objetivo': 'salud',
  'fecha_inicio': '2026-09-11T00:00:00Z',
  'fecha_fin': '2026-09-12',
  'estado': true,
  'calculo': {
    'objetivos': {
      'calorias': '2000',
      'proteinas': 100,
      'carbohidratos': 250,
      'grasas': 70,
    },
  },
  'dias': [
    for (final day in [2, 1])
      {
        'dia': day,
        'fecha': '2026-09-${day == 1 ? '11' : '12'}',
        'totales': nutrients(calories: day * 500),
        'comidas': [
          for (final order in [2, 1])
            {
              'id': day * 10 + order,
              'nombre': 'Comida $day-$order',
              'tipo': order == 1 ? 'desayuno' : 'almuerzo',
              'orden': order,
              'hora_sugerida': order == 1 ? '08:00' : '13:00',
              'objetivos': nutrients(),
              'totales': nutrients(),
              'alimentos': [
                {
                  'id': 100 + day * 10 + order,
                  'id_alimentos': 90,
                  'cantidad': '150.75',
                  'unidad': 'gramos',
                  'notas': null,
                  'detalle_nutricional': {
                    'nombre': 'Alimento $day-$order',
                    'base_cantidad': 100,
                    'base_unidad': 'gramos',
                    'estado_preparacion': 'Cocido',
                    'fuente': 'Fuente de prueba',
                    'nutrientes': nutrients(),
                  },
                },
              ],
            },
        ],
      },
  ],
  'totales_plan': nutrients(calories: 9000),
  'advertencias': ['Advertencia de prueba'],
};
