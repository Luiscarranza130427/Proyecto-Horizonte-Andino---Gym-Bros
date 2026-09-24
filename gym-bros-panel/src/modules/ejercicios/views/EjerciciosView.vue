<script setup>
import { CheckCircle2, CloudOff, Dumbbell, Plus, RotateCw } from 'lucide-vue-next'
import { computed, ref, watch } from 'vue'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import { useListadoFiltrable } from '@/shared/composables/useListadoFiltrable'
import { NIVELES, valoresDe } from '@/modules/ejercicios/catalogos'
import EjercicioFilters from '@/modules/ejercicios/components/EjercicioFilters.vue'
import EjercicioTable from '@/modules/ejercicios/components/EjercicioTable.vue'
import {
  actualizarEstadoEjercicioEmpresa,
  desactivarEjercicio,
  obtenerEjercicios,
} from '@/modules/ejercicios/services/ejercicios.service'
import { leerSesion } from '@/core/storage/session.storage'
import { useTenantStore } from '@/core/tenant/tenant.store'

const tenant = useTenantStore()
const empresaSeleccionadaId = computed(() => {
  if (tenant.tenantId) return tenant.tenantId
  const usuario = leerSesion()?.usuario
  return usuario?.tenantId ?? usuario?.id_empresas ?? null
})

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
  anunciarExito,
} = useListadoFiltrable({
  nombreRuta: 'ejercicios-listado',
  cargar: obtenerEjercicios,
  porPagina: 20,
  // Los filtros son listas cerradas: con `permitidos`, un valor
  // inventado en la URL cae al valor por defecto y nunca llega al servicio.
  filtros: {
    level: { permitidos: ['all', ...valoresDe(NIVELES)] },
    status: { permitidos: ['all', 'active', 'inactive'] },
  },
  mapearParametros: ({ level, status }) => ({
    nivel: level,
    estado: status,
    empresaId: empresaSeleccionadaId.value,
  }),
  mensajeDeError: 'No pudimos cargar los ejercicios.',
  avisos: { deactivated: 'Ejercicio desactivado correctamente.' },
})

// La desactivación se queda en la vista: su texto y su confirmación son propios
// del recurso, no algo que el composable pueda generalizar sin quedarse soso.
const ejercicioSeleccionado = ref(null)
const desactivando = ref(false)
const ejercicioProcesandoId = ref(null)

async function cambiarEstadoEmpresa({ ejercicio, estado }) {
  if (!empresaSeleccionadaId.value) return

  ejercicioProcesandoId.value = ejercicio.id
  mensajeError.value = ''
  try {
    const resultado = await actualizarEstadoEjercicioEmpresa(
      empresaSeleccionadaId.value,
      ejercicio.id,
      estado,
    )
    items.value = items.value.map((item) =>
      item.id === ejercicio.id ? { ...item, estadoEmpresa: resultado.estadoEmpresa } : item,
    )
    mensajeExito.value = resultado.message
  } catch (error) {
    // No hay actualización optimista: el interruptor conserva el estado previo ante 422, 404 o 500.
    mensajeError.value = error?.message || 'No pudimos actualizar el ejercicio para esta empresa.'
  } finally {
    ejercicioProcesandoId.value = null
  }
}

watch(empresaSeleccionadaId, (actual, anterior) => {
  if (actual && actual !== anterior) cargarListado()
})

async function confirmarDesactivacion() {
  if (!ejercicioSeleccionado.value || desactivando.value) return
  desactivando.value = true

  try {
    const { id, nombre } = ejercicioSeleccionado.value
    await desactivarEjercicio(id)
    ejercicioSeleccionado.value = null
    await anunciarExito(`El ejercicio ${nombre} fue desactivado correctamente.`)
  } catch (error) {
    ejercicioSeleccionado.value = null
    mensajeError.value = error?.message || 'No pudimos desactivar el ejercicio.'
    estadoVista.value = 'error'
  } finally {
    desactivando.value = false
  }
}
</script>

<template>
  <section class="ejercicios">
    <PageHeader
      titulo="Ejercicios"
      descripcion="Administra el catálogo de ejercicios disponible para las rutinas."
      seccion="Ejercicios"
      :ruta-seccion="{ name: 'ejercicios-listado' }"
      etiqueta="Catálogo de entrenamiento"
    >
      <template #acciones>
        <RouterLink class="btn btn-primary ejercicios__nuevo" :to="{ name: 'ejercicio-nuevo' }">
          <Plus :size="16" aria-hidden="true" />
          Nuevo ejercicio
        </RouterLink>
      </template>
    </PageHeader>

    <p
      v-if="mensajeExito"
      ref="mensajeExitoRef"
      class="ejercicios__exito"
      role="status"
      tabindex="-1"
    >
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estadoVista === 'success'" class="ejercicios__error" role="alert">
      {{ mensajeError }}
    </p>

    <EjercicioFilters
      :busqueda="busqueda"
      :nivel="filtros.level"
      :estado="filtros.status"
      :cargando="estadoVista === 'loading'"
      @update:busqueda="cambiarBusqueda"
      @update:nivel="cambiarFiltro('level', $event)"
      @update:estado="cambiarFiltro('status', $event)"
      @limpiar="limpiarFiltros"
    />

    <EjercicioTable
      v-if="
        estadoVista === 'idle' ||
        estadoVista === 'loading' ||
        (estadoVista === 'success' && items.length)
      "
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'idle' || estadoVista === 'loading'"
      :empresa-id="empresaSeleccionadaId"
      :ejercicio-procesando-id="ejercicioProcesandoId"
      @cambiar-pagina="cambiarPagina"
      @desactivar="ejercicioSeleccionado = $event"
      @cambiar-estado-empresa="cambiarEstadoEmpresa"
    />

    <section v-else-if="estadoVista === 'error'" class="ejercicios__estado gb-tarjeta" role="alert">
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos cargar los ejercicios</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargarListado">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <section v-else class="ejercicios__estado gb-tarjeta" role="status">
      <Dumbbell :size="48" aria-hidden="true" />
      <h2>
        {{ hayFiltros ? 'No encontramos ejercicios' : 'Aún no hay ejercicios en el catálogo' }}
      </h2>
      <p v-if="hayFiltros">Prueba con otra búsqueda o limpia los filtros seleccionados.</p>
      <p v-else>Registra el primer ejercicio del catálogo.</p>
      <button v-if="hayFiltros" type="button" class="btn btn-ghost" @click="limpiarFiltros">
        Limpiar filtros
      </button>
      <RouterLink v-else class="btn btn-primary" :to="{ name: 'ejercicio-nuevo' }">
        <Plus :size="16" aria-hidden="true" />
        Nuevo ejercicio
      </RouterLink>
    </section>

    <ConfirmDialog
      :abierto="Boolean(ejercicioSeleccionado)"
      titulo="¿Desactivar ejercicio?"
      :descripcion="`${ejercicioSeleccionado?.nombre ?? 'El ejercicio'} dejará de poder asignarse a rutinas nuevas.`"
      :confirmando="desactivando"
      etiqueta-confirmar="Desactivar ejercicio"
      etiqueta-confirmando="Desactivando…"
      @cancelar="ejercicioSeleccionado = null"
      @confirmar="confirmarDesactivacion"
    />
  </section>
</template>

<style scoped>
.ejercicios {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.ejercicios__nuevo,
.ejercicios__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
  text-decoration: none;
}

.ejercicios__exito {
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

.ejercicios__error {
  margin: 0;
  padding: 0.75rem 1rem;
  border-radius: var(--gb-radius-lg);
  font-size: var(--gb-tipo-sm);
}

.ejercicios__error {
  color: var(--gb-error);
  background-color: rgba(var(--gb-red-rgb), 0.08);
  border: 1px solid rgba(var(--gb-red-rgb), 0.28);
}

.ejercicios__estado {
  display: grid;
  place-items: center;
  min-height: 24rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.ejercicios__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.ejercicios__estado h2 {
  margin: 1rem 0 0;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.ejercicios__estado p {
  max-width: 30rem;
  margin: 0.5rem 0 1.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
</style>
