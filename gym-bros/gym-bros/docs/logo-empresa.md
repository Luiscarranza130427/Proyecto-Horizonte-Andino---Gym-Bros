# Subir logo de empresa

```text
POST /api/empresas/{id_empresa}/logo
```

Enviar multipart/form-data, campo logo de tipo archivo. En navegadores, FormData
debe generar el Content-Type con su boundary; no configurarlo manualmente.
Enviar Accept: application/json. Se usa POST para la carga multipart, siguiendo
el patron existente de foto de usuario y el procesamiento de archivos de PHP.

Validacion: imagen JPG/JPEG/PNG/WebP, maximo 5120 KB (5 MB). Se comprueba el
contenido mediante las reglas image/mimes, no solo el nombre. No acepta SVG, GIF,
texto ni rutas en este endpoint. No redimensiona ni impone dimensiones especificas.

Guarda con nombre generado en storage/app/public/empresas. En empresas.logo
almacena la ruta relativa empresas/nombre-generado.ext, nunca la ruta de Windows.
Requiere public/storage apuntando a storage/app/public (ya existe en este entorno).

HTTP 200:
```json
{
  "message": "Logo actualizado correctamente.",
  "id_empresa": 1,
  "logo": "empresas/nombre-generado.webp",
  "logo_url": "http://servidor/storage/empresas/nombre-generado.webp"
}
```

Ejemplo de forma, no de un archivo creado. logo_url usa el host y puerto de la
peticion para funcionar desde la red local, sin depender de APP_URL=localhost.
El cliente debe usar esa URL para mostrar el logo y actualizar su estado al subirlo.

HTTP 422: message/errors, incluso sin Accept. Empresa inexistente: 404.
Fallo de disco o persistencia: 500 sin trazas. Un fallo de persistencia revierte
la base y elimina solo el archivo nuevo. Los logos anteriores se conservan porque
pueden estar compartidos con banners u otras empresas. No borra imagenes ajenas.

Solo modifica logo y updated_at. Las rutas de datos generales y personalizacion
siguen iguales; el PUT general conserva compatibilidad con logo como ruta de texto.
No requiere migraciones ni agrega autenticacion: proteger con middleware de
identidad y permisos por empresa antes de usar fuera del entorno de pruebas.

Archivos: UpdateEmpresaLogoRequest.php, EmpresaController.php, routes/api.php y
tests/Feature/ActualizarLogoEmpresaTest.php.
