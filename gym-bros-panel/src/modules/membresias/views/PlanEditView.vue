<script setup>
import { CloudOff, RotateCw } from 'lucide-vue-next'
import { nextTick, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import PlanForm from '@/modules/membresias/components/PlanForm.vue'
import {
  actualizarPlanComercial,
  obtenerPlanComercial,
} from '@/modules/membresias/services/membresias.service'

const route = useRoute()
const router = useRouter()
const estadoVista = ref('loading')
const plan = ref(null)
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')

async function cargar() {
  estadoVista.value = 'loading'
  mensajeError.value = ''

  try {
    plan.value = await obtenerPlanComercial(route.params.id)
    estadoVista.value = 'success'
    await nextTick()
    document.getElementById('contenido-principal')?.scrollTo({ top: 0, behavior: 'instant' })
  } catch (error) {
    mensajeError.value = error?.message || 'No pudimos cargar el plan.'
    estadoVista.value = 'error'
  }
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    await actualizarPlanComercial(route.params.id, datos)
    await router.push({ name: 'planes-administrar', query: { notice: 'updated' } })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos actualizar el plan.'
  } finally {
    enviando.value = false
  }
}

onMounted(cargar)

function cancelar() {
  router.push({ name: 'planes-administrar' }).catch(() => {})
}
</script>

<template>
  <section class="plan-editor">
    <PageHeader
      titulo="Editar plan"
      descripcion="Actualiza la oferta comercial, sus límites y su disponibilidad."
      seccion="Planes"
      :ruta-seccion="{ name: 'planes-administrar' }"
      etiqueta="Gestión comercial"
      :migas="['Editar plan']"
    />

    <div v-if="estadoVista === 'loading'" class="plan-editor__estado gb-tarjeta" aria-busy="true">
      <span class="plan-editor__spinner" aria-hidden="true"></span>
      <p>Cargando plan…</p>
    </div>

    <section
      v-else-if="estadoVista === 'error'"
      class="plan-editor__estado gb-tarjeta"
      role="alert"
    >
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos cargar el plan</h2>
      <p>{{ mensajeError }}</p>
      <button type="button" class="btn btn-primary" @click="cargar">
        <RotateCw :size="16" aria-hidden="true" />
        Reintentar
      </button>
    </section>

    <template v-else>
      <p v-if="mensajeError" class="alert alert-danger" role="alert">{{ mensajeError }}</p>
      <PlanForm
        modo="edit"
        :valores-iniciales="plan"
        :enviando="enviando"
        :errores-servidor="erroresServidor"
        @submit="guardar"
        @cancel="cancelar"
      />
    </template>
  </section>
</template>

<style scoped>
.plan-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 78rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.plan-editor .alert {
  margin: 0;
}

.plan-editor__estado {
  display: grid;
  place-items: center;
  min-height: 22rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.plan-editor__estado h2,
.plan-editor__estado p {
  margin: 0;
}

.plan-editor__estado h2 {
  margin-top: 0.75rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.plan-editor__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.plan-editor__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  margin-top: 1rem;
}

.plan-editor__spinner {
  width: 2rem;
  height: 2rem;
  border: 3px solid var(--gb-border);
  border-top-color: var(--gb-red);
  border-radius: 50%;
  animation: girar 0.8s linear infinite;
}

@keyframes girar {
  to {
    transform: rotate(1turn);
  }
}
</style>
