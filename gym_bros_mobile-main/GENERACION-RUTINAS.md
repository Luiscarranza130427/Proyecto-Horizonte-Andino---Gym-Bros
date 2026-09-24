# Generación desde Progreso

El botón situado después del peso y la fecha usa `POST /api/rutinas/generar/{id_usuario}` con `{}`. La respuesta `data` contiene la rutina; se coloca primero en la sesión y se abre la pestaña Rutinas, conservando el menú inferior. Al cargar la sesión se ordenan las rutinas por ID descendente.

La disponibilidad se consulta con `GET /api/rutinas/generar/{id_usuario}/estado`: `data.permitido`, `generadas_mes`, `limite_mensual` y `mensaje`. Sin respuesta válida el botón permanece deshabilitado con opción de consultar nuevamente.

El backend local en `C:\laragon\www\gym-bros` aplica el límite dentro de la transacción del generador, con bloqueo del usuario. La tabla `routine_generation_usage` conserva las generaciones exitosas y una huella de los datos físicos y de entrenamiento. No cuenta solicitudes fallidas. El mes calendario usa America/Lima.

Permite tres generaciones mensuales. Agotadas estas, cada combinación nueva de datos de evaluación permite una generación adicional. Cambiar solo fecha, ID o guardar sin cambios no renueva el cupo; volver a datos ya usados durante el mes tampoco. El cupo se renueva al comenzar el siguiente mes.

Las rutinas históricas identificadas por la descripción del generador también cuentan. Como no tenían huella, su excepción inicial se compara con la fecha de modificación de la evaluación; las nuevas generaciones ya tienen comprobación por contenido.

Migración aplicada: `2026_09_11_120000_create_routine_generation_usage.php`. La verificación del POST se hizo con base SQLite en memoria y cliente HTTP simulado, sin crear rutinas de prueba en los usuarios reales.
