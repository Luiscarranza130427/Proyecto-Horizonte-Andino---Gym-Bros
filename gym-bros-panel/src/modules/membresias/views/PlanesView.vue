<script setup>
import { CheckCircle2, Plus } from 'lucide-vue-next'
import { computed, ref } from 'vue'
import { RouterLink } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import { useAuthStore } from '@/core/auth/auth.store'
import { PERMISOS } from '@/core/permissions/permissions'
import PageHeader from '@/shared/components/PageHeader.vue'
import { useListadoFiltrable } from '@/shared/composables/useListadoFiltrable'
import PlanFilters from '@/modules/membresias/components/PlanFilters.vue'
import PlanGrid from '@/modules/membresias/components/PlanGrid.vue'
import PlanTable from '@/modules/membresias/components/PlanTable.vue'
import {
  eliminarPlanComercial,
  obtenerPlanesComerciales,
} from '@/modules/membresias/services/membresias.service'

const props = defineProps({
  esAdministracion: { type: Boolean, default: false },
})

const planAEliminar = ref(null)
const dialogoEliminarAbierto = ref(false)
const eliminando = ref(false)
const errorEliminacion = ref('')
const vista = ref('cards')
const auth = useAuthStore()
const puedeGestionarPlanes = computed(
  () => props.esAdministracion && auth.can(PERMISOS.MEMBERSHIPS_MANAGE),
)

// El botón queda visible para usuarios no administradores, sin dirigirlos aún a un checkout.
const ENLACE_ADQUISICION = ''

const {
  estadoVista,
  items,
  paginacion,
  busqueda,
  filtros,
  hayFiltros,
  mensajeExito,
  mensajeExitoRef,
  cambiarBusqueda,
  cambiarFiltro,
  cambiarPagina,
  limpiarFiltros,
  anunciarExito,
} = useListadoFiltrable({
  nombreRuta: props.esAdministracion ? 'planes-administrar' : 'planes-listado',
  cargar: obtenerPlanesComerciales,
  porPagina: 6,
  filtros: { estado: { permitidos: ['all', 'active', 'inactive'] } },
  mapearParametros: ({ estado }, b) => ({
    busqueda: b,
    estado,
  }),
  mensajeDeError: 'No pudimos cargar los planes comerciales.',
  avisos: {
    created: 'Plan creado correctamente.',
    updated: 'Plan actualizado correctamente.',
  },
})

function solicitarEliminacion(plan) {
  planAEliminar.value = plan
  dialogoEliminarAbierto.value = true
}

async function confirmarEliminacion() {
  if (!planAEliminar.value || eliminando.value) return
  eliminando.value = true
  errorEliminacion.value = ''

  try {
    const { id, nombre } = planAEliminar.value
    await eliminarPlanComercial(id)
    dialogoEliminarAbierto.value = false
    planAEliminar.value = null
    await anunciarExito(`El plan «${nombre}» fue eliminado correctamente.`)
  } catch (error) {
    // Antes el fallo se descartaba en silencio (p. ej. el 409 de un plan con
    // suscripciones) y el usuario creía que el plan se había eliminado.
    errorEliminacion.value = error?.message || 'No se pudo eliminar el plan.'
    dialogoEliminarAbierto.value = false
    planAEliminar.value = null
  } finally {
    eliminando.value = false
  }
}
</script>

<template>
  <section class="planes-view">
    <PageHeader
      :titulo="esAdministracion ? 'Administrar planes' : 'Planes'"
      :descripcion="
        esAdministracion
          ? 'Configura las ofertas comerciales y membresías disponibles para las empresas.'
          : 'Consulta los planes disponibles para tu empresa.'
      "
      :seccion="esAdministracion ? 'Administrar planes' : 'Planes'"
      :ruta-seccion="{ name: esAdministracion ? 'planes-administrar' : 'planes-listado' }"
      :etiqueta="esAdministracion ? 'Gestión comercial' : 'Planes disponibles'"
    >
      <template #acciones>
        <RouterLink
          v-if="puedeGestionarPlanes"
          class="btn btn-primary planes__nuevo"
          :to="{ name: 'plan-nuevo' }"
        >
          <Plus :size="16" aria-hidden="true" />
          <span>Nuevo plan</span>
        </RouterLink>
      </template>
    </PageHeader>

    <p v-if="mensajeExito" ref="mensajeExitoRef" class="planes__exito" role="status" tabindex="-1">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="errorEliminacion" class="alert alert-danger planes__error" role="alert">
      {{ errorEliminacion }}
    </p>

    <!-- Filtros de búsqueda, estado y selector de vista -->
    <PlanFilters
      v-if="esAdministracion"
      :busqueda="busqueda"
      :estado="filtros.estado"
      :vista="vista"
      :cargando="estadoVista === 'loading'"
      :hay-filtros-activos="hayFiltros"
      :permitir-selector-vista="puedeGestionarPlanes"
      @update:busqueda="cambiarBusqueda"
      @update:estado="cambiarFiltro('estado', $event)"
      @update:vista="vista = $event"
      @limpiar="limpiarFiltros"
    />

    <!-- Vista en Tarjetas Elegantes (por defecto) -->
    <PlanGrid
      v-if="!puedeGestionarPlanes || vista === 'cards'"
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'loading'"
      :gestionable="puedeGestionarPlanes"
      :enlace-adquisicion="ENLACE_ADQUISICION"
      @eliminar="solicitarEliminacion"
      @cambiar-pagina="cambiarPagina"
    />

    <!-- Vista en Tabla CRUD -->
    <PlanTable
      v-else-if="puedeGestionarPlanes"
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'loading'"
      @eliminar="solicitarEliminacion"
      @cambiar-pagina="cambiarPagina"
    />

    <!-- Diálogo de confirmación para eliminar -->
    <ConfirmDialog
      :abierto="dialogoEliminarAbierto"
      titulo="¿Eliminar plan comercial?"
      :mensaje="`¿Estás seguro de que deseas eliminar el plan «${planAEliminar?.nombre ?? ''}»? Esta acción retirará la oferta del catálogo.`"
      etiqueta-confirmar="Eliminar plan"
      etiqueta-cancelar="Cancelar"
      tono="peligro"
      :confirmando="eliminando"
      @cancelar="dialogoEliminarAbierto = false"
      @confirmar="confirmarEliminacion"
    />
  </section>
</template>

<style scoped>
.planes-view {
  display: grid;
  gap: var(--gb-dashboard-gap, 1.5rem);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen, 2rem);
}

.planes__nuevo {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.6rem 1.25rem;
  border-radius: var(--gb-radius-pill, 9999px);
  text-decoration: none;
}

.planes__error {
  margin: 0;
}

.planes__exito {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin: 0;
  padding: 0.75rem 1rem;
  background-color: rgba(var(--gb-green-rgb, 34, 197, 94), 0.08);
  border: 1px solid rgba(var(--gb-green-rgb, 34, 197, 94), 0.28);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-green, #22c55e);
  font-size: var(--gb-tipo-sm);
}
</style>
