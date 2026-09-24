-- 30 ejercicios adicionales para GYM-BROS
-- Ejecutar despues de tener creadas las tablas y, si se desea habilitar por empresa,
-- despues de tener empresas registradas.
-- No crea rutinas.

INSERT INTO grupos_musculares (id, descripcion, estado, tipo, created_at, updated_at) VALUES
(1, 'Musculos del pecho para empuje horizontal.', 1, 'pecho', NOW(), NOW()),
(2, 'Musculos de espalda para traccion.', 1, 'espalda', NOW(), NOW()),
(3, 'Musculos del tren inferior enfocados en cuadriceps.', 1, 'cuadriceps', NOW(), NOW()),
(4, 'Zona media y estabilidad del core.', 1, 'abdomen', NOW(), NOW()),
(5, 'Trabajo principal de hombros y deltoides.', 1, 'hombros', NOW(), NOW()),
(6, 'Trabajo principal de biceps.', 1, 'biceps', NOW(), NOW()),
(7, 'Trabajo principal de triceps.', 1, 'triceps', NOW(), NOW()),
(8, 'Trabajo principal de isquiotibiales.', 1, 'isquitiobiales', NOW(), NOW()),
(9, 'Trabajo principal de gluteos.', 1, 'gluteos', NOW(), NOW()),
(10, 'Trabajo principal de pantorrillas.', 1, 'pantorrillas', NOW(), NOW()),
(11, 'Trabajo principal de antebrazos.', 1, 'antebrazos', NOW(), NOW()),
(12, 'Trabajo principal de trapecios.', 1, 'trapecios', NOW(), NOW()),
(13, 'Trabajo principal de serratos.', 1, 'serratos', NOW(), NOW()),
(14, 'Trabajo principal de oblicuos.', 1, 'oblicuos', NOW(), NOW()),
(15, 'Trabajo principal de lumbares.', 1, 'lumbares', NOW(), NOW()),
(16, 'Trabajo principal de aductores.', 1, 'aductores', NOW(), NOW()),
(17, 'Trabajo principal de abductores.', 1, 'abductores', NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO ejercicios (
    id, nombre, descripcion, tipo, instrucciones, nivel, equipamiento, estado,
    enlace_video, imagen_ejercicio, id_grupos_musculares, created_at, updated_at
) VALUES
(5, 'Press inclinado con mancuernas', 'Ejercicio de empuje enfocado en la parte superior del pecho.', 'fuerza', 'Ajustar el banco inclinado, bajar las mancuernas con control y empujar sin bloquear agresivamente los codos.', 'intermedio', 'mancuernas y banco', 1, 'https://videos.test/press-inclinado-mancuernas', 'ejercicios/press-inclinado-mancuernas.webp', 1, NOW(), NOW()),
(6, 'Aperturas en maquina', 'Ejercicio de aislamiento para pecho.', 'fuerza', 'Mantener la espalda apoyada, juntar los brazos al frente y regresar controlando el movimiento.', 'principiante', 'maquina contractora', 1, 'https://videos.test/aperturas-maquina', 'ejercicios/aperturas-maquina.webp', 1, NOW(), NOW()),
(7, 'Fondos asistidos', 'Ejercicio de empuje para pecho y triceps.', 'fuerza', 'Mantener el torso ligeramente inclinado y bajar hasta un rango comodo sin dolor.', 'intermedio', 'maquina asistida', 1, 'https://videos.test/fondos-asistidos', 'ejercicios/fondos-asistidos.webp', 1, NOW(), NOW()),
(8, 'Jalon al pecho', 'Ejercicio de traccion vertical para espalda.', 'fuerza', 'Tirar la barra hacia la parte alta del pecho manteniendo los hombros abajo y el torso estable.', 'principiante', 'polea alta', 1, 'https://videos.test/jalon-pecho', 'ejercicios/jalon-pecho.webp', 2, NOW(), NOW()),
(9, 'Remo con mancuerna', 'Ejercicio unilateral para espalda.', 'fuerza', 'Apoyar una mano en el banco, llevar la mancuerna hacia la cadera y controlar la bajada.', 'intermedio', 'mancuerna y banco', 1, 'https://videos.test/remo-mancuerna', 'ejercicios/remo-mancuerna.webp', 2, NOW(), NOW()),
(10, 'Peso muerto rumano', 'Ejercicio dominante de cadera para cadena posterior.', 'fuerza', 'Flexionar ligeramente rodillas, llevar la cadera atras y mantener la espalda neutra durante todo el recorrido.', 'intermedio', 'barra', 1, 'https://videos.test/peso-muerto-rumano', 'ejercicios/peso-muerto-rumano.webp', 8, NOW(), NOW()),
(11, 'Prensa de piernas', 'Ejercicio de tren inferior con maquina.', 'fuerza', 'Ubicar los pies firmes, bajar con control y empujar sin despegar la cadera del asiento.', 'principiante', 'prensa', 1, 'https://videos.test/prensa-piernas', 'ejercicios/prensa-piernas.webp', 3, NOW(), NOW()),
(12, 'Extension de cuadriceps', 'Ejercicio de aislamiento para cuadriceps.', 'fuerza', 'Extender las piernas hasta contraer el cuadriceps y regresar lentamente.', 'principiante', 'maquina extension', 1, 'https://videos.test/extension-cuadriceps', 'ejercicios/extension-cuadriceps.webp', 3, NOW(), NOW()),
(13, 'Curl femoral acostado', 'Ejercicio de aislamiento para isquiotibiales.', 'fuerza', 'Flexionar rodillas llevando el rodillo hacia los gluteos y controlar la fase de bajada.', 'principiante', 'maquina curl femoral', 1, 'https://videos.test/curl-femoral-acostado', 'ejercicios/curl-femoral-acostado.webp', 8, NOW(), NOW()),
(14, 'Hip thrust con barra', 'Ejercicio principal para gluteos.', 'fuerza', 'Apoyar la espalda alta en banco, empujar la cadera hacia arriba y contraer gluteos al final.', 'intermedio', 'barra y banco', 1, 'https://videos.test/hip-thrust-barra', 'ejercicios/hip-thrust-barra.webp', 9, NOW(), NOW()),
(15, 'Patada de gluteo en polea', 'Ejercicio de aislamiento para gluteos.', 'fuerza', 'Mantener el torso estable y extender la pierna hacia atras sin arquear la espalda.', 'principiante', 'polea baja', 1, 'https://videos.test/patada-gluteo-polea', 'ejercicios/patada-gluteo-polea.webp', 9, NOW(), NOW()),
(16, 'Elevacion de talones de pie', 'Ejercicio para pantorrillas.', 'fuerza', 'Subir los talones hasta la maxima contraccion y bajar lentamente.', 'principiante', 'maquina pantorrilla', 1, 'https://videos.test/elevacion-talones-pie', 'ejercicios/elevacion-talones-pie.webp', 10, NOW(), NOW()),
(17, 'Press militar con barra', 'Ejercicio de empuje vertical para hombros.', 'fuerza', 'Empujar la barra sobre la cabeza manteniendo el abdomen firme y la trayectoria controlada.', 'intermedio', 'barra', 1, 'https://videos.test/press-militar-barra', 'ejercicios/press-militar-barra.webp', 5, NOW(), NOW()),
(18, 'Elevaciones laterales', 'Ejercicio de aislamiento para deltoides lateral.', 'fuerza', 'Elevar las mancuernas hasta la altura de los hombros sin balancear el cuerpo.', 'principiante', 'mancuernas', 1, 'https://videos.test/elevaciones-laterales', 'ejercicios/elevaciones-laterales.webp', 5, NOW(), NOW()),
(19, 'Face pull', 'Ejercicio para hombro posterior y estabilidad escapular.', 'fuerza', 'Tirar la cuerda hacia el rostro separando las manos y manteniendo codos altos.', 'principiante', 'polea con cuerda', 1, 'https://videos.test/face-pull', 'ejercicios/face-pull.webp', 5, NOW(), NOW()),
(20, 'Curl con barra', 'Ejercicio basico para biceps.', 'fuerza', 'Flexionar los codos sin balancear el torso y bajar la barra de forma controlada.', 'principiante', 'barra', 1, 'https://videos.test/curl-barra', 'ejercicios/curl-barra.webp', 6, NOW(), NOW()),
(21, 'Curl martillo', 'Ejercicio para biceps y braquial.', 'fuerza', 'Mantener agarre neutro y elevar las mancuernas sin mover los hombros hacia adelante.', 'principiante', 'mancuernas', 1, 'https://videos.test/curl-martillo', 'ejercicios/curl-martillo.webp', 6, NOW(), NOW()),
(22, 'Curl predicador', 'Ejercicio de aislamiento para biceps.', 'fuerza', 'Apoyar brazos en el banco predicador, flexionar codos y evitar perder tension abajo.', 'intermedio', 'banco predicador', 1, 'https://videos.test/curl-predicador', 'ejercicios/curl-predicador.webp', 6, NOW(), NOW()),
(23, 'Extension de triceps en polea', 'Ejercicio de aislamiento para triceps.', 'fuerza', 'Mantener codos pegados al cuerpo y extender hasta contraer completamente el triceps.', 'principiante', 'polea con cuerda', 1, 'https://videos.test/extension-triceps-polea', 'ejercicios/extension-triceps-polea.webp', 7, NOW(), NOW()),
(24, 'Press frances', 'Ejercicio para triceps con barra.', 'fuerza', 'Bajar la barra hacia la frente controlando los codos y extender sin abrirlos demasiado.', 'intermedio', 'barra z', 1, 'https://videos.test/press-frances', 'ejercicios/press-frances.webp', 7, NOW(), NOW()),
(25, 'Abdominal crunch', 'Ejercicio basico para abdomen.', 'fuerza', 'Elevar el torso contrayendo abdomen sin tirar del cuello.', 'principiante', 'colchoneta', 1, 'https://videos.test/abdominal-crunch', 'ejercicios/abdominal-crunch.webp', 4, NOW(), NOW()),
(26, 'Elevacion de piernas', 'Ejercicio para abdomen inferior.', 'fuerza', 'Elevar piernas manteniendo la zona lumbar controlada y bajar lentamente.', 'intermedio', 'barra o banco', 1, 'https://videos.test/elevacion-piernas', 'ejercicios/elevacion-piernas.webp', 4, NOW(), NOW()),
(27, 'Plancha lateral', 'Ejercicio de estabilidad para oblicuos.', 'equilibrio', 'Apoyar antebrazo y pies, mantener cadera elevada y cuerpo alineado.', 'principiante', 'colchoneta', 1, 'https://videos.test/plancha-lateral', 'ejercicios/plancha-lateral.webp', 14, NOW(), NOW()),
(28, 'Pallof press', 'Ejercicio antirotacional para core.', 'equilibrio', 'Empujar la polea al frente resistiendo la rotacion del torso.', 'intermedio', 'polea o banda', 1, 'https://videos.test/pallof-press', 'ejercicios/pallof-press.webp', 14, NOW(), NOW()),
(29, 'Hiperextension lumbar', 'Ejercicio para lumbares y cadena posterior.', 'fuerza', 'Subir el torso hasta quedar alineado, sin extender excesivamente la espalda.', 'principiante', 'banco romano', 1, 'https://videos.test/hiperextension-lumbar', 'ejercicios/hiperextension-lumbar.webp', 15, NOW(), NOW()),
(30, 'Encogimientos con mancuernas', 'Ejercicio para trapecios.', 'fuerza', 'Elevar hombros hacia arriba sin rotarlos y bajar controladamente.', 'principiante', 'mancuernas', 1, 'https://videos.test/encogimientos-mancuernas', 'ejercicios/encogimientos-mancuernas.webp', 12, NOW(), NOW()),
(31, 'Curl de muneca', 'Ejercicio de aislamiento para antebrazos.', 'fuerza', 'Apoyar antebrazos, flexionar munecas y controlar el regreso.', 'principiante', 'barra o mancuerna', 1, 'https://videos.test/curl-muneca', 'ejercicios/curl-muneca.webp', 11, NOW(), NOW()),
(32, 'Aduccion en maquina', 'Ejercicio para aductores.', 'fuerza', 'Cerrar las piernas contra la resistencia y regresar sin perder control.', 'principiante', 'maquina aductora', 1, 'https://videos.test/aduccion-maquina', 'ejercicios/aduccion-maquina.webp', 16, NOW(), NOW()),
(33, 'Abduccion en maquina', 'Ejercicio para abductores.', 'fuerza', 'Abrir las piernas contra la resistencia manteniendo la espalda apoyada.', 'principiante', 'maquina abductora', 1, 'https://videos.test/abduccion-maquina', 'ejercicios/abduccion-maquina.webp', 17, NOW(), NOW()),
(34, 'Serratus wall slide', 'Ejercicio de control escapular para serratos.', 'flexibilidad', 'Deslizar los antebrazos por la pared manteniendo control escapular y respiracion estable.', 'principiante', 'pared o banda', 1, 'https://videos.test/serratus-wall-slide', 'ejercicios/serratus-wall-slide.webp', 13, NOW(), NOW())
ON DUPLICATE KEY UPDATE id = id;

INSERT INTO ejercicios_grupo_muscular (id_ejercicios, created_at, updated_at)
SELECT ejercicios.id, NOW(), NOW()
FROM ejercicios
WHERE ejercicios.id BETWEEN 5 AND 34
AND NOT EXISTS (
    SELECT 1
    FROM ejercicios_grupo_muscular
    WHERE ejercicios_grupo_muscular.id_ejercicios = ejercicios.id
);

INSERT INTO empresa_ejercicio (id_empresas, id_ejercicios, estado, created_at, updated_at)
SELECT empresas.id, ejercicios.id, 1, NOW(), NOW()
FROM empresas
JOIN ejercicios ON ejercicios.id BETWEEN 5 AND 34
WHERE empresas.id IN (1, 2)
AND NOT EXISTS (
    SELECT 1
    FROM empresa_ejercicio
    WHERE empresa_ejercicio.id_empresas = empresas.id
    AND empresa_ejercicio.id_ejercicios = ejercicios.id
);
