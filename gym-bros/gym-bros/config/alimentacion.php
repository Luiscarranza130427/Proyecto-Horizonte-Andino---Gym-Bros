<?php

return [
    // Technical availability does not certify a patient's profile or food data.
    'habilitado' => env('ALIMENTACION_HABILITADA', true),
    'permitir_sin_sesion_local' => env('ALIMENTACION_PERMITIR_SIN_SESION_LOCAL', true),
    'version' => '1.0-provisional',
    'edad_min' => 19,
    'edad_max' => 65,
    'peso_min' => 40,
    'peso_max' => 200,
    'altura_min_cm' => 130,
    'altura_max_cm' => 220,
    'vigencia_evaluacion_dias' => 90,
    'vigencia_revision_dias' => 90,
    'max_dias' => 14,
    'max_candidatos_grupo' => 4,
    'iteraciones_porciones' => 80,
    'tolerancias' => ['calorias' => 0.08, 'proteinas' => 0.15, 'carbohidratos' => 0.15, 'grasas' => 0.15],
    'factores_actividad' => ['sedentario' => 1.4, 'activo_ligero' => 1.6, 'moderadamente_activo' => 1.8, 'muy_activo' => 2.0],
    // Fractions of energy, not grams per kg. Objective adjustments require approval.
    'objetivos' => [
        'salud' => ['ajuste' => 0, 'proteinas' => 0.20, 'carbohidratos' => 0.50, 'grasas' => 0.30],
        'perdida_peso' => ['ajuste' => -0.10, 'proteinas' => 0.25, 'carbohidratos' => 0.45, 'grasas' => 0.30],
        'ganancia_muscular' => ['ajuste' => 0.05, 'proteinas' => 0.25, 'carbohidratos' => 0.50, 'grasas' => 0.25],
        'resistencia' => ['ajuste' => 0, 'proteinas' => 0.20, 'carbohidratos' => 0.55, 'grasas' => 0.25],
        'recomposicion' => ['ajuste' => 0, 'proteinas' => 0.25, 'carbohidratos' => 0.45, 'grasas' => 0.30],
        'aumento_fuerza' => ['ajuste' => 0.05, 'proteinas' => 0.25, 'carbohidratos' => 0.50, 'grasas' => 0.25],
    ],
    'distribuciones' => [
        3 => ['desayuno' => 0.30, 'almuerzo' => 0.40, 'cena' => 0.30],
        4 => ['desayuno' => 0.25, 'almuerzo' => 0.35, 'media_tarde' => 0.10, 'cena' => 0.30],
        5 => ['desayuno' => 0.25, 'media_manana' => 0.10, 'almuerzo' => 0.30, 'media_tarde' => 0.10, 'cena' => 0.25],
    ],
    'grupos_comida' => [
        'desayuno' => ['proteina', 'carbohidrato', 'fruta', 'grasa'],
        'almuerzo' => ['proteina', 'carbohidrato', 'verdura', 'grasa'],
        'cena' => ['proteina', 'carbohidrato', 'verdura', 'grasa'],
        'media_manana' => ['proteina', 'fruta', 'grasa'],
        'media_tarde' => ['proteina', 'fruta', 'grasa'],
    ],
];
