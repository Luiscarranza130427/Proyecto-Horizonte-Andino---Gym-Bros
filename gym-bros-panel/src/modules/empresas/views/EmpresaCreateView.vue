<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import EmpresaForm from '@/modules/empresas/components/EmpresaForm.vue'
import { crearEmpresa } from '@/modules/empresas/services/empresas.service'

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
    await crearEmpresa(datos)
    await router.push({
      name: 'empresas-listado',
      query: { notice: 'created' },
    })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos crear la empresa.'
  } finally {
    enviando.value = false
  }
}
</script>

<template>
  <section class="empresa-editor">
    <PageHeader
      titulo="Nueva empresa"
      descripcion="Registra una nueva organización y configura su acceso inicial."
      seccion="Empresas"
      :ruta-seccion="{ name: 'empresas-listado' }"
      etiqueta="Gestión empresarial"
      :migas="['Nueva empresa']"
    />
    <p v-if="mensajeError" class="alert alert-danger" role="alert">{{ mensajeError }}</p>
    <EmpresaForm
      class="empresa-editor__formulario"
      mostrar-plan
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="router.push({ name: 'empresas-listado' })"
    />
  </section>
</template>

<style scoped>
.empresa-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}

.empresa-editor .alert {
  margin: 0;
}

.empresa-editor__formulario {
  --empresa-aumento-ayudas-botones: 3px;
  --empresa-columnas: 3;
  --empresa-campo-completo: auto;
}
</style>
