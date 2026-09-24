# Arquitectura del frontend — Gym Bros

Documento práctico del estado actual (fases 1 a 5 completadas). Explica cómo
está montado el proyecto y cómo crecer sobre él sin romperlo.

## 1. Stack

| Pieza         | Elección                                    | Motivo                                         |
| ------------- | ------------------------------------------- | ---------------------------------------------- |
| Framework     | Vue 3 (`<script setup>`)                    | Requisito del proyecto                         |
| Bundler       | Vite 8                                      | Arranque y build rápidos, alias sencillos      |
| Rutas         | Vue Router 5                                | Router oficial; guards y lazy loading          |
| Estado global | Pinia 4                                     | Store oficial de Vue 3                         |
| HTTP          | Axios 1                                     | Interceptores para token y errores             |
| UI            | Bootstrap 5.3 (parciales) + Bootstrap Icons | Formularios, botones y alertas ya resueltos    |
| Gráficos      | Chart.js 4                                  | Visualización encapsulada del Dashboard        |
| Calidad       | ESLint 10 + Prettier 3                      | Lint y formato                                 |
| Estilos       | Sass (sólo build)                           | Compila la selección de parciales de Bootstrap |
| Pruebas       | Vitest 4 + Vue Test Utils                   | Comparte la config de Vite                     |

Sin TypeScript, sin Nuxt, sin Tailwind, sin Vuex.

## 2. Estructura

```text
src/
├── assets/
│   ├── fonts/          Inter y Montserrat en WOFF2 subconjuntado
│   ├── images/         marca · ilustraciones
│   └── styles/         _variables.css (tokens) · base.css · main.css · bootstrap.scss
├── components/
│   ├── base/           ConfirmDialog.vue · PageHeader.vue · IconoMancuerna.vue
│   └── layout/         AppHeader.vue · AppSidebar.vue · UserMenu.vue · …
├── composables/        useListadoFiltrable.js · useFormulario.js · useVistaPreviaArchivo.js
├── config/             env.js  (único lector de import.meta.env)
├── constants/          regionesPeru.js
├── layouts/            AuthLayout.vue · DashboardLayout.vue
├── mocks/              auth · dashboard · empresas · usuarios · notificaciones
├── modules/            auth · dashboard · empresas · usuarios
├── router/             index.js · guards.js · navegacion.js
├── services/           api.js · http-error.js · normalizacion.js · *.service.js
├── stores/             auth.store.js · ui.store.js
├── utils/              formato.js · iniciales.js · validaciones.js
├── views/              NotFoundView.vue · EnConstruccionView.vue
├── App.vue
└── main.js
```

Las carpetas se crean únicamente al aparecer una responsabilidad real:
`composables/` apareció cuando dos listados demostraron necesitar la misma
lógica, no antes.

## 3. Flujo de datos

```text
Vista / Componente
        ↓  (llama a una función del servicio)
    Servicio            src/services/*.service.js
        ↓  (mock o HTTP, decide aquí y sólo aquí)
     api.js             instancia única de Axios
        ↓
  API REST Laravel 11
```

Prohibido saltarse un paso. Un componente nunca importa `axios`.

El **store** (Pinia) se apoya en el servicio y guarda el resultado; no habla con
Axios directamente.

## 4. Modo mock

`VITE_USE_MOCKS=true` hace que los servicios respondan desde `src/mocks/`.

Los mocks se cargan con `import()` **dinámico** dentro de la rama `if (USE_MOCKS)`.
No es un detalle de estilo: con un import estático, Rollup no podía separarlos y
los datos simulados —incluidas las credenciales de demostración— acababan en el
bundle de producción. Ver `src/config/env.js` y el plugin de `vite.config.js`.
El interruptor está **sólo** en la capa de servicios; el store, el router y las
vistas no saben si hay backend o no.

Credenciales de desarrollo (`src/mocks/auth.mock.js`):

```text
admin@gymbros.test / password123
```

No son un secreto: sólo funcionan contra el mock y dejan de existir con
`VITE_USE_MOCKS=false`.

Los mocks se importan de forma estática, así que el módulo entra en el bundle
también en producción. Es ~1 KB y ninguna ruta puede alcanzarlo con los mocks
apagados; si algún día molesta, se convierte en `await import(...)`.

## 5. Variables de entorno

Se leen **exclusivamente** en `src/config/env.js`, que convierte los booleanos y
aporta valores por defecto para que la app arranque sin `.env`.

| Variable            | Por defecto                    | Para qué              |
| ------------------- | ------------------------------ | --------------------- |
| `VITE_APP_NAME`     | `Gym Bros`                     | Títulos y marca       |
| `VITE_API_BASE_URL` | `http://localhost:8000/api/v1` | Base de la API        |
| `VITE_USE_MOCKS`    | `true`                         | Datos simulados sí/no |

`.env` está ignorado por Git; se versiona sólo `.env.example`. Todo lo que empieza
por `VITE_` acaba en el bundle público: **nunca poner ahí claves ni tokens**.

## 6. Autenticación (temporal)

1. `LoginView` llama a `auth.store.iniciarSesion()`.
2. El store llama a `auth.service.iniciarSesion()`, que hoy responde desde el mock.
3. El store guarda `usuario` y `token` y los persiste con `session.storage.js`.
4. `guards.js` deja pasar o redirige según `meta.requiresAuth` / `meta.guestOnly`.

`api.js` ya envía `Authorization: Bearer <token>` en cada petición.

> **Aviso de seguridad.** `localStorage` no es un mecanismo de seguridad: es
> legible por cualquier script inyectado en la página. Se usa para no perder la
> sesión simulada al recargar durante el desarrollo. El mecanismo definitivo
> depende de lo que implemente Natan (Sanctum con cookies httpOnly, o token
> Bearer). Al decidirlo, el único archivo a cambiar es `session.storage.js`.

## 7. Errores HTTP

El interceptor de respuesta de `api.js` convierte cualquier fallo en un
`HttpError` con `status`, `message` y `errors`, con mensajes por defecto para
0/401/403/404/422/500 y respetando el `message` que envíe Laravel. Un 401 dispara
el manejador registrado en `main.js`, que limpia la sesión local y vuelve al login.

El mock lanza el **mismo** `HttpError`, así que las vistas ya tratan los errores
como lo harán con el backend real.

## 8. Cómo ejecutar

```bash
npm install
cp .env.example .env
npm run dev
```

| Script            | Qué hace                             |
| ----------------- | ------------------------------------ |
| `npm run dev`     | Servidor de desarrollo (puerto 5173) |
| `npm run build`   | Build de producción en `dist/`       |
| `npm run preview` | Sirve el build                       |
| `npm run lint`    | ESLint, falla con cualquier aviso    |
| `npm run format`  | Formatea con Prettier                |
| `npm run test`    | Pruebas unitarias                    |

## 9. Cómo añadir un módulo nuevo

Ejemplo con una sección que todavía usa la pantalla «En construcción».

1. **Servicio** — `src/services/ejercicios.service.js`. Se apoya en
   `services/normalizacion.js` para la paginación de Laravel, los campos
   editables y la traducción de los 422; escribe su propio `normalizarEjercicio`,
   que es su contrato. El interruptor `USE_MOCKS` vive aquí y en ningún otro
   sitio, con `import()` dinámico del mock.

2. **Listado** — `src/modules/ejercicios/views/EjerciciosView.vue`, sobre
   `useListadoFiltrable`. No se copia `EmpresasView`: filtros en la URL, rebote
   de búsqueda, paginación y descarte de respuestas obsoletas ya están resueltos.

   ```js
   const { estadoVista, items, paginacion, busqueda, filtros, cambiarFiltro } = useListadoFiltrable(
     {
       nombreRuta: 'ejercicios-listado',
       cargar: obtenerEjercicios,
       filtros: { status: { permitidos: ['all', 'active', 'inactive'] } },
       mapearParametros: ({ status }) => ({ estado: status }),
       mensajeDeError: 'No pudimos cargar los ejercicios.',
     },
   )
   ```

3. **Navegación** — la sección ya existe en `SECCIONES` de
   `src/router/navegacion.js`. Basta con darle su `vista`, o declarar su árbol
   CRUD en `router/index.js` como hacen Empresas y Usuarios, conservando el
   nombre del padre para que el enlace del menú siga activo.

4. **Formulario** — sobre `useFormulario`, que ya resuelve carga de valores
   iniciales, errores 422 por campo, limpieza al escribir y foco en el primer
   error. Las reglas de forma (correo, teléfono, color, URL, fecha) salen de
   `utils/validaciones.js`; el módulo escribe sólo las suyas. Si hay imagen,
   `useVistaPreviaArchivo`.

5. **Componentes** — se extrae un subcomponente cuando hay reutilización real o
   la vista se vuelve difícil de leer, no por norma.

6. **Store** — en `src/stores/` **sólo** si el estado lo necesita más de una
   vista. Un listado no lo necesita: su estado vive en la URL.

## 10. Pendiente para la integración con Laravel

- Cerrar con Natan el contrato real de `/auth/login` y `/auth/logout`. Lo que hay
  en `auth.service.js` es una suposición provisional.
- Decidir el mecanismo de sesión (Sanctum con cookies vs. token Bearer) y ajustar
  `session.storage.js` y el interceptor de `api.js`.
- Confirmar el prefijo real de la API (`/api/v1`) y la política de CORS.
- Definir cómo viajan los roles y permisos, para ampliar los guards.
- Poner `VITE_USE_MOCKS=false` y borrar los mocks que ya no hagan falta.

## 11. Dashboard administrativo — Fase 3

El Dashboard mantiene estado local y consume una única frontera de datos:

```text
DashboardView → dashboard.service.js → dashboard.mock.js / GET /dashboard
```

`GET /dashboard` es provisional hasta cerrar el contrato con Natan. La normalización
vive en el servicio, por lo que una futura respuesta de Laravel no obliga a cambiar
componentes. Chart.js se usa directamente y se destruye al desmontar el gráfico.

## 12. Decisiones y restricciones del shell administrativo

Implementado en Fase 2:

- **Rutas de los módulos.** Empresas, Usuarios, Ejercicios, Alimentación y
  Planes comerciales tienen árboles propios. Notificaciones, Reportes de pagos
  y Perfil mantienen su ruta real apuntando a la vista compartida de «En
  construcción». Todas heredan `requiresAuth` del registro padre.
- **Reflow (WCAG 2.1 AA, 1.4.10).** El shell actual usa un sidebar de 280 px
  fijos, así que por debajo de ~640 px de ancho equivalente —lo que produce un
  zoom del 400 % en una pantalla de 1280 px— el contenido deja de ser usable. No
  es un caso móvil: es un usuario con baja visión en escritorio. El layout de la
  Fase 2 debe contemplar un punto de ruptura en el que el menú pase a superponerse
  en lugar de robar ancho al contenido.
- **Cabeceras de seguridad.** El artefacto es estático, así que `Content-Security-Policy`,
  `Strict-Transport-Security`, `X-Content-Type-Options` y `frame-ancestors` los
  pone el servidor que lo sirva, no este repositorio. Hay que decidirlos al
  definir el despliegue con Natan; sin ellos, guardar el token en `localStorage`
  no tiene ninguna mitigación frente a un XSS.

## 13. Deuda técnica conocida

- **Subida de imágenes.** El selector de logo y el de foto de perfil muestran
  vista previa pero no envían el archivo: falta acordar con Natan si va en
  `multipart/form-data` dentro del propio POST/PUT o en un endpoint previo que
  devuelva la URL. El campo lo advierte de forma explícita en vez de aparentar
  que guarda.
- **JavaScript de Bootstrap.** No se importa: no hace falta. Si algún día se
  necesitan modales o dropdowns suyos, hay que añadir el bundle **y** el parcial
  correspondiente en `bootstrap.scss`.

Resuelto desde la revisión de código:

- El CSS de Bootstrap ya no viaja entero (310 KB → 37 KB): sólo se compilan los
  parciales en uso.
- Las fuentes ya no se cargaban dos veces ni en TTF (1489 KB → 184 KB).
- Los mocks y las credenciales de demostración ya no entran en el bundle de
  producción.
- Los formularios ya no duplican su mitad no visual: `useFormulario`,
  `useVistaPreviaArchivo` y `utils/validaciones.js`.
- Hay verificación automática en CI y medición de cobertura.
- Los iconos son SVG en línea (`IconoSvg.vue` + `assets/iconos.js`), no una
  fuente. `assets/__tests__/iconos.spec.js` impide tanto usar un icono que no
  esté en el catálogo como dejar en él iconos que ya nadie usa.
- `ConfirmDialog` bloquea el scroll de fondo y atrapa el foco de verdad;
  `UserMenu` implementa el patrón `menu` con flechas, Home y End.

## 14. Empresas — Fase 4

El módulo utiliza rutas hijas anidadas para que el enlace del sidebar permanezca
activo en listado, alta, detalle y edición:

```text
/empresas → listado
/empresas/nueva → alta
/empresas/:id → detalle
/empresas/:id/editar → edición
```

El flujo conserva la frontera de datos del proyecto:

```text
Vistas de Empresas → empresas.service.js → empresas.mock.js / API Laravel
```

`empresas.service.js` normaliza tanto el contrato mock como variantes habituales
en `snake_case` de Laravel. Expone listado paginado, detalle, alta, actualización
y desactivación; las vistas no conocen `USE_MOCKS`, Axios ni la forma cruda de la
respuesta HTTP. El mock mantiene una colección mutable durante la sesión y lanza
los mismos `HttpError` 404/422 que la integración real.

Decisiones provisionales que deben confirmarse con backend:

- endpoints `GET/POST /empresas`, `GET/PUT /empresas/:id` y `DELETE /empresas/:id`;
- valores provisionales de estado `active` / `inactive` tanto en filtros como en payloads; el normalizador también tolera `activo` / `inactivo` al leer;
- `DELETE` representa desactivación lógica, no borrado físico;
- RUC es opcional y admite de 8 a 11 dígitos;
- la subida de logo todavía conserva únicamente una vista previa local;
- nombres definitivos de paginación y errores 422.

## 15. Usuarios — Fase 5

Mismo patrón de rutas anidadas que Empresas, para que el enlace del sidebar siga
activo en todo el árbol:

```text
/usuarios → listado
/usuarios/nuevo → alta
/usuarios/:id → detalle (perfil + historial)
/usuarios/:id/editar → edición
```

```text
Vistas de Usuarios → usuarios.service.js → usuarios.mock.js / API Laravel
```

El listado se apoya en `useListadoFiltrable` con cuatro filtros —empresa, estado,
suscripción y rol— más búsqueda. La empresa es el único que no lleva lista de
valores permitidos: su valor es un id, no una lista cerrada.

El desplegable de empresas se pide a `obtenerOpcionesEmpresas()`, que cruza al
servicio de Empresas. Es acoplamiento consciente entre módulos y tiene un límite
conocido: pide 100 empresas y **descarta en silencio a partir de ahí**. Con más
de 100, ese filtro necesitará su propio endpoint o paginación.

Decisiones provisionales que deben confirmarse con backend:

- endpoints `GET/POST /usuarios`, `GET/PUT /usuarios/:id`, `DELETE /usuarios/:id`
  y `GET /usuarios/:id/historial`;
- `tipo_usuario` con valores `admin` / `manager` / `trainer` / `member`;
- forma de la suscripción anidada (`estado`, fechas, días restantes, plan);
- el historial se entrega como `{ id, fecha, accion, descripcion, autor }`; las
  vistas confían en esa forma y no aceptan variantes;
- `DELETE` es desactivación lógica, igual que en Empresas;
- la foto de perfil conserva únicamente vista previa local.
