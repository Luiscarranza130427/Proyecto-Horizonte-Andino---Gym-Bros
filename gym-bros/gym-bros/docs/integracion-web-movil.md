# Integración de API, panel Vue y Flutter

La API local usa `http://localhost:8000/api`. Iniciar con `php artisan serve --host=0.0.0.0 --port=8000`.
Aplicar las migraciones con `php artisan migrate` y publicar los archivos con `php artisan storage:link`.
El panel debe usar `VITE_USE_MOCKS=false` y `VITE_API_BASE_URL=http://localhost:8000/api`.
Flutter web usa localhost por defecto en desarrollo; un teléfono físico necesita
`--dart-define=API_BASE_URL=http://IP-LAN:8000`. En producción Flutter exige HTTPS.

## Sesión y respuestas

`POST /api/auth/login` recibe `correo` y `password`. Devuelve `data.token` y `data.usuario`.
Enviar `Authorization: Bearer TOKEN` en las consultas privadas. `GET /api/auth/me` identifica al actor;
`POST /api/auth/logout` revoca su token. Los códigos 401, 403, 404 y 422 significan sesión inválida,
acceso denegado, recurso inexistente y validación fallida, respectivamente.

## Alimentación

- Flutter conserva `/planesalimentacion` y `/usuarios/{usuario}/planesalimentacion/{plan}`.
- El panel usa `/planes-alimentacion`, `/planes-alimentacion/empresas` y `/planes-alimentacion/{plan}`.
- El listado del panel acepta `search`, `activo`, `id_empresas`, `page` y `per_page` (máximo 100).
- Las comidas se crean con POST a `/planes-alimentacion/{plan}/comidas`, se actualizan con PUT y
  se eliminan con DELETE a `/planes-alimentacion/{plan}/comidas/{comida}`.
- Payload: `tipo_comida`, `hora_sugerida` en HH:mm y `alimentos` con `id_alimentos`, `cantidad`, `unidad`.
  Una comida nueva usa el día 1 por defecto; la API también admite `dia`. Una edición conserva su día.
- Las porciones requieren una base nutricional y las conversiones requieren peso por unidad o densidad.
  Un error de conversión devuelve 422 y revierte toda la edición. Se conservan snapshots para Flutter.
- Administrador, Empresa y Entrenador gestionan comidas dentro de su alcance. El cliente Usuario solo consulta.
- `/alimentos` acepta `search`, `type`, `page`, `per_page`; sin paginación conserva el listado usado por Flutter.

## Preferencias

GET y PUT `/perfil/preferencias` leen y guardan las preferencias del usuario autenticado.
Se guardan idioma, tema y opciones de notificaciones; guardar estas opciones no instala un servicio push
ni configura un proveedor de correo. Los proveedores externos y sus credenciales se configuran aparte.

## Verificación

`php artisan test --compact` usa SQLite en memoria, sin tocar la base local.
Las pruebas de integración verifican contratos de alimentación, aislamiento entre gimnasios,
transacciones, preferencias por usuario y preflight CORS para Vue y Flutter web.
Para el panel: `npm run lint`, `npm run test`, `npm run build`.
Para Flutter: `flutter analyze` y `flutter test`.
