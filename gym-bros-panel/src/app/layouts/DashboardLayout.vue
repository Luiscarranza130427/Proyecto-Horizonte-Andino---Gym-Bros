<script setup>
import Lenis from 'lenis'
import { nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { RouterView, useRoute } from 'vue-router'

import AppHeader from '@/app/layouts/AppHeader.vue'
import AppSidebar from '@/app/layouts/AppSidebar.vue'
import { useTenantStore } from '@/core/tenant/tenant.store'
import { useUiStore } from '@/shared/stores/ui.store'

const ui = useUiStore()
const tenant = useTenantStore()
const route = useRoute()
const contenidoPrincipal = ref(null)
const contenidoLenis = ref(null)
let lenis = null
let cuadroAnimacion = null

function iniciarDesplazamientoSuave() {
  if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return
  if (!contenidoPrincipal.value || !contenidoLenis.value) return

  lenis = new Lenis({
    wrapper: contenidoPrincipal.value,
    content: contenidoLenis.value,
    duration: 1.5,
    easing: (t) => Math.min(1, 1.001 - 2 ** (-10 * t)),
    smoothWheel: true,
    wheelMultiplier: 1.1,
  })

  const raf = (tiempo) => {
    lenis?.raf(tiempo)
    cuadroAnimacion = window.requestAnimationFrame(raf)
  }
  cuadroAnimacion = window.requestAnimationFrame(raf)
}

onMounted(() => {
  if (!tenant.tenant) {
    tenant.cargarTenant()
  }
  iniciarDesplazamientoSuave()
})

onBeforeUnmount(() => {
  if (cuadroAnimacion) window.cancelAnimationFrame(cuadroAnimacion)
  lenis?.destroy()
  lenis = null
})

watch(
  () => route.fullPath,
  async () => {
    await nextTick()
    if (contenidoPrincipal.value) {
      if (lenis) lenis.scrollTo(0, { immediate: true })
      else contenidoPrincipal.value.scrollTop = 0
    }
  },
)
</script>

<template>
  <div class="panel" :class="{ 'panel--compacto gb-panel--compacto': ui.sidebarCompacto }">
    <a class="gb-salto-contenido" href="#contenido-principal">Saltar al contenido</a>

    <AppSidebar class="panel__sidebar" />
    <AppHeader class="panel__header" />

    <main id="contenido-principal" ref="contenidoPrincipal" class="panel__contenido" tabindex="-1">
      <div ref="contenidoLenis" class="panel__contenido-interno">
        <RouterView />
      </div>
    </main>
  </div>
</template>

<style scoped>
.panel {
  display: grid;
  grid-template-columns: var(--gb-sidebar-ancho) minmax(0, 1fr);
  grid-template-rows: var(--gb-header-alto) minmax(0, 1fr);
  grid-template-areas:
    'sidebar header'
    'sidebar contenido';
  height: 100%;
  width: 100%;
  background-color: var(--gb-bg);
  overflow: hidden;
}

.panel--compacto {
  grid-template-columns: var(--gb-sidebar-ancho-compacto) minmax(0, 1fr);
}

.panel__sidebar {
  grid-area: sidebar;
}

.panel__header {
  grid-area: header;
  position: sticky;
  top: 0;
  z-index: 30;
}

.panel__contenido {
  grid-area: contenido;
  min-width: 0;
  padding: var(--gb-margen);
  overflow-y: auto;
}

.panel__contenido-interno {
  min-height: 100%;
}

@media (max-width: 64rem) {
  .panel {
    grid-template-columns: var(--gb-sidebar-ancho-compacto) minmax(0, 1fr);
  }

  .panel__contenido {
    padding: var(--gb-gutter) var(--gb-espacio);
  }
}

@media (max-width: 48rem) {
  .panel__contenido {
    padding: 1rem 0.75rem;
  }
}
</style>
