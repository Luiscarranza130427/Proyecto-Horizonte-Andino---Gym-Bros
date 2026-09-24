# Gym Bros — Frontend web administrativo

Panel de administración de escritorio del SaaS Gym Bros. Este repositorio contiene
**únicamente** el frontend web para PC. La app móvil (Joy) y la API (Natan) son
proyectos aparte.

## Stack

Vue 3 · Composition API con `<script setup>` · JavaScript (sin TypeScript) · Vite ·
Vue Router · Pinia · Axios · Bootstrap 5 (sólo los parciales que se usan).

No introducir Nuxt, Tailwind, jQuery, Vuex ni Options API.

## Reglas de arquitectura

- **Alias `@`** para todo import dentro de `src` (`@/core/api/api`), nunca `../../..`.
- **Nunca llamar a Axios desde una vista o componente.** El flujo es
  `Vista → Servicio (src/modules/<modulo>/services) → core/api/api.js → API Laravel`.
- **Nunca escribir la URL del backend en el código.** Sale de `src/core/config/env.js`,
  único sitio que lee variables `VITE_*` (la `import.meta.env.BASE_URL` de Vite
  en `src/app/router/` es la base de despliegue, no configuración de la app).
- **Pinia sólo para estado realmente global** (sesión, estado del shell). Lo que
  usa una sola vista se queda en la vista con `ref()`.
- **El interruptor de mocks vive sólo en la capa de servicios.** No debe aparecer
  `USE_MOCKS` ni un import de `mocks/` en vistas, componentes ni stores. Si una
  vista necesita algo que depende del modo mock, se lo pide al servicio (ver
  `pistaDeCredenciales()` en `auth.service.js`).
- Un módulo funcional = una carpeta en `src/modules/<modulo>/`, con sus propias
  subcarpetas `views/`, `components/`, `services/` y `mocks/`, más su `routes.js`.
- **Un listado administrativo nuevo usa `useListadoFiltrable`**
  (`src/shared/composables/`), no una copia de `EmpresasView`. Filtros en la URL,
  búsqueda con rebote, paginación y descarte de respuestas obsoletas ya están
  resueltos ahí; el módulo aporta su servicio, el mapeo de filtros a parámetros
  y sus textos.
- **Un formulario nuevo usa `useFormulario`** (carga de valores, errores 422 por
  campo, foco en el primer error) y saca sus reglas de forma —correo, teléfono,
  color, URL, fecha— de `src/shared/utils/validaciones.js`. No se reescribe un regex de
  correo: afinarlo en un solo formulario deja al otro rechazando datos válidos.
- **Un servicio de recurso nuevo se apoya en `src/core/api/normalizacion.js`**
  para la paginación de Laravel, los campos editables y la traducción de los 422.
  Lo que sí escribe cada servicio es su propio `normalizarXxx`, que es su contrato.
- **Normalizar es trabajo del servicio, no del componente.** Una vista consume la
  forma que el servicio garantiza y no vuelve a aceptar variantes por su cuenta:
  esos `?? datos.otro_nombre` en un componente no son defensas, enmascaran un
  cambio de contrato que debería fallar a la vista.
- Componentes enfocados: se extrae un subcomponente cuando hay reutilización real
  o la vista se vuelve difícil de leer, no por norma.
- No añadir dependencias sin necesidad real. Cada una debe justificarse.
- No crear carpetas ni archivos vacíos "por si acaso".

## Estructura de carpetas

Tres capas, y cada cosa en la suya:

- **`src/core/`** — lo transversal: `api/` (cliente Axios, normalización,
  `HttpError`), `auth/`, `config/env.js`, `permissions/`, `storage/`, `tenant/`.
- **`src/app/`** — el armazón: `router/`, `guards/`, `layouts/`, `navigation/`.
- **`src/modules/<modulo>/`** — el dominio. Cada módulo lleva DENTRO sus
  `views/`, `components/`, `services/`, `mocks/`, `catalogos.js` y `routes.js`.
- **`src/shared/`** — reutilizable entre módulos: `components/`, `composables/`,
  `utils/`, `constants/`, `stores/`, `validators/`.
- **`src/views/`** — sólo las pantallas de sistema (404, 403, 500, En construcción).

No hay `src/services/`, `src/mocks/`, `src/composables/` ni `src/layouts/` en la
raíz: eso era la estructura anterior.

## Trabajo en paralelo con otro agente

En este repositorio trabajan Claude Code y Codex. No hay canal entre ellos, así
que la coordinación es por fichero y por rama:

- **Una rama por agente.** Editar el mismo árbol de trabajo a la vez es la forma
  más rápida de perder trabajo: el segundo en guardar pisa al primero sin avisar.
- **Confirmar antes de ceder el turno.** Un cambio sin confirmar no existe para
  el otro y un `git checkout` se lo lleva.
- **`AGENTS.md` y `CLAUDE.md` son el mismo contrato** y deben mantenerse
  sincronizados: si uno queda obsoleto, ese agente trabaja con un mapa falso.

## Convenciones de código

- Nomenclatura del dominio en español (`correo`, `contrasena`, `cargando`,
  `iniciarSesion`); las APIs del framework mantienen su nombre original.
- `<style scoped>` en los componentes. Los colores, radios y medidas salen de los
  tokens `--gb-*` de `src/assets/styles/_variables.css`; no escribir colores sueltos.
- **De Bootstrap sólo se compilan los parciales que se usan** (ver
  `src/assets/styles/bootstrap.scss`). Para usar una clase de un componente que
  no esté ya en esa lista —`badge`, `modal`, `table`, utilidades como `py-2`…—
  hay que añadir antes su `@import`, o la clase existirá en el HTML pero no
  tendrá estilo. Si algo aparece sin formato, mirar ahí primero.
- Las fuentes van autoalojadas en WOFF2 subconjuntado; no enlazar Google Fonts
  ni ningún CDN de tipografías.
- **Los iconos vienen de `lucide-vue-next`**, importados como componentes:
  `import { Bell } from 'lucide-vue-next'` y `<Bell :size="16" aria-hidden="true" />`.
  Ya no existe el catálogo propio `src/assets/iconos.js` ni el componente
  `IconoSvg`: se retiraron en la reestructuración por módulos.
- Antes de añadir una imagen a `src/assets/`, comprobar su peso frente al tamaño
  al que se muestra. No servir un original de cámara para un avatar de 32 px.
- HTML semántico, `<label for>` en todos los campos, botones reales (nunca
  `<div @click>`), iconos decorativos con `aria-hidden="true"`.

## Backend

Laravel 11, todavía en desarrollo. El contrato de `/auth/login` y `/auth/logout`
documentado en `src/core/auth/auth.service.js` es **provisional**: no darlo por
cerrado ni inventar contratos nuevos para otros módulos.

**Dos documentos mandan sobre cualquier suposición:**
[`docs/MODELO_DE_DATOS.md`](docs/MODELO_DE_DATOS.md), que dice qué datos hay, y
[`docs/PANELES.md`](docs/PANELES.md), que dice qué se hace con ellos en cada
pantalla. Lo que no figure en ninguno de los dos no se implementa sin acordarlo.

El esquema de la base de datos Antes de decidir los campos de un módulo,
mirarlo: dice qué guarda cada tabla y, sobre todo, de quién cuelga cada cosa.
Dos relaciones que no son obvias y ya causaron modelos equivocados:

- Quien se suscribe a un plan es la **empresa**, no el usuario.
- El catálogo de **ejercicios es por empresa**, y su categoría sale de la tabla
  `grupos_musculares`, no de una lista cerrada en el frontend.

Lo que el esquema no cubra sigue siendo provisional y se marca como tal.

## Fases del proyecto

El trabajo avanza por fases con aprobación entre una y otra. **No adelantar
trabajo de la fase siguiente**, aunque parezca trivial.

- Fase 1 — Fundación del frontend. **Completada.**
- Fase 2 — Layout administrativo (sidebar y header completos). **Completada.**
- Fase 3 — Dashboard administrativo (service, mocks, KPIs, gráfico y estados). **Completada.**
- Fase 4 — Módulo de empresas (CRUD, filtros, paginación y estados). **Completada.**
- Fase 5 — Módulo de usuarios (CRUD, filtros, historial y estados). **Completada.**
- Fase 6 — Módulo de ejercicios (CRUD, filtros por catálogo y estados). **Completada.**
- Fase 7 — Módulo de alimentación (planes alimentarios, comidas y alimentos). **Completada.**
- Fase 8 — Módulo de planes comerciales (fichas, creación y edición). **Completada.**

Los módulos restantes (notificaciones, reportes de pagos y perfil) pertenecen a
fases posteriores y no deben implementarse hasta que se pidan. Hoy usan la
pantalla compartida «En construcción».

## Reglas nacidas de errores reales

Cada una de estas viene de un fallo que ya ocurrió en este repositorio. No son
buenas prácticas genéricas: son las trampas concretas en las que ya caímos.

### Fusiones

- **Verificar la fusión REAL, no una integración propia.** Comprobar que unas
  ramas integran bien en una rama de pruebas propia NO equivale a comprobar la
  fusión que hará GitHub: la base común es distinta y el resultado también.
  Antes de fusionar, hacer en local `git merge origin/<rama>` **sobre
  `origin/main`** y ejecutar ahí la suite completa.

  > Pasó: Git apiló sin marcar conflicto dos `const cargarMock`; `main` quedó con
  > un `SyntaxError` y 21 pruebas rojas.

- **Git puede fusionar dos cambios compatibles y producir código inválido.**
  Tras cualquier fusión, buscar declaraciones de nivel superior repetidas. `npm
run lint` lo detecta («Parsing error: Identifier … has already been declared»);
  ejecutarlo siempre después de fusionar, no sólo antes.

- **Nunca borrar una rama que sea la base de otra PR.** GitHub **cierra** la PR
  dependiente y ya no se puede reabrir; hay que crearla de nuevo. Reapuntar
  primero la dependiente a `main` (`gh pr edit N --base main`) y borrar después.
  > Pasó: `--delete-branch` al fusionar la #4 cerró la #5.

### Código

- **`watch` con `immediate: true` cuando el estado inicial importa.** Si un
  componente puede montarse ya «abierto», «activo» o «con valor», el watcher sin
  `immediate` no ejecuta nada y el efecto (bloquear scroll, enfocar, suscribirse)
  no ocurre. Que hoy ningún padre lo monte así no lo salva: es una trampa
  esperando al primer uso distinto.

- **No declarar un patrón ARIA que no se implementa.** `role="menu"` promete
  navegación con flechas; `aria-modal` promete trampa de foco. Un lector de
  pantalla anuncia lo prometido y el usuario se queda colgado. O se implementa
  entero, o no se declara el rol.

- **Nada de controles decorativos.** Un campo con `v-model` cuyo valor no usa
  nadie es peor que su ausencia: el usuario teclea, pulsa Intro y concluye que la
  aplicación está rota. Si la función no existe todavía, se retira el control.

- **Los fallos silenciosos necesitan una prueba, no un comentario.** Un icono que
  falta no rompe nada: no dibuja. Un mock importado de forma estática no rompe
  nada: viaja al bundle. Cuando el modo de fallo es «sigue funcionando pero mal»,
  hay que añadir la prueba que lo delate; avisarlo en un comentario no basta.

- **Toda promesa de navegación lleva su `.catch()`.** `router.push` rechaza con
  `NavigationFailure` si hay otra navegación en curso, y queda como rechazo sin
  capturar.

- **Al refactorizar, retirar también lo que queda huérfano**: reglas CSS de un
  bloque eliminado, `ref` de plantilla sin variable, imports sin usar. Lint no
  ve el CSS muerto.

### Pruebas

- **Una prueba de ORDEN necesita datos donde los criterios discrepen.** Si se
  comprueba «ordena por hora» con un desayuno a las siete y una cena a las nueve,
  la prueba pasa igual ordenando por tipo de comida, por el campo `orden` o por
  el orden de llegada. Hay que forzar el desacuerdo: un snack de madrugada y un
  desayuno a media mañana. Lo mismo vale para cualquier criterio compuesto.

  > Pasó dos veces el mismo día, en el servicio y en la vista de alimentación:
  > las dos pruebas seguían verdes con el criterio de orden eliminado.

- **El mock TIENE que hablar el contrato del servicio.** En modo mock nadie
  normaliza: el mock _es_ la respuesta. Si el servicio promete
  `objetivos: { calorias }` y el mock emite `caloriasObjetivo`, la vista revienta
  —o peor, pinta un cero— sólo en desarrollo, que es justo donde nadie lo mira
  con lupa. Vale la pena una prueba que compare la forma del mock con la que el
  normalizador garantiza.

- **Verificar rompiendo el código, no confiar en el verde.** Antes de dar por
  buena una prueba, revertir lo que comprueba y confirmar que falla —y que falla
  sólo ella—. Una prueba que pasa con el código roto no prueba nada.

### Cobertura

- **Un umbral con holgura no es un trinquete.** Los umbrales van uno o dos puntos
  por debajo de lo medido. Con cuatro o más se puede perder cobertura real
  durante meses sin que salte nada.

- **Escribir lógica nueva sin prueba se nota en la cobertura: mirarla.** Si baja
  tras un cambio, es que se añadió código sin probar. No dejarlo pasar porque el
  umbral aguante.

## Antes de dar una tarea por terminada

```bash
npm run lint && npm run test && npm run build
```

Los tres tienen que pasar. Si algo falla, corregir la causa: no desactivar reglas
de ESLint ni silenciar avisos para que desaparezcan.

Lo mismo lo ejecuta CI en cada pull request (`.github/workflows/ci.yml`), junto
con `format:check`, la cobertura y una comprobación de que no se filtren datos
simulados al bundle. Ejecutarlo en local antes de subir sigue siendo más rápido
que esperar al workflow.

> Nota de entorno: en este equipo los scripts npm fallan desde Git Bash
> (`""node"" no se reconoce`). Ejecutarlos desde PowerShell o CMD.
