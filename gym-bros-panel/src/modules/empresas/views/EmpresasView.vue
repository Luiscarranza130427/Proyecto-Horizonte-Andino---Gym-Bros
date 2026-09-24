<script setup>
import { Building2, CheckCircle2, CloudOff, Plus, RotateCw } from 'lucide-vue-next'
import { ref } from 'vue'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import { useListadoFiltrable } from '@/shared/composables/useListadoFiltrable'
import EmpresaFilters from '@/modules/empresas/components/EmpresaFilters.vue'
import EmpresaTable from '@/modules/empresas/components/EmpresaTable.vue'
import {
  desactivarEmpresa,
  eliminarEmpresa,
  obtenerEmpresas,
} from '@/modules/empresas/services/empresas.service'

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
  nombreRuta: 'empresas-listado',
  cargar: obtenerEmpresas,
  filtros: { estado_suscripcion: { permitidos: ['all', 'Activo', 'Inactivo', 'Por Vencer'] } },
  mapearParametros: ({ estado_suscripcion }) => ({ estado_suscripcion }),
  mensajeDeError: 'No pudimos cargar las empresas.',
  avisos: {
    deactivated: 'Empresa desactivada correctamente.',
    created: 'Empresa creada correctamente.',
    updated: 'Empresa actualizada correctamente.',
  },
})

// La desactivación se queda en la vista: su texto y su confirmación son propios
// del recurso, no algo que el composable pueda generalizar sin quedarse soso.
const empresaSeleccionada = ref(null)
const desactivando = ref(false)
const empresaAEliminar = ref(null)
const eliminando = ref(false)
const errorEliminar = ref('')

function solicitarEliminacion(empresa) {
  if (eliminando.value) return
  empresaAEliminar.value = empresa
  errorEliminar.value = ''
  mensajeExito.value = ''
}

async function confirmarEliminacion() {
  if (!empresaAEliminar.value || eliminando.value) return
  eliminando.value = true
  errorEliminar.value = ''
  try {
    const { id, nombre } = empresaAEliminar.value
    const respuesta = await eliminarEmpresa(id)
    empresaAEliminar.value = null
    await anunciarExito(
      respuesta?.message || `La empresa ${nombre} y sus usuarios fueron eliminados.`,
    )
  } catch (error) {
    const cuerpo = error?.response?.data
    const errores = cuerpo?.errors ?? error?.errors ?? {}
    errorEliminar.value = [
      cuerpo?.message || error?.message || 'No pudimos eliminar la empresa.',
      ...Object.values(errores).flat(),
    ]
      .filter(Boolean)
      .join(' ')
  } finally {
    eliminando.value = false
  }
}

function solicitarDesactivacion(empresa) {
  empresaSeleccionada.value = empresa
}

async function confirmarDesactivacion() {
  if (!empresaSeleccionada.value || desactivando.value) return
  desactivando.value = true

  try {
    const { id, nombre } = empresaSeleccionada.value
    await desactivarEmpresa(id)
    empresaSeleccionada.value = null
    await anunciarExito(`La empresa ${nombre} fue desactivada correctamente.`)
  } catch (error) {
    mensajeError.value = error?.message || 'No pudimos desactivar la empresa.'
    empresaSeleccionada.value = null
    estadoVista.value = 'error'
  } finally {
    desactivando.value = false
  }
}
</script>

<template>
  <section class="empresas">
    <PageHeader
      titulo="Empresas"
      descripcion="Administra las empresas registradas y su acceso a Gym Bros."
      seccion="Empresas"
      :ruta-seccion="{ name: 'empresas-listado' }"
      etiqueta="Gestión empresarial"
    >
      <template #acciones>
        <RouterLink class="btn btn-primary empresas__nueva" :to="{ name: 'empresa-nueva' }">
          <Plus :size="16" aria-hidden="true" />
          Nueva empresa
        </RouterLink>
      </template>
    </PageHeader>

    <p
      v-if="mensajeExito"
      ref="mensajeExitoRef"
      class="empresas__exito"
      role="status"
      tabindex="-1"
    >
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>

    <EmpresaFilters
      :busqueda="busqueda"
      :estado="filtros.estado_suscripcion"
      :cargando="estadoVista === 'loading'"
      @update:busqueda="cambiarBusqueda"
      @update:estado="cambiarFiltro('estado_suscripcion', $event)"
    />

    <EmpresaTable
      v-if="
        estadoVista === 'idle' ||
        estadoVista === 'loading' ||
        (estadoVista === 'success' && items.length)
      "
      :items="items"
      :paginacion="paginacion"
      :cargando="estadoVista === 'idle' || estadoVista === 'loading'"
      @cambiar-pagina="cambiarPagina"
      @desactivar="solicitarDesactivacion"
      @eliminar="solicitarEliminacion"
    />

    <section v-else-if="estadoVista === 'error'" class="empresas__estado gb-tarjeta" role="alert">
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos cargar las empresas</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargarListado">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <section v-else class="empresas__estado gb-tarjeta" role="status">
      <Building2 :size="48" aria-hidden="true" />
      <h2>{{ hayFiltros ? 'No encontramos resultados' : 'Aún no hay empresas registradas' }}</h2>
      <p v-if="hayFiltros">Prueba con otra búsqueda o limpia los filtros seleccionados.</p>
      <p v-else>Registra tu primera empresa para comenzar.</p>
      <button v-if="hayFiltros" type="button" class="btn btn-ghost" @click="limpiarFiltros">
        Limpiar filtros
      </button>
      <RouterLink v-else class="btn btn-primary" :to="{ name: 'empresa-nueva' }">
        <Plus :size="16" aria-hidden="true" />
        Nueva empresa
      </RouterLink>
    </section>

    <p v-if="errorEliminar" class="alert alert-danger" role="alert">{{ errorEliminar }}</p>
    <ConfirmDialog
      :abierto="Boolean(empresaAEliminar)"
      titulo="¿Eliminar empresa y sus usuarios?"
      :descripcion="`${errorEliminar ? errorEliminar + ' ' : ''}Se eliminará permanentemente ${empresaAEliminar?.nombre ?? 'la empresa'} y todos sus usuarios. Esta acción no se puede deshacer.`"
      :confirmando="eliminando"
      etiqueta-confirmar="Eliminar empresa y usuarios"
      etiqueta-confirmando="Eliminando…"
      @cancelar="empresaAEliminar = null"
      @confirmar="confirmarEliminacion"
    />
    <ConfirmDialog
      :abierto="Boolean(empresaSeleccionada)"
      titulo="¿Desactivar empresa?"
      :descripcion="`Esta acción suspenderá el acceso de ${empresaSeleccionada?.nombre ?? 'la empresa'} al sistema.`"
      :confirmando="desactivando"
      etiqueta-confirmar="Desactivar empresa"
      etiqueta-confirmando="Desactivando…"
      @cancelar="empresaSeleccionada = null"
      @confirmar="confirmarDesactivacion"
    />
  </section>
</template>

<style scoped>
.empresas {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: 100%;
  max-width: 100rem;
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.empresas__nueva {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
  text-decoration: none;
}

.empresas__exito {
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

.empresas__estado {
  display: grid;
  place-items: center;
  min-height: 24rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.empresas__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.empresas__estado h2 {
  margin: 1rem 0 0;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.empresas__estado p {
  max-width: 30rem;
  margin: 0.5rem 0 1.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.empresas__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  min-height: 2.75rem;
  padding-inline: 1.25rem;
  text-decoration: none;
}
</style>
