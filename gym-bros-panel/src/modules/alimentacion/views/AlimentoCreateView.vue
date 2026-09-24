<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import AlimentoForm from '@/modules/alimentacion/components/AlimentoForm.vue'
import { crearAlimento } from '@/modules/alimentacion/services/alimentacion.service'

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
    const alimento = await crearAlimento(datos)
    await router.push({
      name: 'alimento-detalle',
      params: { id: alimento.id },
      query: { notice: 'created' },
    })
  } catch (error) {
    /*
     * Un 422 CON `errors` es un formulario mal rellenado y se reparte por campo.
     * Uno SIN `errors` es una regla de negocio —un nombre ya usado, por ejemplo—
     * y su `message` no corresponde a ningún campo: va arriba, tal cual.
     */
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos crear el alimento.'
  } finally {
    enviando.value = false
  }
}

function cancelar() {
  router.push({ name: 'alimentos-listado' }).catch(() => {})
}
</script>

<template>
  <section class="alimento-editor">
    <PageHeader
      titulo="Nuevo alimento"
      descripcion="Añade un alimento al catálogo con el que se arman las comidas."
      seccion="Catálogo de alimentos"
      :ruta-seccion="{ name: 'alimentos-listado' }"
      etiqueta="Alimentación"
      :migas="['Nuevo alimento']"
    />
    <p v-if="mensajeError" class="alert alert-danger" role="alert">{{ mensajeError }}</p>
    <AlimentoForm
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="cancelar"
    />
  </section>
</template>

<style scoped>
.alimento-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}

.alimento-editor .alert {
  margin: 0;
}
</style>
