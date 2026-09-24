<script setup>
import { UserX } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import UsuarioForm from '@/modules/usuarios/components/UsuarioForm.vue'
import {
  actualizarUsuario,
  obtenerOpcionesEmpresas,
  obtenerUsuario,
} from '@/modules/usuarios/services/usuarios.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const usuario = ref(null)
const empresas = ref([])
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')
let solicitudActual = 0

function nombreCompleto(datos) {
  if (!datos) return ''
  return [datos.nombre, datos.apellido].filter(Boolean).join(' ').trim()
}

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  usuario.value = null
  erroresServidor.value = {}
  mensajeError.value = ''
  try {
    const [datosUsuario, opciones] = await Promise.all([
      obtenerUsuario(route.params.id),
      obtenerOpcionesEmpresas(),
    ])
    if (idSolicitud !== solicitudActual) return
    usuario.value = datosUsuario
    empresas.value = opciones
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el usuario.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''
  try {
    const actualizado = await actualizarUsuario(route.params.id, datos)
    await router.push({
      name: 'usuario-detalle',
      params: { id: actualizado.id },
      query: { notice: 'updated' },
    })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      mensajeError.value = error?.message || 'Revisa los datos introducidos.'
    } else if (error?.status === 404) {
      usuario.value = null
      mensajeError.value = error?.message || 'El usuario solicitado no existe.'
      estado.value = 'not-found'
    } else mensajeError.value = error?.message || 'No pudimos actualizar el usuario.'
  } finally {
    enviando.value = false
  }
}

watch(() => route.params.id, cargar, { immediate: true })
onBeforeUnmount(() => {
  solicitudActual += 1
})

function cancelar() {
  router.push({ name: 'usuarios-listado' }).catch(() => {})
}
</script>

<template>
  <section class="usuario-editor">
    <PageHeader
      :titulo="usuario ? `Editar a ${nombreCompleto(usuario) || 'usuario'}` : 'Editar usuario'"
      :descripcion="
        usuario
          ? `Actualiza la información de ${nombreCompleto(usuario) || 'este usuario'}.`
          : 'Actualiza la información del usuario.'
      "
      seccion="Usuarios"
      :ruta-seccion="{ name: 'usuarios-listado' }"
      etiqueta="Gestión de usuarios"
      :migas="[usuario ? nombreCompleto(usuario) || 'Usuario' : 'Usuario', 'Editar']"
    />
    <div v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      <p>{{ mensajeError }}</p>
      <ul v-if="Object.keys(erroresServidor).length">
        <li v-for="(error, campo) in erroresServidor" :key="campo">
          {{ Array.isArray(error) ? error.join(' ') : error }}
        </li>
      </ul>
    </div>
    <section v-if="estado === 'loading'" class="usuario-editor__estado gb-tarjeta" aria-busy="true">
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información del usuario…</p>
    </section>
    <UsuarioForm
      v-else-if="estado === 'success' && usuario"
      modo="edit"
      :usuario-inicial="usuario"
      :empresas="empresas"
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      @submit="guardar"
      @cancel="cancelar"
    />
    <section
      v-else
      class="usuario-editor__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <UserX :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Usuario no encontrado' : 'No pudimos cargar el usuario' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
          Reintentar
        </button>
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
