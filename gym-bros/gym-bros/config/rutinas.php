<?php

return [
    // Initial technical presets. Review with the gym's trainer before use with clients.
    'vigencia_semanas' => 4,
    'minutos_maximos' => 180,
    'calentamiento_segundos' => 300,
    'transicion_segundos' => 45,
    'segundos_repeticion' => 4,
    'series_minimas' => 2,
    'recuperacion_dias' => 2,
    'niveles' => ['principiante' => 1, 'intermedio' => 2, 'avanzado' => 3],
    'experiencia' => [
        '1a3meses' => 'principiante', '4a8meses' => 'principiante',
        '1ano' => 'intermedio', 'mas1ano' => 'intermedio',
        '2anos' => 'avanzado', '3anosamas' => 'avanzado', '3anos_mas' => 'avanzado',
    ],
    'series_por_nivel' => ['principiante' => 2, 'intermedio' => 3, 'avanzado' => 4],
    'objetivos' => [
        'ganancia_muscular' => ['repeticiones' => 10, 'descanso' => 90, 'series_extra' => 0, 'cardio_segundos' => 0],
        'aumento_fuerza' => ['repeticiones' => 5, 'descanso' => 150, 'series_extra' => 1, 'cardio_segundos' => 0],
        'resistencia' => ['repeticiones' => 15, 'descanso' => 45, 'series_extra' => 0, 'cardio_segundos' => 300],
        'perdida_peso' => ['repeticiones' => 12, 'descanso' => 60, 'series_extra' => 0, 'cardio_segundos' => 300],
        'recomposicion' => ['repeticiones' => 10, 'descanso' => 75, 'series_extra' => 0, 'cardio_segundos' => 0],
        'salud' => ['repeticiones' => 10, 'descanso' => 60, 'series_extra' => -1, 'cardio_segundos' => 0],
    ],
    'puntuacion' => ['nivel_exacto' => 30, 'nivel_inferior' => 15, 'grupo' => 30,
        'principal' => 8, 'objetivo' => 20, 'repetido_semana' => 6],
    'bloques' => [
        'completo' => ['pecho', 'espalda', 'cuadriceps', 'isquiotibiales', 'hombros', 'abdomen'],
        'superior' => ['pecho', 'espalda', 'hombros', 'biceps', 'triceps', 'abdomen'],
        'inferior' => ['cuadriceps', 'isquiotibiales', 'gluteos', 'pantorrillas'],
        'empuje' => ['pecho', 'hombros', 'triceps'],
        'tiron' => ['espalda', 'biceps', 'abdomen'],
    ],
    'distribuciones' => [
        2 => ['completo', 'completo'],
        3 => ['completo', 'completo', 'completo'],
        4 => ['superior', 'inferior', 'superior', 'inferior'],
        5 => ['empuje', 'tiron', 'inferior', 'superior', 'inferior'],
        6 => ['empuje', 'tiron', 'inferior', 'empuje', 'tiron', 'inferior'],
    ],
    'dias' => ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'],
    'calendarios' => [2 => [1, 4], 3 => [1, 3, 5], 4 => [1, 2, 4, 5], 5 => [1, 2, 3, 5, 6], 6 => [1, 2, 3, 4, 5, 6]],
    'alias_musculares' => ['isquitiobiales' => 'isquiotibiales'],
];
