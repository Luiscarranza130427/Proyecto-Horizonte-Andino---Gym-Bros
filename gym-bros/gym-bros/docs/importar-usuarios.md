# Importacion masiva de usuarios

## Rutas

POST /api/usuarios/importar
GET /api/usuarios/importar/plantilla

Authorization: Bearer TOKEN de login real; Accept: application/json.
POST recibe multipart/form-data con archivo (.csv o .xlsx).
Administrador debe enviar id_empresas del destino; Empresa NO lo envia:
se obtiene de su cuenta autenticada. Otros roles, inactivos y anonimos no acceden.
No se admiten roles, contrasenas ni empresa por fila. No existe importacion XLS.

201:
```json
{"data":{"importados":2,"id_empresas":1,"correos_encolados":2,"mensaje":"Usuarios importados correctamente. Los correos para establecer contrasena quedaron en cola."}}
```

422 (no se guarda nada):
```json
{"message":"No se importo ningun usuario. Corrige los errores indicados.","errors":{"filas.3.correo":["El correo ya esta registrado. No se actualizan usuarios existentes."]}}
```

Fila 1 = encabezados; fila 2 = primer usuario. En CSV con saltos dentro de
campos entrecomillados, se numera el registro, no la linea fisica del archivo.
Errores estructurales pueden indicar archivo o filas.N. Errores de datos se
acumulan por campo; encabezados/lectura/formulas se detienen al primer error.
401 sin token, 403 sin permiso, 429 exceso de solicitudes, 503 fallo de guardado.
No reintentar automaticamente: ante una respuesta perdida, consultar usuarios
antes de reenviar. Reenvio de archivo ya importado se rechaza sin duplicar cuentas.

## Plantilla

El GET descarga plantilla-usuarios.csv en UTF-8, delimitado por punto y coma.
Puede completarse en Excel y guardarse como CSV UTF-8 o XLSX de una sola hoja.
No es el mismo contrato que exportar usuarios: usar la plantilla de importacion.

Obligatorios:
- nombres, apellidos, apodo: texto, maximo 100.
- genero: Varon o Mujer.
- correo: email maximo 255, normalizado a minusculas sin espacios externos.
- tipo_documento: DNI, PASAPORTE u OTRO.
- numero_documento, telefono: texto, maximo 12; conservar ceros iniciales.
- fecha_nacimiento: YYYY-MM-DD, no futura.

Opcionales:
- direccion: maximo 150.
- fecha_registro: YYYY-MM-DD, por defecto fecha actual; no futura ni anterior al nacimiento.
- inicio_suscripcion, fin_suscripcion: YYYY-MM-DD o vacios (null); fin >= inicio si ambos existen.

En XLSX, configurar documento/telefono como Texto ANTES de escribirlos; no basta
aplicar formato visual 00000000 a numeros. Se rechazan numeros para no perder
ceros inadvertidamente. Fechas Excel reales con formato de fecha son aceptadas.
CSV acepta coma o punto y coma, UTF-8 con/sin BOM. Maximo 200 usuarios y 5 MB
(el servidor PHP puede imponer un limite menor; revisar upload_max_filesize y
post_max_size). XLSX: sin formulas, macros, enlaces externos ni multiples hojas,
maximo 20 MB descomprimido y 500 entradas ZIP. No se conserva el archivo subido.

## Atomicidad y correo

Cada carga valida todos los datos. Si hay errores no guarda usuarios ni jobs.
Si una fila falla al guardar, rollback completo. Duplicados del archivo y de DB
se rechazan, incluidos usuarios inactivos. Indice unico correo protege cargas
concurrentes. Se bloquea empresa y se revalida existencia dentro de transaccion.
Se crean cuentas activas tipo Usuario con id_empresas del destino y un marcador
aleatorio NO autentificable en password_hash. No es una contrasena en texto plano:
AuthController lo rechaza hasta que el usuario establezca su clave mediante email.
Nunca se asigna ni envia una contrasena compartida.

La misma transaccion encola jobs cifrados en recuperacion-password. Un 201
significa guardado y encolado, NO entrega confirmada. SMTP no bloquea el POST.
El correo de alta reutiliza el enlace y token de recuperacion (60 minutos,
hash en DB, un uso), con texto Establece tu contrasena. Si vence, el usuario puede
solicitar otro desde Olvide mi contrasena. No cambia comportamiento del checkout.

IMPORTANTE: el enlace aun usa la URL configurada en auth.password_reset_url.
Si https://novawavedev.com/restablecer-contrasena no esta publicada, el correo
llegara pero la pagina devolvera 404. Publicar esa pantalla (Vue o Next.js) y
configurar una URL confiable HTTPS es necesario para completar el alta.
No se cambia esa URL ni se desactiva HTTPS como parte de esta importacion.

## Despliegue

- Nueva dependencia: openspout/openspout 4.32.0 para leer XLSX por streaming.
  Fuente: https://github.com/openspout/openspout/tree/4.x/docs
- PHP requiere extension zip, activada en php.ini de Laragon. Reiniciar PHP
  cuando se despliegue. Composer install instala la dependencia del lockfile.
- Migracion: 2026_09_24_000000_unique_correo_usuarios.php. No crea tablas nuevas,
  solo el indice unico. Aborta si hay correos duplicados normalizados; no borra
  usuarios. Down quita el indice, preservando los registros.
- Worker database --queue=recuperacion-password debe estar activo y usar la misma
  conexion de DB. Reiniciarlo al desplegar los nuevos jobs. failed_jobs permite
  reintentar errores SMTP. SMTP configurado exclusivamente en Laravel.
- No se importaron usuarios reales ni se enviaron correos reales durante QA.
- Composer sigue reportando avisos previos de laravel/framework; la dependencia
  nueva no actualiza Laravel ni resuelve esos avisos de produccion.

## Vue

Agregar Importar usuarios junto a Exportar CSV/Nuevo usuario. Solo Empresa y
Administrador. Modal con Descargar plantilla, selector CSV/XLSX, aviso del limite
y de importacion completa o ninguna. Administrador selecciona empresa; Empresa
no muestra selector. No pedir contrasenas ni roles.
Enviar FormData con archivo y, solo Administrador, id_empresas. No fijar
Content-Type manualmente. Deshabilitar boton mientras se procesa. En 201 mostrar
cantidad y aclarar que los correos quedaron en cola; refrescar listado. En 422
mostrar errores por numero de fila y campo sin cerrar el modal. No decir que se
enviaron todos los correos. Manejar 401,403,429,503 sin reintentos automaticos.

## Pruebas

ImportarUsuariosTest usa SQLite aislado, archivos temporales y Mail fake. Cubre
CSV/XLSX, fechas, roles, empresa, duplicados, errores, rollback y alta por enlace.
