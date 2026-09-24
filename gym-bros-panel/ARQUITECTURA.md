# Arquitectura SaaS Frontend Modular — Gym Bros Web

Documentación oficial y exhaustiva de la arquitectura del frontend de **Gym Bros Web**, desarrollada en **Vue 3 (Composition API + `<script setup>`) + Vite + Pinia + Vue Router + Axios + Vitest + Lucide Icons**.

---

## 1. Visión y Principios de Diseño

1. **Modularidad y Escalabilidad**: Cada funcionalidad de negocio (`empresas`, `usuarios`, `ejercicios`, `alimentacion`, `membresias`, `notificaciones`, `billing`, `suscripciones`, `auditoria`) vive en su propio módulo autocontenido dentro de `src/modules/`.
2. **SaaS Multi-Tenancy Nativo**: Aislamiento y contexto de inquilinos (`tenant.store.js`, `tenant.service.js`, `useTenant.js`), cabeceras HTTP dinámicas (`X-Tenant-ID`) y layouts diferenciados (`PlatformLayout` vs `TenantLayout`).
3. **Control de Acceso Basado en Roles (RBAC)**: Estrategia declarativa y granular con `permissions.js`, `roles.js`, y la directiva / composable `can.js`.
4. **Mocks Modulares y Aislados**: Carga dinámica mediante `USE_MOCKS` que garantiza que los mocks no contaminen el bundle de producción final.
5. **Separación Estricta de Dominios de Negocio**:
   - `modules/membresias/`: Planes y membresías que los socios pagan al gimnasio cliente.
   - `modules/suscripciones/`: Suscripciones SaaS que las empresas/gimnasios pagan a Gym Bros SaaS.
   - `modules/billing/`: Facturación, pagos de empresas y pasarelas de cobro.
6. **Resiliencia y Tipado de Errores**: Manejo canónico de errores con `HttpError`, normalización bidireccional (`snake_case` del backend Laravel a `camelCase` del frontend).
7. **100% Cobertura y Verificación Automatizada**: 290 tests unitarios y de integración pasando al 100%, compilación limpia con Vite y 0 advertencias de linter.

---

## 2. Topología del Árbol de Directorios (`src/`)

```
src/
├── app/                               # Configuración y orquestación global de la aplicación
│   ├── guards/                        # Navigation guards del router
│   │   ├── auth.guard.js              # Validación de sesión y rutas guest-only
│   │   ├── tenant.guard.js            # Validación de inquilino activo
│   │   ├── permission.guard.js        # Verificación RBAC de permisos
│   │   ├── title.guard.js             # Sincronización del título de la pestaña
│   │   ├── index.js                   # Registro secuencial de guards
│   │   └── __tests__/guards.spec.js   # Tests de los guards
│   ├── layouts/                       # Layouts del sistema
│   │   ├── AppLayout.vue              # Layout contenedor
│   │   ├── AppHeader.vue              # Cabecera global
│   │   ├── AppSidebar.vue             # Barra lateral con navegación dinámica
│   │   ├── SidebarNavItem.vue         # Ítem recursivo de navegación
│   │   ├── UserMenu.vue               # Menú de perfil y cierre de sesión
│   │   ├── NotificationButton.vue     # Botón de alertas y notificaciones
│   │   ├── AuthLayout.vue             # Layout para pantallas de autenticación
│   │   ├── DashboardLayout.vue        # Layout base del dashboard
│   │   ├── PlatformLayout.vue         # Layout específico para superadministradores de la plataforma
│   │   ├── TenantLayout.vue           # Layout específico con branding de la empresa/inquilino
│   │   └── __tests__/                 # Tests unitarios de layouts
│   ├── navigation/                    # Catálogo declarativo de rutas del menú
│   │   ├── navegacion.js              # Definición de secciones, iconos y permisos
│   │   └── __tests__/navegacion.spec.js # Tests de integridad de navegación
│   └── router/                        # Vue Router modular
│       └── index.js                   # Ensamblador de rutas modulares y vistas globales
│
├── core/                              # Capa central agnóstica de negocio
│   ├── api/                           # Cliente HTTP y utilidades de comunicación
│   │   ├── api.js                     # Instancia de Axios configurada
│   │   ├── interceptors.js            # Inyección de Bearer tokens y manejo de 401
│   │   ├── http-error.js              # Clase de error normalizada con errores de campo
│   │   └── normalizacion.js           # Adaptadores de paginación, listados y errores 422
│   ├── auth/                          # Dominio de autenticación central
│   │   ├── auth.service.js            # Servicio de login, logout y refresco
│   │   ├── auth.store.js              # Store Pinia de sesión, roles y usuario actual
│   │   └── __tests__/auth.store.spec.js # Tests del store de autenticación
│   ├── config/                        # Configuración de entorno
│   │   └── env.js                     # Variables de entorno y flags de mocks
│   ├── permissions/                   # Sistema RBAC
│   │   ├── permissions.js             # Catálogo de permisos del sistema
│   │   ├── roles.js                   # Matriz de permisos por rol
│   │   ├── can.js                     # Composable y verificador de permisos
│   │   └── __tests__/can.spec.js      # Tests de verificación RBAC
│   ├── storage/                       # Persistencia local
│   │   └── session.storage.js         # Wrapper tipado de sessionStorage / localStorage
│   └── tenant/                        # Multi-tenancy
│       ├── tenant.service.js          # Consulta de datos del inquilino
│       ├── tenant.store.js            # Store de inquilino activo y personalización
│       ├── useTenant.js               # Composable de contexto multi-tenant
│       └── __tests__/tenant.store.spec.js # Tests de multi-tenancy
│
├── shared/                            # Componentes, composables y utilidades transversales
│   ├── components/                    # Componentes UI reutilizables
│   │   ├── ConfirmDialog.vue          # Modal de confirmación accesible con soporte polimórfico
│   │   ├── PageHeader.vue             # Cabecera estándar de sección
│   │   ├── LogoGymBros.vue            # Isotipo e isotipo vectorial de marca
│   │   ├── IconoMancuerna.vue         # Icono gráfico de entrenamiento
│   │   └── __tests__/ConfirmDialog.spec.js # Tests del modal de confirmación
│   ├── composables/                   # Composables reutilizables
│   │   ├── useBreakpoint.js           # Detección responsiva de pantallas
│   │   ├── useDebounce.js             # Debounce para campos de búsqueda
│   │   ├── useFormulario.js           # Gestión reactiva de formularios, errores remotos y foco
│   │   ├── useListadoFiltrable.js     # Paginación, ordenamiento y filtros en URL
│   │   └── useVistaPreviaArchivo.js   # Previsualización segura de imágenes cargadas
│   ├── constants/                     # Constantes de negocio generales
│   │   ├── index.js                   # Constantes comunes
│   │   └── regionesPeru.js            # Catálogo de departamentos y provincias del Perú
│   ├── stores/                        # Stores globales de UI
│   │   └── ui.store.js                # Control de sidebar, tema y diálogos
│   ├── utils/                         # Funciones de utilidad pura
│   │   ├── formato.js                 # Formato de fechas, montos y números
│   │   ├── iniciales.js               # Extracción de iniciales de nombres
│   │   ├── validaciones.js            # Validadores de RUC, DNI, emails y URLs
│   │   └── __tests__/                 # Tests de utilidades
│   └── validators/                    # Validadores de esquemas
│       └── index.js
│
├── modules/                           # Módulos de funcionalidad (Feature Modules)
│   ├── auth/                          # Inicio de sesión y recuperación
│   │   ├── mocks/auth.mock.js         # Mock de autenticación
│   │   ├── views/LoginView.vue        # Vista de login
│   │   ├── views/__tests__/LoginView.spec.js # Tests de la vista de login
│   │   └── routes.js                  # Rutas del módulo
│   │
│   ├── dashboard/                     # Métricas y analíticas
│   │   ├── components/                # MetricCard, ProgressChart, RecentActivity, PopularExercises
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/dashboard.mock.js    # Mock de dashboard
│   │   ├── services/dashboard.service.js # Servicio de métricas
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/DashboardView.vue    # Vista principal
│   │   ├── views/__tests__/           # Tests de la vista
│   │   └── routes.js                  # Rutas del dashboard
│   │
│   ├── empresas/                      # Gestión de sedes y gimnasios clientes
│   │   ├── components/                # EmpresaForm, EmpresaStatusBadge, etc.
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/empresas.mock.js     # Mock de empresas
│   │   ├── services/empresas.service.js # Servicio CRUD de empresas
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # EmpresasView, EmpresaCreateView, EmpresaEditView, EmpresaDetailView
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de empresas
│   │
│   ├── usuarios/                      # Gestión de usuarios, socios y staff
│   │   ├── components/                # UsuarioForm, UsuarioSubscriptionBadge, etc.
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/usuarios.mock.js     # Mock de usuarios
│   │   ├── services/usuarios.service.js # Servicio CRUD de usuarios
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # UsuariosView, UsuarioCreateView, UsuarioEditView, UsuarioDetailView
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de usuarios
│   │
│   ├── ejercicios/                    # Catálogo de entrenamiento y ejercicios
│   │   ├── components/                # EjercicioForm, EjercicioStatusBadge, etc.
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/ejercicios.mock.js   # Mock de ejercicios
│   │   ├── services/ejercicios.service.js # Servicio CRUD de ejercicios
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # EjerciciosView, EjercicioCreateView, EjercicioEditView, EjercicioDetailView
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de ejercicios
│   │
│   ├── alimentacion/                  # Planes nutricionales, comidas y alimentos
│   │   ├── catalogos.js               # Catálogo de tipos de alimentos, comidas y unidades
│   │   ├── components/                # AlimentoForm, ComidaForm, AlimentoTipoBadge, etc.
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/alimentacion.mock.js # Mock de planes, comidas y alimentos
│   │   ├── services/alimentacion.service.js # Servicio CRUD de nutrición
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # PlanesView, PlanDetailView, AlimentosView, etc.
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de alimentación
│   │
│   ├── membresias/                    # Membresías de socios del gimnasio (antes `planes`)
│   │   ├── catalogos.js               # Catálogo de servicios y duraciones de membresías
│   │   ├── components/                # PlanCard, PlanForm, PlanGrid
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/membresias.mock.js   # Mock de membresías
│   │   ├── services/membresias.service.js # Servicio CRUD de membresías
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # PlanesView, PlanCreateView, PlanEditView
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de membresías
│   │
│   ├── notificaciones/                # Mensajería y notificaciones push/programadas
│   │   ├── catalogos.js               # Canales, prioridades y audiencias
│   │   ├── components/                # NotificacionCard, NotificacionForm, NotificacionPreview
│   │   ├── components/__tests__/      # Tests de componentes
│   │   ├── mocks/notificaciones.mock.js # Mock de notificaciones
│   │   ├── services/notificaciones.service.js # Servicio de notificaciones
│   │   ├── services/__tests__/        # Tests del servicio
│   │   ├── views/                     # NotificacionesView
│   │   ├── views/__tests__/           # Tests de vistas
│   │   └── routes.js                  # Rutas modulares de notificaciones
│   │
│   ├── billing/                       # Facturación y pagos SaaS
│   │   ├── mocks/billing.mock.js      # Mock de pagos y facturas
│   │   ├── services/billing.service.js # Servicio de pagos y reportes
│   │   ├── services/__tests__/        # Tests del servicio de billing
│   │   └── routes.js                  # Rutas modulares de facturación
│   │
│   ├── suscripciones/                 # Suscripciones SaaS para gimnasios (Gym Bros SaaS)
│   │   └── routes.js                  # Rutas modulares de suscripciones SaaS
│   │
│   └── auditoria/                     # Registro de actividades y auditoría de seguridad
│       └── routes.js                  # Rutas modulares de auditoría
│
├── views/                             # Vistas de estado global
│   ├── NotFoundView.vue               # Error 404 (Página no encontrada)
│   ├── ForbiddenView.vue              # Error 403 (Acceso no autorizado / RBAC)
│   ├── ServerErrorView.vue            # Error 500 (Fallo interno del servidor)
│   └── EnConstruccionView.vue         # Pantalla para módulos en desarrollo
│
├── assets/                            # Recursos estáticos globales (imágenes, logos)
├── App.vue                            # Componente raíz
└── main.js                            # Punto de entrada de la aplicación
```

---

## 3. Matriz de Roles y Permisos (RBAC)

| Módulo / Recurso    | Super Admin  | Admin Gimnasio (Tenant) |       Entrenador       |     Nutricionista      |      Recepción      |
| :------------------ | :----------: | :---------------------: | :--------------------: | :--------------------: | :-----------------: |
| **Empresas**        | Total (CRUD) |  Solo lectura (Propia)  |       Sin acceso       |       Sin acceso       |     Sin acceso      |
| **Usuarios**        | Total (CRUD) |      Total (Sede)       | Solo lectura (Alumnos) | Solo lectura (Alumnos) | Registro / Búsqueda |
| **Ejercicios**      | Total (CRUD) |      Total (Sede)       |      Total (CRUD)      |      Solo lectura      |     Sin acceso      |
| **Alimentación**    | Total (CRUD) |      Total (Sede)       |      Solo lectura      |      Total (CRUD)      |     Sin acceso      |
| **Membresías**      | Total (CRUD) |      Total (Sede)       |      Solo lectura      |      Solo lectura      | Asignación / Cobro  |
| **Notificaciones**  | Total (CRUD) |      Total (Sede)       |    Envío a alumnos     |   Envío a pacientes    |     Sin acceso      |
| **Billing / Pagos** | Total (CRUD) |    Facturación Sede     |       Sin acceso       |       Sin acceso       | Consulta de cobros  |
| **Auditoría**       | Total (CRUD) |      Logs de sede       |       Sin acceso       |       Sin acceso       |     Sin acceso      |

---

## 4. Guía de Ejecución y Validación

- **Suite de Pruebas**:
  ```bash
  npm test
  # 42 archivos de test, 290 tests pasando al 100%
  ```
- **Compilación de Producción**:
  ```bash
  npm run build
  # Genera el bundle optimizado sin advertencias ni errores
  ```
- **Linter de Código**:
  ```bash
  npm run lint
  # 0 errores, 0 advertencias
  ```
- **Servidor de Desarrollo**:
  ```bash
  npm run dev
  ```
