# Alimentación móvil

Se integra en la pestaña Nutrición del AppShell existente. Conserva `GymApi`, su cliente HTTP inyectable y el estado local StatefulWidget. No agrega dependencias ni cambia Laravel. El ID de usuario procede de la sesión. No se agregan tokens ni autenticación: se usa el cliente existente.

## Entornos

Desarrollo: `flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://192.168.1.70:8000`.
Producción: `flutter build apk --release --dart-define=APP_ENV=production --dart-define=API_BASE_URL=https://DOMINIO-REAL` (sustituir por el servidor real).
`API_BASE_URL` es el origen sin `/api`. En debug/desarrollo el valor local es el predeterminado. Fuera de desarrollo es obligatorio configurar HTTPS. Android permite tráfico sin cifrar únicamente en el manifest debug; main/release lo rechaza. VS Code tiene la configuración local explícita.

## Operaciones

- `GET /api/planesalimentacion`: solo debug/desarrollo. Los resúmenes se filtran por `id_usuarios` y se seleccionan explícitamente; nunca se interpretan como detalles. Este filtrado no es seguridad. Producción necesita autorización y filtrado de servidor; por eso no se hace esta petición fuera de pruebas.
- `GET /api/usuarios/{usuario}/planesalimentacion/{plan}`: consulta por ID explícito, validando ambos IDs en la respuesta. No se inventa un endpoint de último plan.
- `GET /api/usuarios/{usuario}/perfil-alimentario`: estado del perfil, independiente de la consulta del plan; incluye reintento GET si falla.
- `POST /api/planesalimentacion/generar/{usuario}`: solo desde el formulario. Envía exclusivamente fecha_inicio, duracion_dias, cantidad_comidas y horarios. No reintenta automáticamente. Conserva `data.id` y el detalle recibido en el estado de esa sesión/usuario, incluso al cambiar de pestaña. Después de reiniciar la app se elige explícitamente el plan otra vez, o se consulta por ID. No hay almacenamiento persistente compartido entre usuarios.

Los días y comidas se ordenan por `dia` y `orden`. Las fechas conservan su parte de calendario, sin conversión UTC/local. Las cifras son alimentación planificada. Se muestran porciones y nutrientes del snapshot guardado; la base de referencia no se utiliza para recalcularlos. Solo se comparan totales del día con `calculo.objetivos`. No se comparan `totales_plan` con objetivos diarios. Los nulos opcionales se omiten; los obligatorios incompletos producen un estado de error, no ceros.

Los errores 422 muestran `message` y `errors`. Los estados 404/503/500, conexión y timeout tienen mensajes distintos y sin HTML ni trazas. Las respuestas tardías se descartan al cambiar usuario o desmontar la pantalla. El POST bloquea doble pulsación; ante incertidumbre de red pide consultar los planes antes de repetir.

## Archivos

- `lib/models/nutrition_plan.dart`: modelos y validación del formulario.
- `lib/services/api_environment.dart`: entorno y URL.
- `lib/services/nutrition_api.dart`: extensión del mismo GymApi/cliente HTTP.
- `lib/services/gym_api.dart`: imports y configuración de URL.
- `lib/screens/nutrition_screen.dart`: selección, perfil, detalle, días, totales, notas y advertencias.
- `lib/screens/app_shell.dart`: sesión inyectada en Nutrición.
- `lib/widgets/generate_nutrition_sheet.dart`: formulario y POST explícito.
- `android/app/src/main/AndroidManifest.xml`, `android/app/src/debug/AndroidManifest.xml`: HTTP solo debug.
- `.vscode/launch.json`: parámetros locales.
- `test/nutrition_test.dart`, `test/nutrition_environment_test.dart`, `test/fixtures/nutrition_fixture.dart`: contrato, errores, entorno e interacciones. Fixtures sintéticos exclusivamente de tests, sin modo ficticio de ejecución.
- `test/widget_test.dart`: expectativa actualizada para el módulo integrado.

## Verificación

- `flutter --no-version-check test`: 57 pruebas aprobadas.
- `flutter --no-version-check test test/nutrition_environment_test.dart --dart-define=APP_ENV=production --dart-define=API_BASE_URL=http://192.168.1.70:8000`: 2 pruebas aprobadas; bloquea listado global y configuración HTTP en producción.
- GET desde ADB: HTTP 200 en planesalimentacion. Ruta del teléfono: wlan0, IP 192.168.1.71.
- API actual: listado 200 con resúmenes, perfil del usuario 1 devuelve 404 y detalle del plan 1 devuelve 404. La app informa estas ausencias. El flujo 201 completo se verifica con HTTP simulado; no se alteró el backend, los perfiles ni los alimentos para forzar una generación real.

Para validar un plan real completo el backend debe disponer de perfil alimentario, evaluación apta y catálogo verificado, y devolver el detalle correspondiente. Las rutas ya están conectadas para recibirlo.

## Registro y edición del perfil alimentario

En Nutrición, «Agregar datos alimentarios» / «Editar datos alimentarios» abre el formulario `lib/widgets/food_profile_sheet.dart`.

- Lectura y guardado: `GET` y `PUT /api/usuarios/{id_usuario}/perfil-alimentario` (PUT crea o actualiza; respuesta 200 con `data`).
- Catálogos existentes: `GET /api/restriccionesalimentarias` y `GET /api/alimentos`.
- El PUT envía `sexo_calculo`, `embarazo`, `lactancia`, `requiere_plan_clinico`, `apto_plan_general`, `revision_profesional`, `revisado_en`, `alergias`, `intolerancias` y `preferencias`.
- Alergias/intolerancias son listas de IDs de restricciones. Preferencias contiene objetos `{id_alimentos, tipo}` con `preferido` o `rechazado`.
- La aptitud y revisión profesional se introducen explícitamente, sin inventarlas. El backend valida la vigencia de la revisión (configuración actual: 90 días).
- Se conservan las selecciones existentes, se bloquea doble guardado y se muestran los errores 422 dentro del formulario. Se verifica la identidad del usuario en las respuestas.
- El catálogo consultado contiene solamente dos restricciones marcadas `[DEMO]`. Se necesitan restricciones reales en ese catálogo para seleccionarlas desde el móvil; no hace falta crear otra ruta.
- Verificación del cambio: 61 pruebas aprobadas y `flutter analyze` sin incidencias. El guardado se prueba con HTTP simulado, sin escribir datos clínicos ficticios en usuarios reales. Backend sin modificaciones.
