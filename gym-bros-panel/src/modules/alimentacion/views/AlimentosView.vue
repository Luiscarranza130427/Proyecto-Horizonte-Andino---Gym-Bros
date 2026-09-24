<script setup>
import { Activity, CheckCircle2, CloudOff, Plus, RotateCw, Utensils } from 'lucide-vue-next'

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
  mensajeExito,
  mensajeExitoRef,
  cargarListado,
  cambiarBusqueda,
  cambiarFiltro,
  cambiarPagina,
  limpiarFiltros,
} = useListadoFiltrable({
  nombreRuta: 'alimentos-listado',
  cargar: obtenerAlimentos,
  // Lista cerrada: con `permitidos`, un valor inventado en la URL cae al valor
  // por defecto y nunca llega al servicio.
  //
  // No hay filtro de situación: `alimentos` NO tiene columna de estado en el
  // esquema. Ofrecerlo habría sido un control decorativo cuyo «Inactivos» no
  // devolvería nunca nada.
  filtros: {
    type: { permitidos: ['all', ...valoresDe(TIPOS_ALIMENTO)] },
  },
  mapearParametros: ({ type }) => ({ tipo: type }),
  // Doce por página: llena tres o cuatro columnas de tarjetas sin dejar huecos,
  // y es lo que el servicio pide por defecto.
  porPagina: 12,
  mensajeDeError: 'No pudimos cargar el catálogo de alimentos.',
  // `deactivated` es la clave que el composable consume del `?notice=`. Aquí la
  // acción que llega desde la ficha es retirar el alimento, no desactivarlo.
  avisos: { deactivated: 'Alimento retirado del catálogo.' },
})
</script>

<template>
  <section class="alimentos">
    <PageHeader
      titulo="Catálogo de alimentos"
      descripcion="Administra los alimentos con los que se arman las comidas de los planes."
      seccion="Catálogo de alimentos"
      :ruta-seccion="{ name: 'alimentos-listado' }"
      etiqueta="Alimentación"
    >
      <template #acciones>
        <RouterLink class="btn btn-primary alimentos__nuevo" :to="{ name: 'alimento-nuevo' }">
          <Plus :size="16" aria-hidden="true" />
          Nuevo alimento
        </RouterLink>
      </template>
    </PageHeader>

    <p
      v-if="mensajeExito"
      ref="mensajeExitoRef"
      class="alimentos__exito"
      role="status"
      tabindex="-1"
    >
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>

    <AlimentoFilters
      :busqueda="busqueda"
      :tipo="filtros.type"
      :cargando="estadoVista === 'loading'"
      @update:busqueda="cambiarBusqueda"
      @update:tipo="cambiarFiltro('type', $event)"
      @limpiar="limpiarFiltros"
    />

    <p class="alimentos__referencia">
      <Activity :size="16" aria-hidden="true" />
      Los valores nutricionales del catálogo se expresan por cada 100 g o 100 ml del alimento.
    </p>

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

    <section v-else-if="estadoVista === 'error'" class="alimentos__estado gb-tarjeta" role="alert">
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos cargar el catálogo</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargarListado">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <section v-else class="alimentos__estado gb-tarjeta" role="status">
      <Utensils :size="48" aria-hidden="true" />
      <h2>
        {{ hayFiltros ? 'No encontramos alimentos' : 'Aún no hay alimentos en el catálogo' }}
      </h2>
      <p v-if="hayFiltros">Prueba con otra búsqueda o limpia los filtros seleccionados.</p>
      <p v-else>Registra el primer alimento para poder armar comidas.</p>
      <button v-if="hayFiltros" type="button" class="btn btn-ghost" @click="limpiarFiltros">
        Limpiar filtros
      </button>
      <RouterLink v-else class="btn btn-primary" :to="{ name: 'alimento-nuevo' }">
        <Plus :size="16" aria-hidden="true" />
        Nuevo alimento
      </RouterLink>
    </section>
  </section>
</template>

<style scoped>
.alimentos {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.alimentos__nuevo,
.alimentos__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
  text-decoration: none;
}

.alimentos__exito {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin: 0;
  padding: 0.75rem 1rem;
  background-color: rgba(var(--gb-green-rgb), 0.08);
  border: 1px solid rgba(var(--gb-green-rgb), 0.28);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-green);
  font-size: var(--gb-tipo-sm);
}

/* La referencia «por 100» no es decorativa: sin ella, 884 kcal de aceite de
   oliva se leen como la ración y no como la medida del catálogo. */
.alimentos__referencia {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: calc(var(--gb-dashboard-gap) * -0.5) 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.alimentos__estado {
  display: grid;
  place-items: center;
  min-height: 24rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.alimentos__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.alimentos__estado h2 {
  margin: 1rem 0 0;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.alimentos__estado p {
  max-width: 30rem;
  margin: 0.5rem 0 1.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
</style>
