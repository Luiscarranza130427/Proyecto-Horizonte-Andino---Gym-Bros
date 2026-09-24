# Checkout SaaS GYM-BROS

## Alcance y estado

Integracion nueva, deshabilitada por defecto (MP_ENABLED=false). No se cambiaron
precios, datos reales ni migraciones historicas. No se modifico el frontend.
La migracion nueva se prueba en SQLite y MySQL temporal; NO se ejecuto sobre la
base principal. Antes de habilitar: resolver los bloqueos de produccion descritos
abajo y probar extremo a extremo con cuentas de prueba de Mercado Pago.

Checkout Pro por Preferences API usando Http de Laravel (sin SDK adicional).
Solo Sanctum se agrega como dependencia. No se capturan tarjetas en Laravel.
Tarjeta, Yape y saldo dependen de la disponibilidad del checkout del proveedor.

## Esquema y compatibilidad

Se reutilizan empresas, usuarios, planes, suscripciones y pagos. Los horarios ya
son nullable en codigo y DB inspeccionada; no se alteran nuevamente.
La migracion 2026_09_22_200000_prepare_checkout agrega:
- ordenes_compra: UUID, snapshots, comprador y empresa cifrados con APP_KEY,
  referencia externa = uuid, expiracion, ids relacionados, marcas de correo y
  token de alta hasheado. Nunca guarda la contrasena.
- personal_access_tokens de Sanctum se crea ahora mediante la migracion
  independiente 2026_09_22_195900_create_personal_access_tokens, compartida con
  el login de Vue/Flutter. Revertir checkout no elimina sesiones.
- reembolsos_pago: intento persistente unico por pago, actor, motivo, clave de
  idempotencia e identificador de proveedor.
- Auditoria de proveedor, claves unicas y fechas en pagos.
- Nullable en apodo, genero, tipo_documento, numero_documento, fecha_nacimiento
  e inicio/fin_suscripcion de usuarios. Una cuenta empresarial no tiene membresia
  personal; estas dos ultimas fechas quedan null, evitando la tarea antigua que
  desactiva usuarios con fecha personal futura. Sus fechas SaaS viven en suscripciones.
- correo_normalizado generado (LOWER/TRIM), unico. Se comprueban duplicados antes
  de migrar sin imprimir los correos ni borrar registros. No se exige correo unico
  en empresas: el contacto comercial puede ser compartido.

Mantiene los campos obligatorios de identidad y password_hash. El usuario inicial
recibe un hash de un secreto aleatorio desconocido, imposible de usar como clave
entregada al comprador. Establece su clave mediante enlace firmado y token de un
solo uso, valido 48 horas. tipo_usuario = Empresa y estado = true.

Los registros de compra se preservan con FKs restrictivas. El borrado de una
empresa con compra auditada debe rechazarse; no se debe borrar auditoria financiera
en cascada. La reversion de la migracion se detiene si existen compras/reembolsos o
perfiles con null que impidan restaurar el esquema anterior. No completa datos falsos.

El flujo interno AsignarPlanEmpresaService no cambia. Su regla historica es
duracion - 1; este checkout usa la regla pedida: fecha_inicio + duracion_dias.
No hay prueba gratis ni renovacion automatica en este flujo.
Los estados intermedios viven en ordenes_compra, pues pagos exige empresa y
suscripcion existentes. pagos solo nace aprobado tras verificar; el enum existente
ya permite aprobado/reembolsado, por lo que no necesita ampliarse.

## Configuracion (fuera del repositorio)

```dotenv
MP_ENABLED=false
MP_ACCESS_TOKEN=<token privado del vendedor>
MP_WEBHOOK_SECRET=<firma privada de la aplicacion>
MP_NOTIFICATION_URL=https://api.dominio/api/webhooks/mercado-pago
MP_LIVE_MODE=false
FRONTEND_URL=https://portal.dominio
ONBOARDING_LOGO=empresas/logo-predeterminado-gymbros.webp
QUEUE_CONNECTION=database
MAIL_MAILER=smtp
MAIL_HOST=<pendiente del proveedor>
MAIL_PORT=465
MAIL_SCHEME=smtps
MAIL_USERNAME=info@novawavedev.com
MAIL_PASSWORD=<secreto>
MAIL_FROM_ADDRESS=info@novawavedev.com
MAIL_FROM_NAME="GYM-BROS"
SESSION_SECURE_COOKIE=true
SESSION_HTTP_ONLY=true
SESSION_SAME_SITE=lax
```

No se necesita MP_PUBLIC_KEY para redirigir a Checkout Pro. Mantener APP_KEY
estable y respaldada: cifra los datos pendientes. El logo debe existir realmente
en storage/app/public y public/storage debe estar enlazado. No se inventa una ruta.
Configurar APP_URL como URL HTTPS publica para firmar enlaces. Activar MP_ENABLED
solo despues de migrar y verificar credenciales. No activar live_mode con cuentas
de prueba. Las cookies no se usan para las nuevas rutas: Sanctum Bearer de 8 horas.
Al habilitar MP, CORS queda limitado a FRONTEND_URL; revisar los clientes existentes.

## Rutas

```text
POST /api/checkout/mercado-pago
GET /api/checkout/{orden_uuid}/estado
POST /api/webhooks/mercado-pago
POST /api/checkout/login
POST /api/checkout/{orden_uuid}/password
POST /api/pagos/{pago}/reembolso
```

Todas responden JSON; errores de validacion 422 con message/errors. Sin habilitar
responden 503. Checkout requiere Idempotency-Key UUID persistente por intento:
reutilizarlo en reintentos del mismo formulario, no generar uno por cada clic.
Las URLs de retorno son FRONTEND_URL/checkout/success, /pending y /failure.
Ningun retorno activa datos. El frontend consulta estado usando el UUID guardado.

```json
{
  "plan_id": 1,
  "usuario": {"nombres":"Ana","apellidos":"Prueba","apodo":"Ana","genero":"Mujer","correo":"ana@example.test","tipo_documento":"DNI","numero_documento":"00123456","telefono":"912345678","fecha_registro":"2026-09-22","fecha_nacimiento":"1998-04-15","tipo_usuario":"Empresa"},
  "empresa": {"nombre":"Gimnasio de prueba","nombre_gerente":"Ana Prueba","telefono":"987654321","correo":"gym@example.test"}
}
```

Todos los campos de usuario del ejemplo son obligatorios. genero acepta Varon o
Mujer; tipo_documento acepta DNI, PASAPORTE u OTRO. tipo_usuario solo acepta
Empresa y el servidor impone ese rol al activar la compra. Las fechas usan
YYYY-MM-DD: registro no futuro y nacimiento no posterior al registro.
inicio_suscripcion y fin_suscripcion personales permanecen null.
La fecha de registro recibida se conserva; no cambia las fechas del pago o del
plan SaaS. No se solicita contrasena durante el checkout.

201:
```json
{"data":{"orden_id":"UUID","checkout_url":"https://www.mercadopago.com.pe/checkout/...","estado":"checkout_creado"}}
```

Consulta de estado (sin datos personales, hashes ni tokens):
```json
{"data":{"estado":"aprobado","plan":"Plan contratado","monto":"99.90","moneda":"PEN","estado_suscripcion":"activa"}}
```

El precio y duracion provienen exclusivamente del plan activo. Importe comparado
en centavos exactos; snapshot inmutable aunque el plan cambie despues.
La orden caduca en 24 horas. Una aprobacion fechada fuera de ese intervalo se
retiene para conciliacion, no se activa silenciosamente. Rechazos no crean empresas.
Conflictos de correo durante el pago y segundos pagos distintos de una misma orden
requieren conciliacion/reembolso por soporte; no generan registros duplicados.

Login: correo y password; devuelve data.token y token_type Bearer. El alta por
correo abre FRONTEND_URL/establecer-contrasena?url=<URL firmada de la API>.
El frontend envia POST a esa URL sin modificar su query, con password y
password_confirmation. Minimo 12 caracteres, letras y numeros. No registrar esa URL
en analitica ni logs de acceso; contiene un secreto temporal. Configurar el proxy
para ocultar el query de esta ruta. No guardar tarjetas, CVV ni payloads de proveedor.

Reembolso: Authorization Bearer, body {"motivo":"Solicitud del cliente"}.
Solo Empresa/Administrador activo, de la misma empresa del pago y con capacidad
pagos:reembolsar. Hasta fin del quinto dia calendario posterior a la aprobacion,
hora Peru. Se admite solo reembolso total. Confirmacion por proveedor y reconsulta
del pago antes de marcar reembolsado; suscripcion pasa a cancelada.

## Webhook, colas y recuperacion

En Mercado Pago configurar Webhooks, evento payment, URL HTTPS indicada y copiar
la firma secreta. Verificar x-signature (HMAC SHA256), x-request-id y data.id de
query; PHP puede convertirlo a data_id. Se exige coincidencia con el cuerpo.
Ventana de timestamp: 5 minutos; servidor debe tener reloj sincronizado.
Se encola el ID y se responde 200. Worker consulta /v1/payments/{id}; compara
ID, external_reference, moneda, importe y live_mode. Reconsulta bajo bloqueo de
orden para eventos concurrentes. Una transaccion crea empresa, usuario,
suscripcion y pago una sola vez. Nunca aprueba usando el body del webhook.

```shell
php artisan migrate --path=database/migrations/2026_09_22_200000_prepare_checkout.php
php artisan queue:work database --tries=5 --timeout=60
php artisan schedule:run
```

Supervisar workers y ejecutar el scheduler de produccion regularmente. Las tareas
Windows antiguas solo llaman sus comandos diarios y NO procesan esta cola.
No se iniciaron workers de pagos ni tareas Windows nuevas en esta preparacion.
El scheduler vuelve a encolar confirmaciones pendientes cada hora. Un fallo de
correo no revierte la compra. Cola database explicita incluso si default=sync.
Revisar failed_jobs y reintentar tras corregir el problema, sin habilitar logs de
payloads sensibles. Una caida SMTP despues de aceptar correo puede repetir un
mensaje; la compra permanece idempotente. Si el enlace caduca, soporte debe
reemitirlo; no hay endpoint publico de reenvio en esta primera entrega.

Preferences API no documenta garantia de idempotencia remota como refunds. Se
envia X-Idempotency-Key y se serializa localmente, pero una respuesta perdida puede
crear otra preferencia remota para la misma orden. Solo una activacion local es
posible. Conciliar pagos duplicados reales, no confundir con webhooks repetidos.

## Bloqueos antes de produccion

- Faltan credenciales de Mercado Pago y HTTPS publico de la API. SMTP esta
  configurado localmente, pero el envio real aun debe verificarse. El logo
  predeterminado local es empresas/logo-predeterminado-gymbros.webp; copiar
  ese archivo tambien al storage publico del servidor de produccion.
- Sanctum protege solo rutas nuevas: las rutas antiguas de empresas, usuarios,
  planes y pagos siguen sin una politica global de acceso. No exponer el backend
  completo a Internet antes de protegerlas; permitirian alterar datos por fuera
  del checkout. Esta tarea no cambia sus permisos, por compatibilidad solicitada.
- composer audit reporta avisos existentes en Laravel 11.56.0 (URLs firmadas y
  validacion email). Se rechazan controles CR/LF y el enlace exige ademas token
  hasheado ligado a la orden, pero esto NO sustituye actualizar a Laravel soportado
  antes de produccion. No se actualizo Laravel mayor de forma silenciosa.
- Las migraciones historicas no coinciden totalmente con la DB local (enum
  Adm0inistrador frente a Administrador y fechas de usuarios). No se reescriben.
- Verificar medios de pago habilitados en la cuenta peruana real; no se promete
  Yape o saldo sin confirmarlo en el checkout del proveedor.

## Referencias oficiales

- https://www.mercadopago.com.pe/developers/es/reference/online-payments/checkout-pro-preferences/create-preference/post
- https://www.mercadopago.com.pe/developers/es/docs/checkout-pro-preferences/additional-content/notifications/webhooks
- https://www.mercadopago.com.pe/developers/es/reference/online-payments/checkout-api-payments/create-refund/post

## Pruebas

MercadoPagoCheckoutTest usa SQLite aislado, Http::fake, Queue::fake y Mail::fake;
prohibe requests externos. tests/Support/checkout-schema-mysql.php crea y elimina
una base temporal exclusiva para probar up/down/up en MySQL local.
No se insertan compradores ficticios en la base principal ni se llama a MP real.

Resultado de la suite general durante esta entrega: 355 pruebas, 73 errores por
fixtures antiguos de usuarios.inicio_suscripcion y 3 fallos por expectativas de
horarios/fecha_registro de empresas. No se alteraron esos tests para ocultarlos.
Composer audit: 3 entradas (dos avisos distintos) de laravel/framework existente.
