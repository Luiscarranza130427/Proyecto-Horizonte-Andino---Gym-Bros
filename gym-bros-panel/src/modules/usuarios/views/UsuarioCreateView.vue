<script setup>
import { CloudOff } from 'lucide-vue-next'
import { ref } from 'vue'
import { useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import UsuarioForm from '@/modules/usuarios/components/UsuarioForm.vue'
import { crearUsuario, obtenerOpcionesEmpresas } from '@/modules/usuarios/services/usuarios.service'

const router = useRouter()
const empresas = ref([])
const estadoOpciones = ref('loading')
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')

async function cargarOpciones() {
  estadoOpciones.value = 'loading'
  mensajeError.value = ''
  try {
    empresas.value = (await obtenerOpcionesEmpresas()).filter((item) => item.estado !== 'inactive')
    estadoOpciones.value = 'success'
  } catch (error) {
    mensajeError.value = error?.message || 'No pudimos cargar las empresas disponibles.'
    estadoOpciones.value = 'error'
  }
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''
  try {
    const usuario = await crearUsuario(datos)
    await router.push({
      name: 'usuario-detalle',
      params: { id: usuario.id },
      query: { notice: 'created' },
    })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos crear el usuario.'
  } finally {
    enviando.value = false
  }
}

cargarOpciones()
</script>

<template>
  <section class="usuario-editor">
    <PageHeader
      titulo="Nuevo usuario"
      descripcion="Registra una persona y configura su acceso inicial."
      seccion="Usuarios"
      :ruta-seccion="{ name: 'usuarios-listado' }"
      etiqueta="Gestión de usuarios"
      :migas="['Nuevo usuario']"
    />
    <p v-if="mensajeError && estadoOpciones === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>
    <section
      v-if="estadoOpciones === 'loading'"
      class="usuario-editor__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando opciones del formulario…</p>
    </section>
    <UsuarioForm
      v-else-if="estadoOpciones === 'success'"
      :empresas="empresas"
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="router.push({ name: 'usuarios-listado' })"
    />
    <section v-else class="usuario-editor__estado gb-tarjeta" role="alert">
      <CloudOff :size="48" aria-hidden="true" />
      <h2>No pudimos preparar el formulario</h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button type="button" class="btn btn-primary" @click="cargarOpciones">Reintentar</button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'usuarios-listado' }"
          >Volver a usuarios</RouterLink
        >
      </div>
    </section>
  </section>
</template>

<style scoped>
.usuario-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}
.usuario-editor .alert {
  margin: 0;
}
.usuario-editor__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}
.usuario-editor__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}
.usuario-editor__estado h2,
.usuario-editor__estado p {
  margin: 0;
}
.usuario-editor__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}
.usuario-editor__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
.usuario-editor__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}
.usuario-editor__estado .btn {
  text-decoration: none;
}
</style>
