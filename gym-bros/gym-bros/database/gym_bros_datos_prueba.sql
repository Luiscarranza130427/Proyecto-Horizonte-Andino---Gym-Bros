-- Datos de prueba para GYM-BROS
-- Ejecutar despues de correr todas las migraciones.
-- Password de usuarios de prueba: password

SET FOREIGN_KEY_CHECKS=0;

INSERT INTO users (id, name, email, email_verified_at, password, remember_token, created_at, updated_at) VALUES
(1, 'Administrador Laravel', 'admin@gymbros.test', NOW(), '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', NULL, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO empresas (
    id, nombre, nombre_gerente, region, RUC, enlace_web, direccion, telefono, correo,
    estado, fecha_registro, logo, color_1, color_2,
    banner_1, banner_2, banner_3, link_boton_1, link_boton_2, link_boton_3,
    horario_inicio_lunes, horario_fin_lunes, horario_inicio_martes, horario_fin_martes,
    horario_inicio_miercoles, horario_fin_miercoles, horario_inicio_jueves, horario_fin_jueves,
    horario_inicio_viernes, horario_fin_viernes, horario_inicio_sabado, horario_fin_sabado,
    horario_inicio_domingo, horario_fin_domingo, created_at, updated_at
) VALUES
(1, 'Gym Bros Central', 'Carlos Mendoza', 'Lima', '20601234567', 'https://gymbros.test', 'Av. Principal 123, Lima', '999888777', 'central@gymbros.test',
 1, '2026-09-01', 'logos/gym-bros-central.png', '#111111', '#FFCC00',
 'banners/central-1.jpg', 'banners/central-2.jpg', 'banners/central-3.jpg', 'https://gymbros.test/promos', 'https://gymbros.test/rutinas', 'https://gymbros.test/planes',
 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 6.00, 22.00, 7.00, 20.00, 8.00, 14.00, NOW(), NOW()),
(2, 'Iron House Fitness', 'Mariana Torres', 'Arequipa', '20607654321', 'https://ironhouse.test', 'Calle Fitness 456, Arequipa', '988777666', 'contacto@ironhouse.test',
 1, '2026-09-01', 'logos/iron-house.png', '#202020', '#00AEEF',
 'banners/iron-1.jpg', 'banners/iron-2.jpg', 'banners/iron-3.jpg', 'https://ironhouse.test/promos', 'https://ironhouse.test/clases', 'https://ironhouse.test/contacto',
 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 5.50, 23.00, 7.00, 21.00, 8.00, 13.00, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO usuarios (
    id, nombres, apellidos, apodo, genero, correo, password_hash, tipo_documento,
    numero_documento, telefono, direccion, foto_perfil, fecha_registro, fecha_nacimiento,
    asistencia_semanal, tipo_usuario, estado, id_empresas, created_at, updated_at
) VALUES
(1, 'Diego', 'Ramirez', 'D-Ram', 'Varon', 'diego@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'DNI',
 '74581236', '987654321', 'Av. Los Olivos 100', 'perfiles/diego.png', '2026-09-01', '1998-04-15',
 '2026-09-07 07:00:00', 'Usuario', 1, 1, NOW(), NOW()),
(2, 'Lucia', 'Salazar', 'Lu', 'Mujer', 'lucia@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'DNI',
 '70889911', '976543210', 'Jr. Progreso 220', 'perfiles/lucia.png', '2026-09-01', '2001-02-20',
 '2026-09-07 18:00:00', 'Usuario', 1, 1, NOW(), NOW()),
(3, 'Marco', 'Vargas', 'Coach Marco', 'Varon', 'marco@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'DNI',
 '70112233', '965432109', 'Av. Trainer 300', 'perfiles/marco.png', '2026-09-01', '1990-07-10',
 NULL, 'Entrenador', 1, 1, NOW(), NOW()),
(4, 'Admin', 'Empresa Central', 'Central Admin', 'Varon', 'empresa@gymbros.test', '$2y$12$KIXQ4YkTDuJXo7T4PK6H5.6V0U1uL5M3xT/1uIX7O2G9LuA2xwq1i', 'OTRO',
 '20601234567', '954321098', 'Av. Principal 123', NULL, '2026-09-01', '1988-01-01',
 NULL, 'Empresa', 1, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO evaluaciones_fisicas (
    id, nivel_experiencia, actividad_diaria, objetivo, edad, peso, altura,
    porcentaje_grasa, masa_muscular, cintura, pecho, brazo, muslo, cadera,
    dias_semana, eleccion_dias, tiempo_sesion_min, restricciones, fecha_evaluacion,
    id_usuarios, created_at, updated_at
) VALUES
(1, '1ano', 'moderadamente_activo', 'ganancia_muscular', 28, 78.50, 1.76, 18.20, 34.00, 84.00, 98.00, 34.00, 58.00, 92.00,
 4, 'Lunes', 60, 'sin-restricciones', '2026-09-02', 1, NOW(), NOW()),
(2, '1a3meses', 'activo_ligero', 'perdida_peso', 25, 66.20, 1.62, 26.00, 24.00, 78.00, 88.00, 27.00, 52.00, 96.00,
 3, 'Martes', 45, 'sin-restricciones', '2026-09-02', 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO grupos_musculares (id, descripcion, estado, tipo, created_at, updated_at) VALUES
(1, 'Musculos del pecho para empuje horizontal.', 1, 'pecho', NOW(), NOW()),
(2, 'Musculos de espalda para traccion.', 1, 'espalda', NOW(), NOW()),
(3, 'Musculos del tren inferior enfocados en cuadriceps.', 1, 'cuadriceps', NOW(), NOW()),
(4, 'Zona media y estabilidad del core.', 1, 'abdomen', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO ejercicios (
    id, nombre, descripcion, tipo, instrucciones, nivel, equipamiento, estado,
    enlace_video, imagen_ejercicio, id_grupos_musculares, created_at, updated_at
) VALUES
(1, 'Press banca', 'Ejercicio basico de empuje para pecho.', 'fuerza', 'Mantener escapulas retraidas, bajar controlado y empujar sin despegar la espalda.', 'intermedio', 'barra y banco', 1, 'https://videos.test/press-banca', 'ejercicios/press-banca.jpg', 1, NOW(), NOW()),
(2, 'Remo con polea', 'Ejercicio de traccion para espalda.', 'fuerza', 'Tirar la polea hacia el abdomen manteniendo el torso estable.', 'principiante', 'polea', 1, 'https://videos.test/remo-polea', 'ejercicios/remo-polea.jpg', 2, NOW(), NOW()),
(3, 'Sentadilla goblet', 'Ejercicio para piernas con mancuerna.', 'fuerza', 'Bajar manteniendo rodillas alineadas y pecho arriba.', 'principiante', 'mancuerna', 1, 'https://videos.test/sentadilla-goblet', 'ejercicios/sentadilla-goblet.jpg', 3, NOW(), NOW()),
(4, 'Plancha frontal', 'Ejercicio de estabilidad abdominal.', 'equilibrio', 'Mantener abdomen activo y cadera alineada.', 'principiante', 'peso corporal', 1, 'https://videos.test/plancha', 'ejercicios/plancha.jpg', 4, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO ejercicios_grupo_muscular (id, id_ejercicios, created_at, updated_at) VALUES
(1, 1, NOW(), NOW()),
(2, 2, NOW(), NOW()),
(3, 3, NOW(), NOW()),
(4, 4, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO rutinas (
    id, nombre, descripcion, objetivo, dias_semana, duracion_estimada,
    fecha_inicio, fecha_fin, estado, id_usuarios, created_at, updated_at
) VALUES
(1, 'Rutina hipertrofia inicial', 'Rutina base para ganar masa muscular con cuatro sesiones semanales.', 'ganancia_muscular', 4, 60, '2026-09-03', '2026-10-03', 1, 1, NOW(), NOW()),
(2, 'Rutina perdida de peso inicial', 'Rutina de acondicionamiento para tres dias semanales.', 'perdida_peso', 3, 45, '2026-09-03', '2026-10-03', 1, 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO ejercicios_rutina (
    id, dia, orden, series, repeticiones, peso, descanso_segundos, tiempo_segundos,
    notas, id_rutinas, id_ejercicios, created_at, updated_at
) VALUES
(1, 1, 1, 4, 10, 40.00, 90, 0, 'Calentar antes de la primera serie.', 1, 1, NOW(), NOW()),
(2, 1, 2, 4, 12, 35.00, 75, 0, 'Mantener control en la fase excentrica.', 1, 2, NOW(), NOW()),
(3, 2, 1, 3, 12, 18.00, 75, 0, 'Usar peso moderado y buena tecnica.', 1, 3, NOW(), NOW()),
(4, 1, 1, 3, 15, 12.00, 60, 0, 'Ritmo constante.', 2, 3, NOW(), NOW()),
(5, 1, 2, 3, 0, 0.00, 45, 30, 'Mantener postura estable.', 2, 4, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO alimentos (
    id, nombre, tipo, calorias, proteinas, carbohidratos, grasas, fibra, created_at, updated_at
) VALUES
(1, 'Pechuga de pollo', 'proteina', 165.00, 31.00, 0.00, 3.60, 0.00, NOW(), NOW()),
(2, 'Arroz integral', 'carbohidrato', 111.00, 2.60, 23.00, 0.90, 1.80, NOW(), NOW()),
(3, 'Palta', 'grasa', 160.00, 2.00, 8.50, 14.70, 6.70, NOW(), NOW()),
(4, 'Platano', 'fruta', 89.00, 1.10, 22.80, 0.30, 2.60, NOW(), NOW()),
(5, 'Brocoli', 'verdura', 34.00, 2.80, 6.60, 0.40, 2.60, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO planes_alimentacion (
    id, nombre, descripcion, objetivo, calorias_objetivo, proteinas_objetivo,
    carbohidratos_objetivo, grasas_objetivo, fecha_inicio, fecha_fin, estado,
    id_usuarios, created_at, updated_at
) VALUES
(1, 'Plan volumen limpio', 'Plan base para aumento muscular controlado.', 'ganancia_muscular', 2600.00, 160.00, 320.00, 75.00, '2026-09-03', '2026-10-03', 1, 1, NOW(), NOW()),
(2, 'Plan deficit inicial', 'Plan base para perdida de peso progresiva.', 'perdida_peso', 1800.00, 120.00, 180.00, 55.00, '2026-09-03', '2026-10-03', 1, 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO comidas (
    id, nombre, tipo, orden, hora_sugerida, notas, id_planes_alimentacion, created_at, updated_at
) VALUES
(1, 'Desayuno volumen', 'desayuno', 1, '07:30:00', 'Comida alta en carbohidratos para iniciar el dia.', 1, NOW(), NOW()),
(2, 'Almuerzo volumen', 'almuerzo', 2, '13:00:00', 'Comida principal con proteina magra.', 1, NOW(), NOW()),
(3, 'Desayuno deficit', 'desayuno', 1, '08:00:00', 'Porcion moderada y saciante.', 2, NOW(), NOW()),
(4, 'Cena deficit', 'cena', 2, '20:00:00', 'Cena ligera con verduras.', 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO comida_alimentos (
    id, cantidad, unidad, notas, id_comidas, id_alimentos, created_at, updated_at
) VALUES
(1, 120.00, 'gramos', 'Porcion cocida.', 1, 2, NOW(), NOW()),
(2, 1.00, 'unidad', 'Platano mediano.', 1, 4, NOW(), NOW()),
(3, 180.00, 'gramos', 'Pechuga a la plancha.', 2, 1, NOW(), NOW()),
(4, 100.00, 'gramos', 'Acompanar con arroz.', 2, 5, NOW(), NOW()),
(5, 1.00, 'unidad', 'Platano pequeno.', 3, 4, NOW(), NOW()),
(6, 150.00, 'gramos', 'Pechuga a la plancha.', 4, 1, NOW(), NOW()),
(7, 120.00, 'gramos', 'Verdura al vapor.', 4, 5, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO preferencias_alimentarias (
    id, activo, id_usuarios, id_alimentos, created_at, updated_at
) VALUES
(1, 1, 1, 1, NOW(), NOW()),
(2, 1, 1, 2, NOW(), NOW()),
(3, 1, 2, 4, NOW(), NOW()),
(4, 1, 2, 5, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO progresos (
    id, fecha, peso, altura, porcentaje_grasa, masa_muscular,
    cintura, pecho, brazo, muslo, cadera, notas, id_usuarios, created_at, updated_at
) VALUES
(1, '2026-09-04', 78.20, 1.76, 18.00, 34.20, 83.50, 98.50, 34.20, 58.20, 92.00, 'Primer registro posterior a evaluacion.', 1, NOW(), NOW()),
(2, '2026-09-04', 65.90, 1.62, 25.70, 24.10, 77.50, 88.00, 27.00, 52.00, 95.50, 'Inicio de seguimiento semanal.', 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO sensaciones (
    id, fecha, energia, dificultad, fatiga, dolor, comentario,
    id_usuarios, id_rutinas, created_at, updated_at
) VALUES
(1, '2026-09-05', 4, 3, 2, 1, 'Entrenamiento manejable y buena energia.', 1, 1, NOW(), NOW()),
(2, '2026-09-05', 3, 4, 3, 1, 'Sesion intensa pero completada.', 2, 2, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO historial_cambios (
    id, id_empresas, id_usuarios, tabla_afectada, id_registros,
    accion, datos_anteriores, datos_nuevos, descripcion, created_at, updated_at
) VALUES
(1, 1, 3, 'rutinas', 1, 'crear', JSON_OBJECT(), JSON_OBJECT('nombre', 'Rutina hipertrofia inicial'), 'Creacion de rutina inicial para usuario Diego.', NOW(), NOW()),
(2, 1, 4, 'empresas', 1, 'actualizar', JSON_OBJECT('banner_1', NULL), JSON_OBJECT('banner_1', 'banners/central-1.jpg'), 'Actualizacion de banner principal de empresa.', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO notificaciones (
    id, id_empresas, id_usuarios, tipo, titulo, mensaje,
    fecha_envio, leida, enviada, created_at, updated_at
) VALUES
(1, 1, 1, 'rutina', 'Rutina asignada', 'Ya tienes una rutina activa para esta semana.', '2026-09-05 09:00:00', 0, 1, NOW(), NOW()),
(2, 1, 2, 'alimentacion', 'Plan de alimentacion listo', 'Tu plan de alimentacion inicial ya esta disponible.', '2026-09-05 09:30:00', 0, 1, NOW(), NOW()),
(3, NULL, NULL, 'sistema', 'Bienvenido a GYM-BROS', 'Gracias por usar la plataforma.', '2026-09-05 10:00:00', 0, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO planes (
    id, nombre, descripcion, precio_original, precio_inicial, duracion_dias,
    limite_usuarios, activo, contenido, enlace_whatsapp, created_at, updated_at
) VALUES
(1, 'Plan Basico', 'Plan inicial para gimnasios pequenos.', 149.00, 99.00, 30, 100, 1, 'Usuarios, rutinas, alimentacion y soporte basico.', 'https://wa.me/51999999999', NOW(), NOW()),
(2, 'Plan Pro', 'Plan para gimnasios con mayor cantidad de usuarios.', 299.00, 199.00, 30, 500, 1, 'Usuarios ilimitados por sede, reportes y soporte prioritario.', 'https://wa.me/51999999999', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO suscripciones (
    id, id_empresas, id_planes, fecha_inicio, fecha_fin,
    estado, renovacion_automatica, created_at, updated_at
) VALUES
(1, 1, 2, '2026-09-01', '2026-10-01', 'activa', 1, NOW(), NOW()),
(2, 2, 1, '2026-09-01', '2026-10-01', 'activa', 0, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO pagos (
    id, id_empresas, id_suscripciones, monto, moneda, metodo_pago,
    referencia, estado, fecha_pago, created_at, updated_at
) VALUES
(1, 1, 1, 199.00, 'PEN', 'tarjeta', 'PAY-GYMBROS-0001', 'aprobado', '2026-09-01 12:00:00', NOW(), NOW()),
(2, 2, 2, 99.00, 'PEN', 'transferencia', 'PAY-GYMBROS-0002', 'aprobado', '2026-09-01 13:00:00', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO banners (
    id, imagen, contenido_text, texto_boton, enlace_boton, created_at, updated_at
) VALUES
(1, 'banners/general-1.jpg', 'Entrena con una rutina personalizada.', 'Ver rutina', 'https://gymbros.test/rutinas', NOW(), NOW()),
(2, 'banners/general-2.jpg', 'Mejora tu alimentacion semanal.', 'Ver plan', 'https://gymbros.test/alimentacion', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO empresa_ejercicio (
    id, id_empresas, id_ejercicios, estado, created_at, updated_at
) VALUES
(1, 1, 1, 1, NOW(), NOW()),
(2, 1, 2, 1, NOW(), NOW()),
(3, 1, 3, 1, NOW(), NOW()),
(4, 1, 4, 1, NOW(), NOW()),
(5, 2, 2, 1, NOW(), NOW()),
(6, 2, 3, 1, NOW(), NOW()),
(7, 2, 4, 1, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

SET FOREIGN_KEY_CHECKS=1;
