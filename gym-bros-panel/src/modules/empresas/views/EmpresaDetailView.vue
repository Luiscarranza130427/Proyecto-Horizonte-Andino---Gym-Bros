<script setup>
import { Ban, Building2, CheckCircle2, Pencil } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import EmpresaDetails from '@/modules/empresas/components/EmpresaDetails.vue'
import { desactivarEmpresa, obtenerEmpresa } from '@/modules/empresas/services/empresas.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const empresa = ref(null)
const mensajeError = ref('')
const mensajeExito = ref('')
const dialogoAbierto = ref(false)
const desactivando = ref(false)

let solicitudActual = 0

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  empresa.value = null
  dialogoAbierto.value = false
  mensajeError.value = ''

  try {
    const respuesta = await obtenerEmpresa(route.params.id)
    if (idSolicitud !== solicitudActual) return
    empresa.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar la empresa.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function confirmarDesactivacion() {
  if (!empresa.value || desactivando.value) return
  desactivando.value = true

  try {
    await desactivarEmpresa(empresa.value.id)
    dialogoAbierto.value = false
    await router.push({ name: 'empresas-listado', query: { notice: 'deactivated' } })
  } catch (error) {
    dialogoAbierto.value = false
    mensajeError.value = error?.message || 'No pudimos desactivar la empresa.'
  } finally {
    desactivando.value = false
  }
}

watch(
  () => route.params.id,
  () => {
    mensajeExito.value = ''
    const notice = route.query.notice
    if (notice === 'created') mensajeExito.value = 'Empresa creada correctamente.'
    if (notice === 'updated') mensajeExito.value = 'Empresa actualizada correctamente.'
    if (notice === 'created' || notice === 'updated') {
      router.replace({ name: 'empresa-detalle', params: { id: route.params.id } }).catch(() => {})
    }
    cargar()
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  solicitudActual += 1
})
</script>

<template>
  <section class="empresa-detalle">
    <PageHeader
      :titulo="empresa?.nombre ?? 'Detalle de empresa'"
      descripcion="Consulta la información administrativa y el estado operativo."
      seccion="Empresas"
      :ruta-seccion="{ name: 'empresas-listado' }"
      etiqueta="Gestión empresarial"
      :migas="[empresa?.nombre ?? 'Empresa']"
    >
      <template v-if="estado === 'success' && empresa" #acciones>
        <RouterLink
          class="btn btn-secondary"
          :to="{ name: 'empresa-editar', params: { id: empresa.id } }"
        >
          <Pencil :size="16" aria-hidden="true" />
          <span>Editar</span>
        </RouterLink>
        <button
          v-if="empresa.estado === 'active'"
          type="button"
          class="btn btn-danger"
          @click="dialogoAbierto = true"
        >
          <Ban :size="16" aria-hidden="true" />
          <span>Desactivar</span>
        </button>
      </template>
    </PageHeader>

    <p v-if="mensajeExito" class="empresa-detalle__exito" role="status">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section
      v-if="estado === 'loading'"
      class="empresa-detalle__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información de la empresa…</p>
    </section>

    <template v-else-if="estado === 'success' && empresa">
      <EmpresaDetails :empresa="empresa" />
    </template>

    <section
      v-else
      class="empresa-detalle__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <Building2 :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Empresa no encontrada' : 'No pudimos cargar la empresa' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'empresas-listado' }"
          >Volver a empresas</RouterLink
        >
      </div>
    </section>

    <ConfirmDialog
      :abierto="dialogoAbierto"
      titulo="¿Desactivar empresa?"
      :descripcion="`La empresa ${empresa?.nombre ?? ''} y sus accesos asociados quedarán desactivados.`"
      :confirmando="desactivando"
      etiqueta-confirmar="Desactivar empresa"
      etiqueta-confirmando="Desactivando…"
      @cancelar="dialogoAbierto = false"
      @confirmar="confirmarDesactivacion"
    />
  </section>
</template>

<style scoped>
.empresa-detalle {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.empresa-detalle__exito {
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

.empresa-detalle__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.empresa-detalle__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.empresa-detalle__estado h2,
.empresa-detalle__estado p {
  margin: 0;
}

.empresa-detalle__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.empresa-detalle__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.empresa-detalle__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.empresa-detalle__estado .btn {
  text-decoration: none;
}
</style>
