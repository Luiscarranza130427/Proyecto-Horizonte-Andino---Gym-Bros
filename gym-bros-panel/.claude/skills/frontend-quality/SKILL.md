---
name: frontend-quality
description: >-
  Revisión de calidad del frontend web de Gym Bros (Vue 3, Vite, Pinia, Axios,
  Bootstrap 5). Usar al terminar un módulo, componente o fase, antes de dar el
  trabajo por cerrado, para auditar arquitectura, capa de servicios, estado,
  accesibilidad, seguridad, duplicación y dependencias.
---

# Revisión de calidad — frontend Gym Bros

Auditoría de lo que se acaba de tocar. Las convenciones están en `CLAUDE.md` y la
arquitectura en `docs/FRONTEND_ARCHITECTURE.md`; aquí sólo va **qué comprobar**.

Revisar únicamente los archivos modificados. Corregir lo que se encuentre, no
limitarse a listarlo.

## 1. Arquitectura y capas

- [ ] Ninguna vista o componente importa `axios` ni llama a la API directamente.
- [ ] Toda llamada al backend pasa por un servicio de `src/services/`.
- [ ] Ningún `USE_MOCKS` ni import de `@/mocks` fuera de `src/services/`.
- [ ] Ninguna URL de backend ni valor de entorno leído fuera de `src/config/env.js`.
- [ ] Cada módulo vive en `src/modules/<modulo>/`; nada de lógica de un módulo
      esparcida por otro.
- [ ] Sin capas inventadas (repositorios, casos de uso, factorías) que no
      resuelvan un problema real de hoy.

## 2. Vue

- [ ] `<script setup>` y Composition API; nada de Options API.
- [ ] Estado derivado con `computed()`, no con variables duplicadas ni `watch`.
- [ ] `v-for` con `:key` estable (nunca el índice si hay id).
- [ ] Props nunca mutadas en el hijo; comunicación hacia arriba con `emit`.
- [ ] Sin manipulación manual del DOM (`querySelector`, `addEventListener`) donde
      Vue ya ofrece una directiva o un `ref` de plantilla.
- [ ] Componentes enfocados: si una vista ya no se lee de un vistazo, extraer.

## 3. Estado (Pinia)

- [ ] En el store sólo estado que necesitan varias vistas o el router.
- [ ] Estado de una sola pantalla, dentro de la pantalla.
- [ ] Sin datos derivados persistidos que puedan quedar desincronizados.

## 4. Errores y red

- [ ] Los fallos llegan como `HttpError` (`status`, `message`, `errors`) y se
      muestran al usuario en lenguaje claro.
- [ ] Los estados de carga se apagan también cuando hay error (`finally`).
- [ ] Nada de `console.log` olvidado.

## 5. Accesibilidad

- [ ] Todo campo con `<label for>` y `autocomplete` correcto.
- [ ] Acciones en `<button>`/`<a>` reales, nunca `<div @click>`.
- [ ] HTML semántico y jerarquía de encabezados coherente (un solo `h1` por página).
- [ ] Iconos decorativos con `aria-hidden="true"`; los que informan, con texto.
- [ ] Foco visible, navegable con teclado, y mensajes de error con `role="alert"`.
- [ ] Contraste de texto >= 4.5:1.

## 6. Seguridad

- [ ] Sin claves, tokens ni credenciales reales en el código ni en `.env` versionado.
- [ ] Sin `v-html` con contenido que venga del usuario o del backend.
- [ ] Redirecciones (`?redirect=`) validadas como rutas internas.
- [ ] Recordar que las validaciones del frontend son de UX: la autoridad es Laravel.

## 7. Estilos

- [ ] Colores, radios y medidas desde los tokens `--gb-*`; nada de valores sueltos.
- [ ] `<style scoped>` en los componentes; sin `style="..."` repetido en la plantilla.
- [ ] Sin CSS duplicado entre componentes: si se repite, subir a `main.css`.
- [ ] Sin desbordamiento horizontal (`min-width: 0` en los hijos de rejilla/flex).

## 8. Dependencias y limpieza

- [ ] Ninguna dependencia nueva sin justificación; ninguna instalada y sin usar.
- [ ] Sin imports sin usar, código muerto, archivos vacíos ni carpetas de relleno.
- [ ] Nombres del dominio en español y descriptivos.

## 9. Trampas ya pisadas

Comprobaciones nacidas de fallos reales de este repositorio (ver la sección
«Reglas nacidas de errores reales» de `CLAUDE.md`).

- [ ] Ningún `watch` sin `immediate: true` cuyo efecto haga falta también en el
      montaje (bloquear scroll, enfocar, suscribirse).
- [ ] Ningún rol ARIA declarado sin su comportamiento: `role="menu"` implica
      flechas + Home/End; `aria-modal` implica trampa de foco real.
- [ ] Ningún control decorativo: todo `v-model` tiene a alguien que lea su valor.
- [ ] Todo `router.push`/`replace` fuera de un guard lleva `.catch()`.
- [ ] Ningún componente vuelve a normalizar lo que el servicio ya garantiza:
      los `?? datos.otro_nombre` en una vista son ramas muertas que enmascaran
      un cambio de contrato.
- [ ] Los mocks se cargan con `import()` dinámico dentro de `if (USE_MOCKS)`,
      nunca con import estático.
- [ ] Los iconos usados existen en `src/assets/iconos.js`.
- [ ] Al refactorizar no ha quedado huérfano: reglas CSS de bloques eliminados,
      `ref` de plantilla sin variable, imports sin usar.
- [ ] Si se ha escrito lógica nueva, la cobertura **no ha bajado**.

## 10. Comprobación final

Ejecutar de verdad, no suponer (desde PowerShell en Windows):

```bash
npm run lint && npm run test && npm run build
```

Y en el navegador: la ruta cargada, consola sin errores ni avisos de Vue, red sin
404 y sin scroll horizontal.

Y tras fusionar en `main`, no sólo antes: `lint` vuelve a ejecutarse, porque una
fusión puede producir código inválido sin marcar conflicto.

## 11. Alcance de fase

- [ ] No se ha implementado nada de una fase posterior a la pedida.
