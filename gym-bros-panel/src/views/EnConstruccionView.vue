<script setup>
import { Construction } from 'lucide-vue-next'
import { computed } from 'vue'
import { useRoute } from 'vue-router'

const route = useRoute()

/** El nombre de la sección sale de la ruta: una sola vista sirve para todas. */
const seccion = computed(() => route.meta.title ?? 'Esta sección')
</script>

<template>
  <section class="pendiente">
    <h1 class="pendiente__titulo">{{ seccion }}</h1>

    <div class="gb-tarjeta pendiente__aviso">
      <span class="pendiente__icono" aria-hidden="true">
        <Construction :size="24" />
      </span>

      <div>
        <p class="pendiente__encabezado">Módulo en construcción</p>
        <p class="pendiente__texto">
          La ruta y la navegación ya funcionan. La pantalla de
          <strong>{{ seccion }}</strong> se desarrollará en una fase posterior.
        </p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.pendiente__titulo {
  margin: 0 0 var(--gb-espacio-lg);
  font-size: 1.5rem;
  text-transform: uppercase;
}

.pendiente__aviso {
  display: flex;
  align-items: flex-start;
  gap: var(--gb-espacio);
  max-width: 40rem;
  padding: var(--gb-espacio-lg);
}

.pendiente__icono {
  flex: none;
  color: var(--gb-amber);
  font-size: 1.5rem;
  line-height: 1;
}

.pendiente__encabezado {
  margin: 0 0 0.25rem;
  color: var(--gb-text);
  font-weight: 600;
}

.pendiente__texto {
  margin: 0;
  color: var(--gb-text-muted);
}
</style>
