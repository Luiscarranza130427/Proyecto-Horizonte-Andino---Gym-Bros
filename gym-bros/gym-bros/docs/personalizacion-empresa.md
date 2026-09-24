# Personalizacion de empresa

```text
PUT /api/empresas/{id_empresa}/personalizacion
```

Enviar JSON con uno o mas de estos campos:
color_1, color_2, banner_1, banner_2, banner_3, link_boton_1, link_boton_2, link_boton_3.

Solo actualiza campos enviados y validados. Ignora otros campos (incluidos nombre,
logo, estado e id). No modifica otra empresa ni las rutas anteriores.
Colores: texto no vacio de hasta 10 caracteres, conservando el formato actual.
Banners: rutas de imagen como texto de hasta 300 caracteres, no archivos.
Links de boton: texto de hasta 200 caracteres. Banners y links admiten null
para quitarlos; colores no. Los campos omitidos conservan su valor anterior.

HTTP 200: empresa actualizada dentro de data usando EmpresaResource.
HTTP 422: message y errors, incluso sin Accept; no guarda ningun cambio.
Solicitud vacia o solo con campos ajenos: 422 en errors.datos.
Empresa inexistente con solicitud valida: 404 con message.

No requiere migraciones. Conserva la autenticacion actual; es necesario conectar
los middlewares de identidad y permisos por empresa antes de exponerlo fuera de
pruebas. El id_empresa de la ruta por si solo no autoriza a un cliente.

Archivos: EmpresaController.php, UpdatePersonalizacionEmpresaRequest.php,
routes/api.php y tests/Feature/ActualizarEmpresaTest.php.
