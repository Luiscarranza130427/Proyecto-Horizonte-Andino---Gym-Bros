<script setup>
import { Ban, CheckCircle2, Dumbbell, Pencil, XCircle } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import { EQUIPOS, NIVELES, etiquetaDe } from '@/modules/ejercicios/catalogos'
import EjercicioStatusBadge from '@/modules/ejercicios/components/EjercicioStatusBadge.vue'
import {
  desactivarEjercicio,
  obtenerEjercicio,
} from '@/modules/ejercicios/services/ejercicios.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const ejercicio = ref(null)
const mensajeError = ref('')
const mensajeExito = ref('')
const dialogoAbierto = ref(false)
const desactivando = ref(false)
let solicitudActual = 0

function etiquetaEquipo(equipo) {
  return EQUIPOS.find((opcion) => opcion.valor === equipo)?.etiqueta ?? equipo ?? 'Sin equipo'
}

function etiquetaTipo(tipo) {
  if (!tipo) return 'No especificado'

  const etiqueta = String(tipo).replaceAll('_', ' ')
  return `${etiqueta.charAt(0).toUpperCase()}${etiqueta.slice(1)}`
}

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  ejercicio.value = null
  dialogoAbierto.value = false
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

async function confirmarDesactivacion() {
  if (!ejercicio.value || desactivando.value) return
  desactivando.value = true

  try {
    await desactivarEjercicio(ejercicio.value.id)
    dialogoAbierto.value = false
    await router.push({ name: 'ejercicios-listado', query: { notice: 'deactivated' } })
  } catch (error) {
    dialogoAbierto.value = false
    mensajeError.value = error?.message || 'No pudimos desactivar el ejercicio.'
  } finally {
    desactivando.value = false
  }
}

watch(
  () => route.params.id,
  () => {
    mensajeExito.value = ''
    const notice = route.query.notice
    if (notice === 'created') mensajeExito.value = 'Ejercicio creado correctamente.'
    if (notice === 'updated') mensajeExito.value = 'Ejercicio actualizado correctamente.'
    if (notice === 'created' || notice === 'updated') {
      router.replace({ name: 'ejercicio-detalle', params: { id: route.params.id } }).catch(() => {})
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
  <section class="ejercicio-detalle">
    <PageHeader
      :titulo="ejercicio?.nombre ?? 'Detalle de ejercicio'"
      descripcion="Consulta la ficha técnica y el estado del ejercicio."
      seccion="Ejercicios"
      :ruta-seccion="{ name: 'ejercicios-listado' }"
      etiqueta="Catálogo de entrenamiento"
      :migas="[ejercicio?.nombre ?? 'Ejercicio']"
    >
      <template v-if="estado === 'success' && ejercicio" #acciones>
        <RouterLink
          class="btn btn-secondary"
          :to="{ name: 'ejercicio-editar', params: { id: ejercicio.id } }"
        >
          <Pencil :size="16" aria-hidden="true" />
          <span>Editar</span>
        </RouterLink>
        <button
          v-if="ejercicio.estado === 'active'"
          type="button"
          class="btn btn-danger"
          @click="dialogoAbierto = true"
        >
          <Ban :size="16" aria-hidden="true" />
          <span>Desactivar</span>
        </button>
      </template>
    </PageHeader>

    <p v-if="mensajeExito" class="ejercicio-detalle__exito" role="status">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section
      v-if="estado === 'loading'"
      class="ejercicio-detalle__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información del ejercicio…</p>
    </section>

    <div v-else-if="estado === 'success' && ejercicio" class="detalle">
      <section class="detalle__resumen gb-tarjeta">
        <span class="detalle__icono" aria-hidden="true"
          ><Dumbbell :size="28" aria-hidden="true"
        /></span>
        <div>
          <p>Ejercicio del catálogo</p>
          <h2>{{ ejercicio.nombre }}</h2>
          <span>{{ etiquetaTipo(ejercicio.tipo) }}</span>
        </div>
        <EjercicioStatusBadge :estado="ejercicio.estado" />
      </section>

      <div class="detalle__rejilla">
        <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-ficha">
          <header>
            <p>Ficha técnica</p>
            <h2 id="titulo-ficha">Información del ejercicio</h2>
          </header>
          <div
            class="detalle__contenido"
            :class="{ 'detalle__contenido--sin-imagen': !ejercicio.imagen }"
          >
            <figure v-if="ejercicio.imagen" class="detalle__figura">
              <img class="detalle__imagen" :src="ejercicio.imagen" :alt="ejercicio.nombre" />
              <figcaption>Medidas recomendadas: 500 × 380 px.</figcaption>
            </figure>

            <dl>
              <div>
                <dt>Nombre</dt>
                <dd>{{ ejercicio.nombre }}</dd>
              </div>
              <div>
                <dt>Tipo</dt>
                <dd>{{ etiquetaTipo(ejercicio.tipo) }}</dd>
              </div>
              <div>
                <dt>Nivel</dt>
                <dd>{{ etiquetaDe(NIVELES, ejercicio.nivel) }}</dd>
              </div>
              <div>
                <dt>Equipamiento</dt>
                <dd>{{ etiquetaEquipo(ejercicio.equipo) }}</dd>
              </div>
              <div>
                <dt>Estado</dt>
                <dd><EjercicioStatusBadge :estado="ejercicio.estado" /></dd>
              </div>
              <div v-if="ejercicio.enlaceVideo" class="detalle__completo">
                <dt>Enlace de video</dt>
                <dd>
                  <a :href="ejercicio.enlaceVideo" target="_blank" rel="noopener noreferrer">
                    Ver video del ejercicio
                  </a>
                </dd>
              </div>
              <div class="detalle__completo">
                <dt>Descripción</dt>
                <dd>{{ ejercicio.descripcion || 'Sin descripción registrada.' }}</dd>
              </div>
              <div class="detalle__completo">
                <dt>Instrucciones</dt>
                <dd>{{ ejercicio.instrucciones || 'Sin instrucciones registradas.' }}</dd>
              </div>
            </dl>
          </div>
        </section>
      </div>
    </div>

    <section
      v-else
      class="ejercicio-detalle__estado gb-tarjeta"
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

    <ConfirmDialog
      :abierto="dialogoAbierto"
      titulo="¿Desactivar ejercicio?"
      :descripcion="`${ejercicio?.nombre ?? 'El ejercicio'} dejará de poder asignarse a rutinas nuevas.`"
      :confirmando="desactivando"
      etiqueta-confirmar="Desactivar ejercicio"
      etiqueta-confirmando="Desactivando…"
      @cancelar="dialogoAbierto = false"
      @confirmar="confirmarDesactivacion"
    />
  </section>
</template>

<style scoped>
.ejercicio-detalle {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.ejercicio-detalle__exito {
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

.ejercicio-detalle__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.ejercicio-detalle__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.ejercicio-detalle__estado h2,
.ejercicio-detalle__estado p {
  margin: 0;
}

.ejercicio-detalle__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.ejercicio-detalle__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.ejercicio-detalle__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.ejercicio-detalle__estado .btn {
  text-decoration: none;
}

.detalle {
  display: grid;
  gap: var(--gb-gutter);
}

.detalle__resumen {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl);
}

.detalle__icono {
  display: grid;
  place-items: center;
  width: 4rem;
  height: 4rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
  font-size: 1.75rem;
}

.detalle__resumen p,
.detalle__resumen h2,
.detalle__resumen div > span {
  margin: 0;
}

.detalle__resumen p,
.detalle__panel header p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.detalle__resumen h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.detalle__resumen div > span {
  display: block;
  margin-top: 0.25rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.detalle__rejilla {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: var(--gb-gutter, 1.25rem);
  align-items: stretch;
}

.detalle__panel {
  padding: 1.25rem 1.5rem;
  border-radius: var(--gb-radius-xl);
  display: flex;
  flex-direction: column;
}

.detalle__panel--principal {
  height: 100%;
}

.detalle__panel header {
  min-height: 3.5rem;
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
  flex-shrink: 0;
}

.detalle__panel header p,
.detalle__panel header h2 {
  margin: 0;
}

.detalle__contenido {
  display: grid;
  grid-template-columns: minmax(17rem, 31.25rem) minmax(0, 1fr);
  gap: 1.25rem;
  padding-top: 1rem;
}

.detalle__contenido--sin-imagen {
  grid-template-columns: minmax(0, 1fr);
}

.detalle__figura {
  margin: 0;
}

.detalle__imagen {
  display: block;
  width: 100%;
  aspect-ratio: 500 / 380;
  border: 1px solid var(--gb-border);
  border-radius: 5px;
  background: var(--gb-surface-muted);
  object-fit: contain;
}

.detalle__figura figcaption {
  margin-top: 0.625rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.detalle__panel header h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.detalle__panel dl {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  margin: 0;
}

.detalle__panel dl > div {
  min-width: 0;
  padding: 1rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.detalle__panel dl > div:last-child {
  border-bottom: 0;
}

.detalle__panel dl > div:nth-child(even) {
  padding-left: 1rem;
}

.detalle__panel dl > div:nth-child(odd) {
  padding-right: 1rem;
}

.detalle__panel .detalle__completo {
  grid-column: 1 / -1;
  padding-right: 0;
  padding-left: 0;
}

.detalle__panel dt {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.detalle__panel dd {
  margin: 0.375rem 0 0;
  overflow-wrap: anywhere;
  color: var(--gb-text);
  font-size: var(--gb-tipo-sm);
}

@media (max-width: 52rem) {
  .detalle__resumen {
    grid-template-columns: auto minmax(0, 1fr);
  }

  .detalle__resumen > :last-child {
    grid-column: 1 / -1;
    justify-self: start;
  }

  .detalle__contenido,
  .detalle__panel dl {
    grid-template-columns: 1fr;
  }

  .detalle__panel dl > div {
    grid-column: auto;
    padding-right: 0 !important;
    padding-left: 0 !important;
  }
}
</style>
