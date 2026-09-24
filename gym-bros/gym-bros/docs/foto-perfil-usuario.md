# Actualizacion de foto de usuario

```text
POST /api/usuarios/{id_usuario}/foto-perfil
```

Enviar multipart/form-data con foto_perfil de tipo archivo, no una ruta de texto
ni base64. Formatos JPG, JPEG, PNG o WebP; maximo 5 MB. El cliente debe dejar que
su libreria genere Content-Type con el boundary. Se recomienda Accept: application/json.

El archivo se guarda en storage/app/public/usuario con nombre generado. La base
de datos guarda usuario/<nombre>.<extension> en usuarios.foto_perfil.
public/storage debe enlazar a storage/app/public. El enlace local fue comprobado.

Respuesta 200: message, id_usuario, foto_perfil y foto_url. foto_url usa el esquema,
host y puerto de la peticion, igual que el logo de empresa. El cliente debe usar
esa URL para mostrar la foto y reemplazar la anterior en su estado local.
En un despliegue con proxy, configurar correctamente los proxies de confianza.

Validacion 422: message y errors.foto_perfil, incluso sin Accept.
Usuario inexistente 404: se conserva el campo error del contrato anterior.
Fallo al guardar 500: message generico, sin trazas en la respuesta.

El guardado de la ruta usa una transaccion. Ante fallo se elimina solamente el
archivo nuevo. Las fotos anteriores se conservan, igual que los logos, para no
borrar archivos compartidos. No se modifican otros campos del usuario ni rutas.
La autorizacion existente se conserva; este ajuste no agrega middleware.

Pruebas aisladas: formatos, limite de tamano, validacion JSON, URL con host y
puerto, usuario inexistente, aislamiento, archivos anteriores y rollback de DB
y archivo incluso cuando falla un evento posterior al UPDATE.
