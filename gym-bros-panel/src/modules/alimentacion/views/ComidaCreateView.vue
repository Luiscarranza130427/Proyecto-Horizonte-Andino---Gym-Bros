<script setup>
import { RotateCw, XCircle } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import ComidaForm from '@/modules/alimentacion/components/ComidaForm.vue'
import {
  crearComida,
  obtenerAlimentosParaElegir,
  obtenerPlan,
} from '@/modules/alimentacion/services/alimentacion.service'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const plan = ref(null)
const enviando = ref(false)
const erroresServidor = ref({})
const mensajeError = ref('')
let solicitudActual = 0

/*
 * El catálogo de alimentos es un recurso AUXILIAR de esta pantalla: si falla, no
 * se vacía el formulario. El selector muestra su propio error con reintento y el
 * resto de la comida sigue rellenable.
 */
const catalogo = ref([])
const cargandoCatalogo = ref(false)
const errorCatalogo = ref('')

async function cargarCatalogo() {
  cargandoCatalogo.value = true
  errorCatalogo.value = ''

  try {
    catalogo.value = await obtenerAlimentosParaElegir()
  } catch (error) {
    catalogo.value = []
    errorCatalogo.value = error?.message || 'No pudimos cargar el catálogo de alimentos.'
  } finally {
    cargandoCatalogo.value = false
  }
}

async function cargarPlan() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  plan.value = null
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    const respuesta = await obtenerPlan(route.params.idPlan)
    if (idSolicitud !== solicitudActual) return
    plan.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el plan de alimentación.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

function volverAlPlan(query = {}) {
  return router
    .push({
      name: 'plan-alimentacion-detalle',
      params: { id: route.params.idPlan },
      query,
    })
    .catch(() => {})
}

async function guardar(datos) {
  if (enviando.value) return
  enviando.value = true
  erroresServidor.value = {}
  mensajeError.value = ''

  try {
    await crearComida(route.params.idPlan, datos)
    await volverAlPlan({ notice: 'created' })
  } catch (error) {
    if (error?.status === 422) {
      /*
       * Un 422 CON `errors` se reparte por campo. Uno SIN `errors` es una regla
       * de negocio y su `message` se muestra tal cual, arriba del formulario.
       */
      erroresServidor.value = error.errors ?? {}
      if (!Object.keys(erroresServidor.value).length) {
        mensajeError.value = error?.message || 'Revisa los datos introducidos.'
      }
    } else mensajeError.value = error?.message || 'No pudimos añadir la comida.'
  } finally {
    enviando.value = false
  }
}

function cancelar() {
  volverAlPlan()
}

watch(
  () => route.params.idPlan,
  () => {
    cargarPlan()
    cargarCatalogo()
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  solicitudActual += 1
})
</script>

<template>
  <section class="comida-editor">
    <PageHeader
      titulo="Nueva comida"
      :descripcion="
        plan?.usuario?.nombre
          ? `Añade una comida al horario de ${plan.usuario.nombre}.`
          : 'Añade una comida al horario del plan.'
      "
      seccion="Alimentación"
      :ruta-seccion="{ name: 'alimentacion-listado' }"
      etiqueta="Nutrición y planes"
      :migas="[plan?.usuario?.nombre ?? 'Plan', 'Nueva comida']"
    />

    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section v-if="estado === 'loading'" class="comida-editor__estado gb-tarjeta" aria-busy="true">
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando el plan de alimentación…</p>
    </section>

    <ComidaForm
      v-else-if="estado === 'success'"
      :enviando="enviando"
      :errores-servidor="erroresServidor"
      :catalogo="catalogo"
      :cargando-catalogo="cargandoCatalogo"
      :error-catalogo="errorCatalogo"
      @submit="guardar"
      @cancel="cancelar"
      @recargar-catalogo="cargarCatalogo"
    />

    <section
      v-else
      class="comida-editor__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <XCircle :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Plan no encontrado' : 'No pudimos cargar el plan' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargarPlan">
          <RotateCw :size="16" aria-hidden="true" />
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'alimentacion-listado' }">
          Volver a planes
        </RouterLink>
      </div>
    </section>
  </section>
</template>

<style scoped>
.comida-editor {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
}

.comida-editor .alert {
  margin: 0;
}

.comida-editor__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.comida-editor__estado > :deep(svg) {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.comida-editor__estado h2,
.comida-editor__estado p {
  margin: 0;
}

.comida-editor__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.comida-editor__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.comida-editor__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.comida-editor__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  text-decoration: none;
}
</style>
