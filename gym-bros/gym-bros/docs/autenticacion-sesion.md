# Sesiones Vue y Flutter

Autenticacion independiente de Mercado Pago. No requiere MP_ENABLED ni compras.
Sanctum usa usuarios.password_hash. No acepta contrasenas en texto plano ni
tokens ficticios. No cambia claves existentes automaticamente salvo rehash de
una clave correcta. Correos duplicados normalizados se rechazan por ambiguedad.

## Rutas

POST /api/auth/login
GET /api/auth/me
POST /api/auth/logout

Login JSON: {"correo":"persona@example.com","password":"clave"}.
Correo obligatorio valido (maximo 255), password obligatorio (maximo 255).
Limite cinco intentos por IP por minuto. Respuestas JSON: 422 validacion,
401 credenciales incorrectas o token invalido, 403 cuenta inactiva, 429 limite.
La inactividad solo se informa despues de verificar la clave.

200 login: {"data":{"token":"TOKEN","token_type":"Bearer","expires_at":"ISO8601","usuario":{...}}}.
usuario usa UsuarioResource: id, nombres, apellidos, tipo_usuario, id_empresas y
otros campos de perfil, nunca password_hash. me devuelve {"data":{...usuario}}.
Logout devuelve {"message":"Sesion cerrada correctamente."}.

Enviar Authorization: Bearer TOKEN y Accept: application/json en rutas protegidas.
Cada login crea un token distinto, valido ocho horas. DB guarda solo su hash.
Logout revoca solo ese token, conservando las otras sesiones. No hay refresh token:
al vencer, pedir login de nuevo. No imprimir tokens ni claves en consola/analitica.
Flutter debe usar almacenamiento seguro; Vue preferentemente memoria (o BFF con
cookie HttpOnly para persistencia). HTTPS obligatorio en despliegue.

Eliminar en ambos clientes cualquier fallback de login simulado o token inventado.
Usar data.usuario.tipo_usuario para la navegacion, nunca para sustituir autorizacion
en backend. Ante 401 limpiar sesion y pedir login; un 403 es falta de permiso o
cuenta inactiva, no motivo para reintentar login automaticamente.

## Alcance de proteccion

ApiSesion valida token con capacidad sesion y cuenta activa. Se aplica a me,
logout y GET /api/usuarios/exportar. Esta ultima conserva autorizacion por rol
y empresa. Los tokens generales NO tienen permiso de reembolso.
Las rutas historicas restantes NO quedaron protegidas en bloque: necesitan
aplicar autenticacion y autorizacion por recurso/empresa antes de produccion.
Tener un login no protege automaticamente toda la API. Tampoco se aplica aqui
el bloqueo de empresa por vencimiento de suscripcion.

## Migracion

2026_09_22_195900_create_personal_access_tokens.php se ejecuta independientemente.
La migracion del checkout ya no crea ni elimina esa tabla compartida; la prueba
de checkout incluye la migracion independiente. No se activo Mercado Pago.
Revertir la migracion de tokens elimina todas las sesiones: hacerlo solo tras
detener su uso. No borra usuarios, empresas ni suscripciones.

Pruebas: AuthSesionTest, ExportarUsuariosTest y MercadoPagoCheckoutTest.
