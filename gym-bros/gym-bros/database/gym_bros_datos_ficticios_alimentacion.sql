-- GYM-BROS: datos SINTETICOS para pruebas locales, NO para produccion.
-- Ejecutar TODO el archivo en una misma conexion, seleccionando antes la BD.
-- Requiere las migraciones de alimentacion, revision opcional y seleccion por alimentos.
-- Cada ejecucion crea un lote NUEVO. No actualiza ni borra registros existentes.
-- No crea planes, comidas ni rutinas: estos deben generarse mediante el API.
-- ATENCION: el catalogo de alimentos es GLOBAL, incluso con una empresa demo.
-- Estos alimentos pueden aparecer para otros usuarios del entorno de prueba.
-- Los indicadores verificados=1 simulan datos completos, NO certifican alimentos.
-- Ante cualquier error, detener la ejecucion y ejecutar ROLLBACK en esa conexion.

START TRANSACTION;

SET @lote = REPLACE(UUID(), '-', '');
-- Laravel utiliza UTC. La fecha puede ajustarse si cambia la zona de la app.
SET @hoy = DATE(UTC_TIMESTAMP());
SET @ahora = UTC_TIMESTAMP();
SET @correo_demo = CONCAT('demo.alimentacion.', @lote, '@example.invalid');
SET @fuente_demo = CONCAT('DATOS SINTETICOS - NO CONSUMO REAL - lote ', @lote);

INSERT INTO empresas (
    nombre, nombre_gerente, region, ruc, telefono, correo, estado,
    fecha_registro, logo, color_1, color_2,
    horario_inicio_lunes, horario_fin_lunes, horario_inicio_martes, horario_fin_martes,
    horario_inicio_miercoles, horario_fin_miercoles, horario_inicio_jueves, horario_fin_jueves,
    horario_inicio_viernes, horario_fin_viernes, created_at, updated_at
) VALUES (
    CONCAT('[DEMO] Alimentacion ', @lote), 'Responsable ficticio', 'Lima', NULL,
    '000000000', CONCAT('empresa.', @lote, '@example.invalid'), 1,
    @hoy, '', '#167D50', '#FFFFFF',
    6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, @ahora, @ahora
);
SET @id_empresa_demo = LAST_INSERT_ID();

-- Contrasena ficticia: GymBrosDemo2026! (almacenada mediante bcrypt).
INSERT INTO usuarios (
    nombres, apellidos, apodo, genero, correo, password_hash, tipo_documento,
    numero_documento, telefono, direccion, foto_perfil, fecha_registro,
    fecha_nacimiento, asistencia_semanal, tipo_usuario, estado, id_empresas,
    created_at, updated_at
) VALUES (
    '[DEMO] Usuario', 'Alimentacion ficticia', CONCAT('demo_', @lote), 'Varon', @correo_demo,
    '$2y$10$cnCI2uCdZuipDZI.WJ1aeOdrs1lk0IxLiEYRHQ4Elsl1V6terv6nG', 'OTRO',
    CONCAT('QA', LEFT(@lote, 10)), '000000000', 'SOLO PRUEBAS', NULL, @hoy,
    DATE_SUB(@hoy, INTERVAL 30 YEAR), NULL, 'Usuario', 1, @id_empresa_demo, @ahora, @ahora
);
SET @id_usuario_demo = LAST_INSERT_ID();

INSERT INTO evaluaciones_fisicas (
    nivel_experiencia, actividad_diaria, objetivo, edad, peso, altura, altura_unidad,
    porcentaje_grasa, masa_muscular, cintura, pecho, brazo, muslo, cadera,
    dias_semana, eleccion_dias, tiempo_sesion_min, restricciones, fecha_evaluacion,
    id_usuarios, created_at, updated_at
) VALUES (
    '1a3meses', 'sedentario', 'salud', 30, 70.00, 175.00, 'cm',
    20.00, 30.00, 80.00, 90.00, 30.00, 50.00, 90.00,
    3, JSON_ARRAY('Lunes', 'Miercoles', 'Viernes'), 60, 'sin-restricciones', @hoy,
    @id_usuario_demo, @ahora, @ahora
);
SET @id_evaluacion_demo = LAST_INSERT_ID();

INSERT INTO perfiles_alimentarios (
    id_usuarios, sexo_calculo, embarazo, lactancia, requiere_plan_clinico,
    apto_plan_general, revision_profesional, revisado_en, created_at, updated_at
) VALUES (
    @id_usuario_demo, 'masculino', 0, 0, 0, 1,
    NULL,
    NULL, @ahora, @ahora
);

-- 15 alimentos compatibles: 3 variantes por cada grupo.
-- Nutrientes por 100 g, exclusivamente matematicos. No representan alimentos reales.
INSERT INTO alimentos (
    nombre, tipo, calorias, proteinas, carbohidratos, grasas, fibra,
    base_unidad, estado_preparacion, gramos_por_unidad, densidad_g_ml,
    fuente_nutricional, nutricion_verificada, restricciones_verificadas,
    grupo_menu, tipos_comida, porcion_min, porcion_max, paso_porcion, created_at, updated_at
)
SELECT CONCAT('[DEMO] ', g.grupo, ' ', v.numero, ' ', @lote), g.grupo,
    g.kcal, g.proteina, g.carbohidrato, g.grasa, 0,
    'gramos', 'Simulado - no destinado a consumo', NULL, NULL,
    @fuente_demo, 1, 1, g.grupo,
    JSON_ARRAY('desayuno', 'media_manana', 'almuerzo', 'media_tarde', 'cena'),
    1.00, IF(g.grupo = 'grasa', 60.00, 600.00), 1.00, @ahora, @ahora
FROM (
    SELECT 'proteina' AS grupo, 138 AS kcal, 25 AS proteina, 5 AS carbohidrato, 2 AS grasa
    UNION ALL SELECT 'carbohidrato', 226, 2, 50, 2
    UNION ALL SELECT 'grasa', 900, 0, 0, 100
    UNION ALL SELECT 'fruta', 48, 1, 11, 0
    UNION ALL SELECT 'verdura', 28, 2, 5, 0
) AS g
CROSS JOIN (SELECT 1 AS numero UNION ALL SELECT 2 UNION ALL SELECT 3) AS v;

-- 3 alimentos adicionales que el generador debe EXCLUIR para este usuario.
INSERT INTO alimentos (
    nombre, tipo, calorias, proteinas, carbohidratos, grasas, fibra,
    base_unidad, estado_preparacion, fuente_nutricional,
    nutricion_verificada, restricciones_verificadas, grupo_menu, tipos_comida,
    porcion_min, porcion_max, paso_porcion, created_at, updated_at
)
SELECT CONCAT('[DEMO] EXCLUIR ', x.motivo, ' ', @lote), 'proteina', 138, 25, 5, 2, 0,
    'gramos', 'Simulado - no destinado a consumo', @fuente_demo, 1, 1, 'proteina',
    JSON_ARRAY('desayuno', 'media_manana', 'almuerzo', 'media_tarde', 'cena'),
    1.00, 600.00, 1.00, @ahora, @ahora
FROM (SELECT 'rechazo_a' AS motivo UNION ALL SELECT 'rechazo_b' UNION ALL SELECT 'rechazo') AS x;

SET @id_alimento_rechazo_a = (SELECT id FROM alimentos WHERE nombre = CONCAT('[DEMO] EXCLUIR rechazo_a ', @lote));
SET @id_alimento_rechazo_b = (SELECT id FROM alimentos WHERE nombre = CONCAT('[DEMO] EXCLUIR rechazo_b ', @lote));
SET @id_alimento_rechazado = (SELECT id FROM alimentos WHERE nombre = CONCAT('[DEMO] EXCLUIR rechazo ', @lote));
SET @id_alimento_preferido = (SELECT id FROM alimentos WHERE nombre = CONCAT('[DEMO] proteina 1 ', @lote));

INSERT INTO preferencias_alimentarias (activo, tipo, id_usuarios, id_alimentos, created_at, updated_at)
VALUES (1, 'preferido', @id_usuario_demo, @id_alimento_preferido, @ahora, @ahora),
       (1, 'rechazado', @id_usuario_demo, @id_alimento_rechazado, @ahora, @ahora),
       (1, 'rechazado', @id_usuario_demo, @id_alimento_rechazo_a, @ahora, @ahora),
       (1, 'rechazado', @id_usuario_demo, @id_alimento_rechazo_b, @ahora, @ahora);
-- Los tres rechazos son selecciones por alimento, no antecedentes medicos.

COMMIT;

-- Resultado: utilizar ESTE id_usuario, no un ID de usuario anterior.
SELECT @lote AS lote_prueba, @id_usuario_demo AS id_usuario,
    @id_empresa_demo AS id_empresa, @id_evaluacion_demo AS id_evaluacion,
    @correo_demo AS correo, 'GymBrosDemo2026!' AS contrasena_demo,
    (SELECT COUNT(*) FROM alimentos WHERE fuente_nutricional = @fuente_demo) AS alimentos_creados,
    @hoy AS fecha_inicio_sugerida;

-- El body ya tiene una fecha valida para el dia de ejecucion.
SELECT JSON_OBJECT('fecha_inicio', DATE_FORMAT(@hoy, '%Y-%m-%d'),
    'duracion_dias', 7, 'cantidad_comidas', 3,
    'horarios', JSON_OBJECT('desayuno', '08:00', 'almuerzo', '13:00', 'cena', '19:00')) AS body_generacion;
