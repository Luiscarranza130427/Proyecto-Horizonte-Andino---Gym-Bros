<script setup>
import { XCircle } from 'lucide-vue-next'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import EjercicioForm from '@/modules/ejercicios/components/EjercicioForm.vue'
import {
  actualizarEjercicio,
  obtenerEjercicio,
  obtenerGruposMusculares,
} from '@/modules/ejercicios/services/ejercicios.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const ejercicio = ref(null)
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')
const gruposMusculares = ref([])
const cargandoGrupos = ref(true)
const errorGrupos = ref('')
let solicitudActual = 0

/*
 * El servicio expone el equipamiento como `equipo` (vocabulario del listado) y
 * el formulario lo edita como `equipamiento`, que es el campo de la API. Sin
 * esta traducción el campo aparecía vacío al editar y obligaba a cambiarlo.
 */
const valoresFormulario = computed(() =>
  ejercicio.value ? { ...ejercicio.value, equipamiento: ejercicio.value.equipo } : {},
)

async function cargarGruposMusculares() {
  cargandoGrupos.value = true
  errorGrupos.value = ''
  try {
    gruposMusculares.value = await obtenerGruposMusculares()
  } catch (error) {
    gruposMusculares.value = []
    errorGrupos.value = error?.message || 'No pudimos cargar los grupos musculares.'
  } finally {
    cargandoGrupos.value = false
  }
}

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  ejercicio.value = null
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    const respuesta = await obtenerEjercicio(route.params.id)
    if (idSolicitud !== solicitudActual) return
    ejercicio.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el ejercicio.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    const actualizado = await actualizarEjercicio(route.params.id, datos)
    await router.push({
      name: 'ejercicio-detalle',
      params: { id: actualizado.id },
      query: { notice: 'updated' },
    })
  } catch (error) {
    if (error?.status === 422) {
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else if (error?.status === 404) {
      ejercicio.value = null
      mensajeError.value = error?.message || 'El ejercicio solicitado no existe.'
      estado.value = 'not-found'
    } else mensajeError.value = error?.message || 'No pudimos actualizar el ejercicio.'
  } finally {
    enviando.value = false
  }
}

function cancelar() {
  router.push({ name: 'ejercicios-listado' }).catch(() => {})
}

watch(() => route.params.id, cargar, { immediate: true })
cargarGruposMusculares()
onBeforeUnmount(() => {
  solicitudActual += 1
})
</script>

<template>
  <section class="ejercicio-editor">
    <PageHeader
      titulo="Editar ejercicio"
      :descripcion="
        ejercicio
          ? `Actualiza la ficha de ${ejercicio.nombre}.`
          : 'Actualiza la ficha del ejercicio.'
      "
      seccion="Ejercicios"
      :ruta-seccion="{ name: 'ejercicios-listado' }"
      etiqueta="Catálogo de entrenamiento"
      :migas="[ejercicio?.nombre ?? 'Ejercicio', 'Editar']"
    />

    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section
      v-if="estado === 'loading'"
      class="ejercicio-editor__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información del ejercicio…</p>
    </section>

    <EjercicioForm
      v-else-if="estado === 'success' && ejercicio"
      modo="edit"
      :valores-iniciales="valoresFormulario"
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      :grupos-musculares="gruposMusculares"
      :cargando-grupos="cargandoGrupos"
      :error-grupos="errorGrupos"
      @reintentar-grupos="cargarGruposMusculares"
      @submit="guardar"
      @cancel="cancelar"
    />

    <section
      v-else
      class="ejercicio-editor__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <XCircle :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Ejercicio no encontrado' : 'No pudimos cargar el ejercicio' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'ejercicios-listado' }">
          Volver a ejercicios
        </RouterLink>
      </div>
    </section>
  </section>
</template>

<style scoped>
.ejercicio-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}

.ejercicio-editor .alert {
  margin: 0;
}

.ejercicio-editor__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.ejercicio-editor__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.ejercicio-editor__estado h2,
.ejercicio-editor__estado p {
  margin: 0;
}

.ejercicio-editor__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.ejercicio-editor__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.ejercicio-editor__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.ejercicio-editor__estado .btn {
  text-decoration: none;
}
</style>
