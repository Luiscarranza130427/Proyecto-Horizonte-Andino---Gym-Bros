# Design QA — Fases 2, 3 y 4 Gym Bros

## Artifacts

- Dashboard source visual truth: `C:\Users\carra\AppData\Local\Temp\gym-bros-stitch-ref-20260823\stitch_gym_bros_mobile_login_ui\dashboard_strategic_command\screen.png`.
- Login source assets supplied by the user:
  - `C:\Users\carra\AppData\Local\Temp\codex-clipboard-6c36fdc2-b2db-46df-9644-454f5b2e7a07.webp` (Gym Bros lockup).
  - `C:\Users\carra\AppData\Local\Temp\codex-clipboard-508a05a6-97c9-40a1-9615-cec671dbc978.webp` (athlete photo).
- Dashboard implementation screenshot: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\dashboard-final-1280x1024.png`.
- Login implementation screenshot: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\login-final-1280x1024.png`.
- Compact login evidence: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\login-1280x720-final.png`, `login-1024x768-final.png`, and `login-mobile-390x844-final.png`.
- Admin sidebar evidence: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\dashboard-no-sidebar-logout-1280x720.png`.
- Header alignment reference: `C:\Users\carra\AppData\Local\Temp\codex-clipboard-7b835824-7675-472e-9412-a1e320358953.png`.
- Header alignment evidence: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\dashboard-header-aligned-1280x720.png` and `dashboard-header-aligned-1024x768.png`.
- Dashboard comparison: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\dashboard-comparison-iteration-2.png`.
- Login asset comparison: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\login-assets-comparison-final.png`.

## Normalization and state

- Dashboard source pixels: 1600 × 1280.
- Dashboard source CSS target: 1280 × 1024, inferred from the exported Stitch HTML and its 280 px sidebar becoming 350 source pixels. The source was downsampled by 0.8 for comparison (effective source density 1.25).
- Implementation pixels and CSS viewport: 1280 × 1024 at device scale factor 1.
- Primary state: authenticated dashboard, expanded sidebar, dashboard route active.
- Login state: signed out, empty form, email field focused, split desktop layout. Additional compact desktop targets: 1280 × 720 and 1024 × 768; mobile target: 390 × 844.
- Secondary responsive evidence: `dashboard-1024x768.png` and `login-1024x768.png` in `design-qa-evidence`.

## Findings

No actionable P0, P1, or P2 issues remain.

- Fonts and typography: local Montserrat 700/800/900 and Inter 400/600/700 match the Stitch families and preserve the command/data hierarchy. Headline weight, uppercase labels, metric scale, wrapping, and truncation were checked at 1280 and 1024 px.
- Spacing and layout rhythm: sidebar widths are 280/80 px, header is 64 px, page margin is 32 px, container gaps are 24/32 px, and the final dashboard hero is 237.55 px tall versus approximately 240 px in the normalized source. The table/popular-exercise split and four-card metric grid preserve the source proportions.
- Colors and visual tokens: the Iron Core charcoal surface stack, metallic borders, Gym Red, warm secondary text, data green, and amber are centralized in `src/assets/styles/_variables.css`. Tonal layering and hard outlines match the source without introducing diffuse shadows.
- Image quality and asset fidelity: the supplied Gym Bros lockup and athlete photo are used directly, without CSS/SVG substitutes. Stitch's command-stream and exercise/member assets are local copies of the source assets. Crops preserve the subjects, stay sharp, and retain the black/red art direction.
- Copy and content: the English Stitch placeholders were localized to the Gym Bros domain without changing information hierarchy. No CRUD or future module logic was introduced.
- Icons: Bootstrap Icons are used consistently at the same optical size and weight; no new icon dependency or handcrafted SVG was added.
- Accessibility and behavior: labels, autocomplete, keyboard focus, error association, password visibility, loading/disabled state, skip link, active routes, menu Escape behavior, and reduced-motion support are present. At 1024 px the shell compacts without horizontal overflow.
- Responsive access layout: at 1280 × 720, 1024 × 768, and 390 × 844, the document scroll dimensions equal the viewport dimensions. The desktop image remains visible, the mobile image is intentionally hidden, and all login controls remain in view without vertical or horizontal overflow.
- Session actions: the duplicated sidebar logout was removed. “Cerrar sesión” remains available and functional only from the profile menu in the header.
- Header geometry: the sidebar brand row and application header now share the same 64 px height and bottom edge. Toggle, title, search, notification, and profile controls share a measured center line at 31.6–32 px.
- Type system: navigation and dashboard text now use a shared seven-level scale. The header is 20 px, search is 14 px, profile name is 13 px, hero heading is 28 px, and dashboard metrics are capped at 40 px instead of reaching 48 px.

## Comparison history

### Iteration 1

- [P2] Dashboard hero was approximately 291 px tall, about 51 px taller than the normalized Stitch source, pushing all above-the-fold metrics and data panels downward.
- Fix: removed the extra status eyebrow, reduced headline size to the 32 px design token, tightened padding and paragraph spacing, and set the hero minimum to 224 px.
- Evidence before fix: `design-qa-evidence\dashboard-iteration-1.png` and `design-qa-evidence\dashboard-comparison-iteration-1.png`.

### Iteration 2

- Post-fix hero height: 237.55 px, aligned with the approximately 240 px source.
- The four metric cards, table, and popular-exercise panel now begin at the same visual rhythm as the source.
- Evidence after fix: `design-qa-evidence\dashboard-iteration-2.png` and `design-qa-evidence\dashboard-comparison-iteration-2.png`.
- No actionable P0/P1/P2 findings remain.

### Iteration 3

- [P2] The login retained an oversized 44 rem minimum height and generous vertical spacing, creating vertical overflow on 720–768 px-tall desktop viewports.
- Fix: bounded the authentication panel by `100dvh`, reduced its maximum width/height, added height-aware compact spacing, softened the fields to a 14 px radius, and preserved controlled scrolling only for unusually short mobile content.
- [P2] “Cerrar sesión” appeared in both the sidebar and the profile menu, duplicating a global account action.
- Fix: removed the sidebar action and its unused authentication/router state; the profile menu remains the single logout location.
- Evidence after fix: `design-qa-evidence\login-1280x720-final.png`, `design-qa-evidence\login-1024x768-final.png`, `design-qa-evidence\login-mobile-390x844-final.png`, and `design-qa-evidence\dashboard-no-sidebar-logout-1280x720.png`.
- Measured page overflow after fix: 0 px at all three login targets. Sidebar logout buttons: 0; profile logout menu items: 1.

### Iteration 4

- [P2] The sidebar brand row was 88 px tall while the application header was 64 px, leaving their bottom borders visibly misaligned in the supplied capture.
- [P2] Header and dashboard typography used unrelated local sizes: the page title was 24 px, search inherited 16 px, and metrics expanded to 48 px.
- Fix: made the brand row consume the shared 64 px header token, centered every header control on one axis, standardized control heights around 40 px, and introduced a single reusable type scale for layout and dashboard components.
- Evidence after fix: `design-qa-evidence\dashboard-header-aligned-1280x720.png` and `design-qa-evidence\dashboard-header-aligned-1024x768.png`.
- Measured result: brand/header bottom edges both at 64 px; header component center lines differ by no more than 0.4 px. No console warnings or errors.

## Interaction and runtime verification

- Login with the mock credentials navigates to `/dashboard`.
- Empty form validation remains covered by the existing component tests.
- Sidebar collapse/expand changes its measured width from 280 px to 80 px and swaps the horizontal lockup for the compact mark.
- Profile menu opens, closes with Escape, and exposes “Mi perfil” and “Cerrar sesión”.
- Logout returns to `/login`.
- Login dimensions verified at 1280 × 720, 1024 × 768, and 390 × 844 with no document overflow.
- Sidebar contains no logout action; profile-menu logout remains functional and returns to `/login`.
- `/empresas` loads the shared pending-module view and the RouterLink receives the active class; the remaining menu entries share the same routing strategy.
- The notification badge renders with the mock unread count.
- Browser console warnings/errors: none.
- Vite error overlay: absent.
- `npm run lint`, `npm run test` (16 tests), and `npm run build`: passed.

## Fase 3 — Dashboard administrativo

### Evidencia

- Referencia Stitch inspeccionada: `design-qa-evidence\stitch-project-phase3.png` y el export normalizado de 1280 × 1024 citado al inicio de este documento.
- Vista normal: `dashboard-phase3-1280x1024-final.png`, `dashboard-phase3-1366x768-final.png`, `dashboard-phase3-1440x900-final.png` y `dashboard-phase3-1920x1080-final.png`.
- Contenido inferior a 1366 × 768: `dashboard-phase3-1366x768-lower-final.png`.
- Estado de carga: `dashboard-phase3-loading-1366x768.png`.

### Comparación y correcciones

- Se mantuvieron la jerarquía, las superficies oscuras, el borde metálico, el rojo Gym Bros, la grilla de cuatro KPIs y la proporción analítica de la referencia. El contenido se adaptó al dominio solicitado: empresas, usuarios, entrenadores y rutinas activas.
- [P2] La primera composición de actividad reciente quedaba en una distribución 3 + 1 en anchos intermedios. Se cambió a cuatro columnas en escritorio amplio, dos columnas hasta 1440 px y una columna en el ancho compacto del shell.
- [P1] Una fecha de actividad ausente o inválida podía producir `RangeError`. El formateador ahora devuelve “Fecha no disponible” y omite el atributo `datetime` inválido.
- [P2] La frescura se mostraba como “ahora” incluso en loading/error. Ahora se registra únicamente al completar la carga y se recalcula una vez por minuto junto con los tiempos relativos.
- [P2] Las tendencias decimales concatenaban valores crudos. Ahora utilizan el formateador numérico común y un espaciado consistente para porcentajes.
- [P2] Las barras comparativas de ejercicios usaban semántica de progreso de tarea. Ahora son decorativas; el valor legible continúa expuesto como texto.
- [P2] El contrato de backend transportaba un nombre interno de Vue Router. La navegación del CTA queda definida en frontend y el servicio sólo admite el texto recibido.

### Resultado medido

- Sin overflow horizontal en 1280 × 1024, 1366 × 768, 1440 × 900 y 1920 × 1080.
- Cuatro KPIs, un canvas Chart.js y cuatro eventos renderizados en estado normal.
- El CTA “Ver usuarios” navega a `/usuarios`.
- Consola nueva del navegador: cero warnings y cero errores.
- Estados normal, loading, error, retry y colecciones vacías cubiertos entre navegador y pruebas.
- Chart.js queda aislado en el chunk lazy del dashboard y su instancia se destruye al desmontar o al alternar a estado vacío.
- `npm run lint`, `npm run test` (31 pruebas en 8 archivos) y `npm run build`: passed.

## Follow-up polish

- [P3] The supplied login hero is approximately 1.8 MB. It is visually sharp and acceptable for this phase; a later performance pass could create an AVIF/WebP responsive derivative while retaining this source file.

## Fase 4 — Módulo de empresas

### Evidencia

- Referencia Stitch: `C:\Users\carra\AppData\Local\Temp\gym-bros-stitch-ref-20260823\stitch_gym_bros_mobile_login_ui\empresas_strategic_command\screen.png`.
- Comparación normalizada: referencia y `design-qa-evidence\empresas-phase4-1280x1024.png` inspeccionadas juntas antes y después de la corrección responsive.
- Listado final: `empresas-phase4-1366x768-final.png`.
- Formulario final: `empresas-form-phase4-1440x900-final.png`.
- Detalle y confirmación final: `empresas-detail-phase4-1920x1080-final.png` y `empresas-modal-phase4-1920x1080-final.png`.

### Comparación y correcciones

- Se reprodujo la jerarquía de la referencia: cabecera compacta, filtros segmentados, CTA rojo, superficies Iron Core, tabla densa y paginación inferior.
- [P2] A 1280 px, la suma de columnas podía forzar scroll interno y ocultar las acciones. El RUC pasa a una prioridad secundaria hasta 1440 px; empresa, gerente, estado y acciones permanecen visibles.
- [P2] Los avisos de éxito podían reaparecer al refrescar porque vivían en la query. Ahora se consumen con `router.replace` sin recargar datos.
- [P2] El modal no devolvía el foco al disparador. Ahora captura el elemento activo, confina el foco, admite Escape y restaura el foco al cerrar.
- [P2] Se completaron nombres de campos, anuncio de errores, dimensiones de logos, elipsis tipográficas y scroll confinado del modal.
- [P1] Los filtros se deshabilitaban durante cada búsqueda debounced y expulsaban el foco. Ahora permanecen operables, exponen `aria-busy` y el foco continúa en el buscador durante y después de la carga.
- [P1] El formulario de edición podía reenviar conteos y fechas de solo lectura. Ahora carga y emite exclusivamente la lista blanca de campos editables; el adaptador Laravel tampoco serializa esos datos.
- [P2] Se reforzaron teléfono, colores hexadecimales, errores 422 globales/por campo, limpieza entre cambios de `:id` y claves/estado actual del breadcrumb.
- [P1] Un `legend.visually-hidden` situado al final del formulario ampliaba el scroll del documento fuera del `DashboardLayout`; al desplazar esa barra se movían también header/sidebar y aparecía un gran bloque vacío. El `fieldset` ahora toma su nombre accesible de `titulo-estado`, el documento conserva exactamente la altura del viewport y se eliminó el padding inferior duplicado del editor.
- [P2] La barra sticky de acciones terminaba antes del padding inferior del contenido y dejaba ver el formulario que circulaba por debajo como una franja aparentemente transparente. Una extensión opaca de la misma superficie cubre ahora exactamente ese margen (32 px en escritorio y 24 px en el shell compacto), sin alterar la posición ni la interacción de los botones.
- No quedan hallazgos P0, P1 o P2 abiertos.

### Resultado funcional

- Búsqueda con debounce, filtro por estado y paginación sincronizan la URL.
- Alta, detalle, edición, cancelación con cambios y desactivación funcionan con el mock mutable.
- Estados loading, vacío general, vacío por filtros, error con retry, 404 y validación 422 están cubiertos entre navegador y pruebas.
- Las cuatro rutas mantienen “Empresas” activo en el sidebar.
- Sin overflow horizontal en 1366 × 768, 1440 × 900 y 1920 × 1080.
- Formulario inferior verificado también en 1534 × 704 (equivalente al zoom 125 % de la captura aportada): `design-qa-evidence\empresa-edit-zoom125-fixed.png`; header/sidebar permanecen en `top: 0`, scroll externo 0 y acciones a 32 px del borde inferior del contenido.
- Corrección de la franja inferior comparada directamente con la captura aportada y registrada en `design-qa-evidence\empresa-edit-sticky-band-fixed.jpg`; el relleno opaco coincide con el margen medido y no produce overflow horizontal o vertical en 1920 × 894 ni en 800 × 900.
- Consola nueva del navegador: cero warnings y cero errores.
- `npm run lint`, `npm run test` (60 pruebas en 12 archivos) y `npm run build`: passed.

## Implementation checklist

- [x] Branded split login with rounded inputs and preserved authentication logic.
- [x] Reusable DashboardLayout with collapsible sidebar and header.
- [x] Active RouterLink navigation and pending-module routes.
- [x] Notification indicator, profile menu, and functional logout.
- [x] Stitch-aligned dashboard content without CRUD.
- [x] Desktop responsive checks, test suite, build, console check, and visual correction pass.

## Ajuste de marca del sidebar — 2026-08-28

- Fuente visual: `C:\Users\carra\AppData\Local\Temp\codex-clipboard-14fb6bb6-cbc2-4059-b15e-3747beaa4b79.png` (407 × 113 px).
- Implementación enfocada: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\sidebar-logo-after-focused.png` (407 × 113 px).
- Implementación completa: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\sidebar-logo-after.png` (1919 × 922 px).
- Comparación conjunta: `C:\Users\carra\Videos\gym-bros-web\design-qa-evidence\sidebar-logo-comparison.png`.
- Viewport CSS: 1919 × 922 a densidad 1; ambas regiones enfocadas se compararon a 407 × 113 sin reescalado.
- Estado: perfil autenticado con datos mock; sidebar expandido y tema oscuro. El logo fallback cuadrado usa el mismo contenedor que el logo horizontal de la empresa.

### Comparación visual y correcciones

- [P1, corregido] La cabecera incluía el nombre del tenant y “Gym Bros SaaS”, contrario al objetivo de mostrar únicamente la marca. Ambos textos y sus estilos se eliminaron.
- [P1, corregido] La primera iteración dejó la imagen a 128 px de alto dentro de un marco de 48 px, por lo que quedaba recortada. Se fijó un alto efectivo de 48 px con ancho automático y `object-fit: contain`.
- Resultado final: logo completo, centrado, sin caja decorativa ni títulos. El logo horizontal real del tenant dispone de hasta 128 × 48 px; el fallback cuadrado queda en 48 × 48 px.
- Tipografía y copy: no se añadieron estilos tipográficos; se retiró exclusivamente el copy solicitado.
- Espaciado y layout: se conserva la altura original del header y la alineación con la barra superior.
- Color: se mantienen los tokens existentes y no se introdujeron colores nuevos.
- Calidad de imagen: se reutilizan los assets reales, sin estiramiento ni recreaciones.
- No quedan hallazgos P0, P1 o P2 en esta región. No fue necesaria una comparación adicional fuera de la región enfocada porque el cambio no altera navegación ni contenido.
- Interacción comprobada: acceso de prueba, apertura de `/perfil`, render del sidebar expandido; consola sin warnings ni errores.

final result: passed
