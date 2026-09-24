<script setup>
import { CloudOff, Salad } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import { obtenerPlanAlimentacionUsuario } from '@/modules/usuarios/services/usuarios.service'

const route = useRoute()
const estado = ref('loading')
const plan = ref(null)
const mensajeError = ref('')
let solicitudActual = 0

async function cargar() {
  const solicitud = ++solicitudActual
  estado.value = 'loading'
  mensajeError.value = ''
  try {
    const respuesta = await obtenerPlanAlimentacionUsuario(route.params.id)
    if (solicitud !== solicitudActual) return
    plan.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (solicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el plan de alimentación.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

watch(() => route.params.id, cargar, { immediate: true })
onBeforeUnmount(() => {
  solicitudActual += 1
})
</script>

<template>
  <section class="plan-usuario">
    <PageHeader
      titulo="Plan de alimentación"
      descripcion="Plan alimentario asignado al usuario."
      seccion="Usuarios"
      :ruta-seccion="{ name: 'usuarios-listado' }"
      etiqueta="Gestión de usuarios"
    />
    <section v-if="estado === 'loading'" class="plan-usuario__estado gb-tarjeta" aria-busy="true">
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando plan de alimentación…</p>
    </section>
    <section v-else-if="estado === 'success'" class="plan-usuario__contenido gb-tarjeta">
      <Salad :size="28" aria-hidden="true" />
      <h2>{{ plan.nombre || 'Plan de alimentación' }}</h2>
      <p v-if="plan.objetivo">Objetivo: {{ plan.objetivo }}</p>
      <p v-if="plan.fecha_inicio || plan.fecha_fin">
        {{ plan.fecha_inicio || '—' }} — {{ plan.fecha_fin || '—' }}
      </p>
      <p>{{ plan.dias?.length || 0 }} días planificados</p>
    </section>
    <section
      v-else
      class="plan-usuario__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <CloudOff :size="40" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'No hay plan de alimentación' : 'No pudimos cargar el plan' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
        Reintentar
      </button>
    </section>
  </section>
</template>

<style scoped>
.plan-usuario {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}
.plan-usuario__estado,
.plan-usuario__contenido {
  display: grid;
  place-items: center;
  min-height: 18rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}
.plan-usuario__contenido {
  justify-items: start;
  text-align: left;
}
.plan-usuario__estado p,
.plan-usuario__contenido p {
  margin: 0.5rem 0 0;
  color: var(--gb-text-muted);
}
.plan-usuario__estado h2,
.plan-usuario__contenido h2 {
  margin: 1rem 0 0;
}
</style>
