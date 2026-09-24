# Gym Bros — Frontend web

Panel administrativo de escritorio del SaaS Gym Bros. Vue 3 + Vite.

Este repositorio es sólo el frontend web para PC. La aplicación móvil y la API
REST (Laravel 11) son proyectos independientes.

## Requisitos

Node.js `^20.19.0` o `>=22.12.0`.

## Puesta en marcha

```bash
npm install
cp .env.example .env
npm run dev
```

La aplicación queda en <http://localhost:5173>.

Como el backend todavía no existe, arranca en **modo mock** (`VITE_USE_MOCKS=true`).
Credenciales de desarrollo:

```text
admin@gymbros.test / password123
```

Sólo funcionan contra el mock local; no son credenciales reales.

## Scripts

| Script                  | Qué hace                            |
| ----------------------- | ----------------------------------- |
| `npm run dev`           | Servidor de desarrollo              |
| `npm run build`         | Build de producción en `dist/`      |
| `npm run preview`       | Sirve el build generado             |
| `npm run lint`          | ESLint (falla ante cualquier aviso) |
| `npm run format`        | Formatea con Prettier               |
| `npm run test`          | Pruebas unitarias con Vitest        |
| `npm run test:coverage` | Pruebas con informe de cobertura    |

> En Windows, ejecutar los scripts desde PowerShell o CMD. Desde Git Bash el
> lanzador de npm de este equipo falla con `""node"" no se reconoce`.

## Verificación automática

Cada push a `main` y cada pull request ejecutan
[`.github/workflows/ci.yml`](.github/workflows/ci.yml): lint, formato, pruebas
con cobertura y build de producción.

El workflow incluye además un guardián propio: comprueba que en `dist/` no
aparezca ningún dato simulado ni las credenciales de demostración. Si alguien
vuelve a importar `@/mocks` de forma estática, la fuga se detecta en CI y no en
producción, donde la aplicación seguiría funcionando sin dar ninguna señal.

Los umbrales de cobertura se mantienen uno o dos puntos por debajo de lo medido
(hoy ~68%). No son un objetivo de calidad, son un trinquete contra el retroceso:
con más holgura se puede perder cobertura real durante meses sin que salte.

## Recursos estáticos

Las fuentes van **autoalojadas en WOFF2 subconjuntado** al rango latino
(`src/assets/fonts/`). No se enlaza ningún CDN de tipografías. Regenerarlas desde
un `.ttf` no hace falta para compilar; si alguna vez se necesita, requiere
`fonttools` y `brotli` de Python y el comando está documentado en
`src/assets/styles/base.css`.

Los **iconos son SVG en línea** (`src/components/base/IconoSvg.vue`), no una
fuente. Para añadir uno hay que copiar sus trazos a `src/assets/iconos.js`; la
prueba del catálogo falla en CI si se olvida.

De Bootstrap **sólo se compilan los parciales que se usan**
(`src/assets/styles/bootstrap.scss`). Para emplear una clase de un componente
que no esté en esa lista hay que añadir antes su `@import`, o la clase existirá
en el HTML sin ningún estilo.

Antes de añadir una imagen, comprobar su peso frente al tamaño al que se muestra.

## Rutas

Todo lo que cuelga de `/` requiere sesión: `requiresAuth` va en el registro
padre y Vue Router lo hereda, de modo que una ruta nueva no puede quedarse
pública por olvido.

| Ruta                                   | Acceso                            |
| -------------------------------------- | --------------------------------- |
| `/login`                               | Sólo sin sesión                   |
| `/dashboard`                           | Requiere sesión                   |
| `/empresas`                            | Requiere sesión                   |
| `/empresas/nueva`                      | Requiere sesión                   |
| `/empresas/:id`                        | Requiere sesión                   |
| `/empresas/:id/editar`                 | Requiere sesión                   |
| `/usuarios`                            | Requiere sesión                   |
| `/usuarios/nuevo`                      | Requiere sesión                   |
| `/usuarios/:id`                        | Requiere sesión                   |
| `/usuarios/:id/editar`                 | Requiere sesión                   |
| `/ejercicios`                          | Requiere sesión                   |
| `/ejercicios/nuevo`                    | Requiere sesión                   |
| `/ejercicios/:id`                      | Requiere sesión                   |
| `/ejercicios/:id/editar`               | Requiere sesión                   |
| `/alimentacion`                        | Requiere sesión                   |
| `/planes`                              | Requiere sesión                   |
| `/planes/nuevo`                        | Requiere sesión                   |
| `/planes/:id/editar`                   | Requiere sesión                   |
| `/perfil`, `/notificaciones`, `/pagos` | Requiere sesión · en construcción |
| `/404` y cualquier otra                | Pública                           |

## Documentación

- [`docs/FRONTEND_ARCHITECTURE.md`](docs/FRONTEND_ARCHITECTURE.md) — estructura,
  flujo de datos, modo mock, integración pendiente con Laravel.
- [`docs/MODELO_DE_DATOS.md`](docs/MODELO_DE_DATOS.md) — esquema de la base de
  datos: qué guarda cada tabla y cómo se relacionan.
- [`docs/PANELES.md`](docs/PANELES.md) — qué contiene cada pantalla del panel, y
  cuánto se desvía de eso lo ya construido.
- [`CLAUDE.md`](CLAUDE.md) — convenciones del proyecto.

## Estado

| Fase | Alcance                                         | Estado     |
| ---- | ----------------------------------------------- | ---------- |
| 1    | Fundación del frontend                          | Completada |
| 2    | Layout administrativo (sidebar y header)        | Completada |
| 3    | Dashboard (KPIs, gráfico y estados)             | Completada |
| 4    | Módulo de Empresas (CRUD, filtros, paginación)  | Completada |
| 5    | Módulo de Usuarios (CRUD, filtros, historial)   | Completada |
| 6    | Módulo de Ejercicios (CRUD, catálogo y filtros) | Completada |
| 7    | Módulo de Alimentación                          | Completada |
| 8    | Módulo de Planes comerciales                    | Completada |

Los módulos restantes —notificaciones, reportes de pagos y perfil— usan la
pantalla compartida «En construcción» y pertenecen a fases posteriores.

Nada de esto habla todavía con Laravel: el backend está en desarrollo y la
aplicación funciona íntegramente contra `src/mocks/`.
