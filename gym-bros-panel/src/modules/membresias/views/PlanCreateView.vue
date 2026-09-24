<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import PlanForm from '@/modules/membresias/components/PlanForm.vue'
import { crearPlanComercial } from '@/modules/membresias/services/membresias.service'

const router = useRouter()
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    await crearPlanComercial(datos)
    await router.push({ name: 'planes-administrar', query: { notice: 'created' } })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos crear el plan.'
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <section class="plan-editor">
    <PageHeader
      titulo="Nuevo plan"
      descripcion="Crea una oferta comercial usando los límites y precios definidos para Gym Bros."
      seccion="Planes"
      :ruta-seccion="{ name: 'planes-administrar' }"
      etiqueta="Gestión comercial"
      :migas="['Nuevo plan']"
    />
    <p v-if="mensajeError" class="alert alert-danger" role="alert">{{ mensajeError }}</p>
    <PlanForm
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="router.push({ name: 'planes-administrar' })"
    />
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
</style>
