<script setup>
import { CloudOff, RotateCw, Utensils } from 'lucide-vue-next'

import PageHeader from '@/shared/components/PageHeader.vue'
import { useListadoFiltrable } from '@/shared/composables/useListadoFiltrable'
import { TIPOS_ALIMENTO, valoresDe } from '@/modules/alimentacion/catalogos'
import AlimentoFilters from '@/modules/alimentacion/components/AlimentoFilters.vue'
import AlimentoGrid from '@/modules/alimentacion/components/AlimentoGrid.vue'
import { obtenerAlimentos } from '@/modules/alimentacion/services/alimentacion.service'

const {
  estadoVista,
  items,
  paginacion,
  busqueda,
  filtros,
  hayFiltros,
  mensajeError,
  cargarListado,
  cambiarBusqueda,
  cambiarFiltro,
  cambiarPagina,
  limpiarFiltros,
} = useListadoFiltrable({
  nombreRuta: 'alimentacion-listado',
  cargar: obtenerAlimentos,
  filtros: {
    type: { permitidos: ['all', ...valoresDe(TIPOS_ALIMENTO)] },
  },
  mapearParametros: ({ type }) => ({ tipo: type }),
  porPagina: 12,
  mensajeDeError: 'No pudimos cargar el catálogo de alimentos.',
})
</script>

<template>
  <section class="planes">
    <PageHeader
      titulo="Catálogo de alimentos"
      descripcion="Consulta los alimentos disponibles para crear planes de alimentación."
      seccion="Alimentación"
      :ruta-seccion="{ name: 'alimentacion-listado' }"
      etiqueta="Catálogo de alimentos"
    />

    <AlimentoFilters
      :busqueda="busqueda"
      :tipo="filtros.type"
      :cargando="estadoVista === 'loading'"
      @update:busqueda="cambiarBusqueda"
      @update:tipo="cambiarFiltro('type', $event)"
      @limpiar="limpiarFiltros"
    />

    <AlimentoGrid
      v-if="
        estadoVista === 'idle' ||
        estadoVista === 'loading' ||
        (estadoVista === 'success' && items.length)
      "
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'idle' || estadoVista === 'loading'"
      @cambiar-pagina="cambiarPagina"
    />

    <section v-else-if="estadoVista === 'error'" class="planes__estado gb-tarjeta" role="alert">
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos cargar el catálogo de alimentos</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargarListado">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <section v-else class="planes__estado gb-tarjeta" role="status">
      <Utensils :size="48" aria-hidden="true" />
      <h2>
        {{ hayFiltros ? 'No encontramos alimentos' : 'Aún no hay alimentos en el catálogo' }}
      </h2>
      <p v-if="hayFiltros">Prueba con otra búsqueda o limpia los filtros seleccionados.</p>
      <p v-else>Los alimentos registrados aparecerán aquí.</p>
      <button v-if="hayFiltros" type="button" class="btn btn-ghost" @click="limpiarFiltros">
        Limpiar filtros
      </button>
    </section>
  </section>
</template>

<style scoped>
.planes {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.planes__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
  text-decoration: none;
}

.planes__estado {
  display: grid;
  place-items: center;
  min-height: 24rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.planes__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.planes__estado h2 {
  margin: 1rem 0 0;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.planes__estado p {
  max-width: 32rem;
  margin: 0.5rem 0 1.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
</style>
