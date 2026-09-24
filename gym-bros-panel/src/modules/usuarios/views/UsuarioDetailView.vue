<script setup>
import { Ban, CheckCircle2, Pencil, Salad, UserX } from 'lucide-vue-next'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import UsuarioHistory from '@/modules/usuarios/components/UsuarioHistory.vue'
import UsuarioProfileSummary from '@/modules/usuarios/components/UsuarioProfileSummary.vue'
import {
  desactivarUsuario,
  obtenerHistorialUsuario,
  obtenerUsuario,
} from '@/modules/usuarios/services/usuarios.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const usuario = ref(null)
/*
 * `null` mientras no se sepa, y también cuando la API no tenga el endpoint:
 * en ese caso la sección se oculta en lugar de afirmar que no hay cambios.
 */
const historial = ref(null)
const historialCargando = ref(false)
const historialError = ref('')
const mensajeError = ref('')
const mensajeExito = ref('')
const dialogoAbierto = ref(false)
const desactivando = ref(false)
let solicitudActual = 0
let solicitudHistorial = 0
const nombreCompleto = computed(() =>
  [usuario.value?.nombre, usuario.value?.apellido].filter(Boolean).join(' '),
)

async function cargarHistorial() {
  const idSolicitud = ++solicitudHistorial
  historialCargando.value = true
  historialError.value = ''
  try {
    const respuesta = await obtenerHistorialUsuario(route.params.id)
    if (idSolicitud !== solicitudHistorial) return
    historial.value = respuesta
  } catch (error) {
    if (idSolicitud !== solicitudHistorial) return
    historial.value = []
    historialError.value = error?.message || 'No pudimos cargar el historial.'
  } finally {
    if (idSolicitud === solicitudHistorial) historialCargando.value = false
  }
}

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  usuario.value = null
  historial.value = []
  historialError.value = ''
  dialogoAbierto.value = false
  mensajeError.value = ''
  try {
    const respuesta = await obtenerUsuario(route.params.id)
    if (idSolicitud !== solicitudActual) return
    usuario.value = respuesta
    estado.value = 'success'
    cargarHistorial()
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el usuario.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function confirmarDesactivacion() {
  if (!usuario.value || desactivando.value) return
  desactivando.value = true
  try {
    await desactivarUsuario(usuario.value.id)
    dialogoAbierto.value = false
    await router.push({ name: 'usuarios-listado', query: { notice: 'deactivated' } })
  } catch (error) {
    dialogoAbierto.value = false
    mensajeError.value = error?.message || 'No pudimos desactivar el usuario.'
  } finally {
    desactivando.value = false
  }
}

watch(
  () => route.params.id,
  () => {
    mensajeExito.value = ''
    const notice = route.query.notice
    if (notice === 'created') mensajeExito.value = 'Usuario creado correctamente.'
    if (notice === 'updated') mensajeExito.value = 'Usuario actualizado correctamente.'
    if (notice === 'created' || notice === 'updated') {
      router.replace({ name: 'usuario-detalle', params: { id: route.params.id } })
    }
    cargar()
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  solicitudActual += 1
  solicitudHistorial += 1
})
</script>

<template>
  <section class="usuario-detalle">
    <PageHeader
      :titulo="nombreCompleto || 'Perfil de usuario'"
      :descripcion="
        usuario?.apodo
          ? `@${usuario.apodo} · Consulta su información, membresía y trazabilidad administrativa.`
          : 'Consulta su información, membresía y trazabilidad administrativa.'
      "
      seccion="Usuarios"
      :ruta-seccion="{ name: 'usuarios-listado' }"
      etiqueta="Gestión de usuarios"
      :migas="[nombreCompleto || 'Usuario']"
    >
      <template v-if="estado === 'success' && usuario" #acciones>
        <RouterLink
          class="btn btn-secondary"
          :to="{ name: 'usuario-plan-alimentacion', params: { id: usuario.id } }"
        >
          <Salad :size="16" aria-hidden="true" />
          <span>Ver plan de alimentación</span>
        </RouterLink>
        <RouterLink
          class="btn btn-secondary"
          :to="{ name: 'usuario-editar', params: { id: usuario.id } }"
        >
          <Pencil :size="16" aria-hidden="true" />
          <span>Editar</span>
        </RouterLink>
        <button
          v-if="usuario.estado === 'active'"
          type="button"
          class="btn btn-danger"
          @click="dialogoAbierto = true"
        >
          <Ban :size="16" aria-hidden="true" />
          <span>Desactivar</span>
        </button>
      </template>
    </PageHeader>

    <p v-if="mensajeExito" class="usuario-detalle__exito" role="status">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section
      v-if="estado === 'loading'"
      class="usuario-detalle__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando perfil del usuario…</p>
    </section>

    <template v-else-if="estado === 'success' && usuario">
      <UsuarioProfileSummary :usuario="usuario" />
      <!--
        Oculta mientras la API no tenga `GET /usuarios/:id/historial`. Un panel
        que dice «Sin cambios registrados» para siempre se lee como que el
        usuario no tiene actividad, no como que falta el backend.
      -->
      <UsuarioHistory
        v-if="historial !== null"
        :items="historial"
        :loading="historialCargando"
        :error="historialError"
        @retry="cargarHistorial"
      />
    </template>

    <section
      v-else
      class="usuario-detalle__estado gb-tarjeta"
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

    <ConfirmDialog
      :abierto="dialogoAbierto"
      titulo="¿Desactivar usuario?"
      :descripcion="`${nombreCompleto || 'El usuario'} dejará de tener acceso a Gym Bros.`"
      :confirmando="desactivando"
      etiqueta-confirmar="Desactivar usuario"
      etiqueta-confirmando="Desactivando…"
      @cancelar="dialogoAbierto = false"
      @confirmar="confirmarDesactivacion"
    />
  </section>
</template>

<style scoped>
.usuario-detalle {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}
.usuario-detalle__exito {
  display: flex;
  align-items: center;
  gap: 0.625rem;
  margin: 0;
  padding: 0.75rem 1rem;
  background: rgba(var(--gb-green-rgb), 0.08);
  border: 1px solid rgba(var(--gb-green-rgb), 0.28);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-green);
  font-size: var(--gb-tipo-sm);
}
.usuario-detalle__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}
.usuario-detalle__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}
.usuario-detalle__estado h2,
.usuario-detalle__estado p {
  margin: 0;
}
.usuario-detalle__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}
.usuario-detalle__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}
.usuario-detalle__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}
.usuario-detalle__estado .btn {
  text-decoration: none;
}
</style>
