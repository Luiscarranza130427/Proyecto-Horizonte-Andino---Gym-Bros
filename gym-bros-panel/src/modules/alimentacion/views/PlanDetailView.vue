<script setup>
import { CheckCircle2, RotateCw, Utensils, XCircle } from 'lucide-vue-next'
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PageHeader from '@/shared/components/PageHeader.vue'
import { TIPOS_COMIDA, etiquetaDe } from '@/modules/alimentacion/catalogos'
import HorarioDeComidas from '@/modules/alimentacion/components/HorarioDeComidas.vue'
import { eliminarComida, obtenerPlan } from '@/modules/alimentacion/services/alimentacion.service'
import { formatearFecha, formatearNumero } from '@/shared/utils/formato'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const plan = ref(null)
const mensajeError = ref('')
const mensajeExito = ref('')
const comidaSeleccionada = ref(null)
const eliminando = ref(false)
let solicitudActual = 0

/**
 * Los cuatro macros que el entrenador fija en `planes_alimentacion`. La fibra se
 * suma pero no se fija, así que se muestra aparte y sin comparación.
 */
const MACROS = [
  { clave: 'calorias', etiqueta: 'Calorías', unidad: 'kcal' },
  { clave: 'proteinas', etiqueta: 'Proteínas', unidad: 'g' },
  { clave: 'carbohidratos', etiqueta: 'Carbohidratos', unidad: 'g' },
  { clave: 'grasas', etiqueta: 'Grasas', unidad: 'g' },
]

/**
 * El dato con valor de la pantalla: lo que suman las comidas frente a lo que
 * fijó el entrenador, y la diferencia entre ambos.
 *
 * La barra sólo traduce esa proporción a una longitud; el número manda y va en
 * texto. No hay semáforo: el panel no sabe cuánta desviación es aceptable.
 */
const comparativa = computed(() => {
  if (!plan.value) return []

  return MACROS.map(({ clave, etiqueta, unidad }) => {
    const real = plan.value.macros[clave]
    const objetivo = plan.value.objetivos[clave]
    return {
      clave,
      etiqueta,
      unidad,
      real,
      objetivo,
      diferencia: Math.round(real - objetivo),
      porcentaje: objetivo ? Math.min(100, Math.round((real / objetivo) * 100)) : 0,
      excede: Boolean(objetivo) && real > objetivo,
    }
  })
})

function diferenciaLegible({ objetivo, diferencia, unidad }) {
  if (!objetivo) return 'Sin objetivo fijado'
  if (diferencia === 0) return 'Coincide con el objetivo'
  const signo = diferencia > 0 ? '+' : '−'
  return `${signo}${formatearNumero(Math.abs(diferencia))} ${unidad}`
}

/**
 * @param {object} [opciones]
 * @param {boolean} [opciones.silencioso]
 *   Refresco posterior a una acción que SÍ funcionó. No vacía la ficha ni la
 *   manda al estado de error: castigaría al usuario por un fallo que no impidió
 *   lo que pidió. Se avisa de que los totales pueden estar atrasados y ya.
 */
async function cargar({ silencioso = false } = {}) {
  const idSolicitud = ++solicitudActual

  if (!silencioso) {
    estado.value = 'loading'
    plan.value = null
    comidaSeleccionada.value = null
    mensajeError.value = ''
  }

  try {
    const respuesta = await obtenerPlan(route.params.id)
    if (idSolicitud !== solicitudActual) return
    plan.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return

    if (silencioso) {
      mensajeError.value =
        'No pudimos refrescar el plan: los totales que ves pueden estar atrasados.'
      return
    }

    mensajeError.value = error?.message || 'No pudimos cargar el plan de alimentación.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

async function confirmarEliminacion() {
  if (!comidaSeleccionada.value || eliminando.value) return
  eliminando.value = true
  mensajeError.value = ''
  mensajeExito.value = ''

  const comida = comidaSeleccionada.value

  try {
    await eliminarComida(route.params.id, comida.id)
    comidaSeleccionada.value = null
    mensajeExito.value = `La comida de las ${comida.horaSugerida || 'sin hora'} fue retirada del plan.`
    await cargar({ silencioso: true })
  } catch (error) {
    /*
     * Falla una ACCIÓN, no la carga: la ficha se queda como está y el aviso va
     * encima. Un 422 SIN `errors` es una regla de negocio —«un plan necesita al
     * menos una comida»— y su `message` se muestra tal cual.
     */
    comidaSeleccionada.value = null
    mensajeError.value = error?.message || 'No pudimos retirar la comida.'
  } finally {
    eliminando.value = false
  }
}

watch(
  () => route.params.id,
  () => {
    mensajeExito.value = ''
    const notice = route.query.notice
    if (notice === 'created') mensajeExito.value = 'Comida añadida al plan.'
    if (notice === 'updated') mensajeExito.value = 'Comida actualizada correctamente.'
    if (notice === 'created' || notice === 'updated') {
      router
        .replace({ name: 'plan-alimentacion-detalle', params: { id: route.params.id } })
        .catch(() => {})
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
  <section class="plan-detalle">
    <PageHeader
      :titulo="plan?.usuario?.nombre ? `Plan de ${plan.usuario.nombre}` : 'Plan de alimentación'"
      descripcion="Revisa el horario de comidas y cuánto se aparta de los objetivos fijados."
      seccion="Alimentación"
      :ruta-seccion="{ name: 'alimentacion-listado' }"
      etiqueta="Nutrición y planes"
      :migas="[plan?.usuario?.nombre ?? 'Plan']"
    />

    <p v-if="mensajeExito" class="plan-detalle__exito" role="status">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section v-if="estado === 'loading'" class="plan-detalle__estado gb-tarjeta" aria-busy="true">
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando el plan de alimentación…</p>
    </section>

    <div v-else-if="estado === 'success' && plan" class="detalle">
      <section class="detalle__resumen gb-tarjeta">
        <span class="detalle__icono" aria-hidden="true"
          ><Utensils :size="28" aria-hidden="true"
        /></span>
        <div>
          <p>Plan de alimentación</p>
          <h2>{{ plan.usuario?.nombre || 'Usuario sin nombre' }}</h2>
          <span>{{ plan.empresa?.nombre || 'Empresa sin asignar' }}</span>
        </div>
        <span
          class="detalle__situacion"
          :class="plan.activo ? 'detalle__situacion--activo' : 'detalle__situacion--inactivo'"
        >
          {{ plan.activo ? 'Activo' : 'Finalizado' }}
        </span>
      </section>

      <div class="detalle__rejilla">
        <HorarioDeComidas
          :comidas="plan.comidas"
          :id-plan="plan.id"
          :ocupado="eliminando"
          @eliminar="comidaSeleccionada = $event"
        />

        <aside class="detalle__lateral">
          <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-objetivos">
            <header>
              <p>Objetivo frente a lo servido</p>
              <h2 id="titulo-objetivos">Macros del plan</h2>
            </header>

            <dl class="macros">
              <div v-for="fila in comparativa" :key="fila.clave" class="macros__fila">
                <dt>{{ fila.etiqueta }}</dt>
                <dd>
                  <span class="macros__cifra">
                    {{ formatearNumero(fila.real) }}
                    <small>
                      / {{ fila.objetivo ? formatearNumero(fila.objetivo) : '—' }}
                      {{ fila.unidad }}
                    </small>
                  </span>
                  <span
                    class="macros__barra"
                    :class="{ 'macros__barra--excede': fila.excede }"
                    aria-hidden="true"
                  >
                    <span :style="{ width: `${fila.porcentaje}%` }"></span>
                  </span>
                  <small class="macros__diferencia">{{ diferenciaLegible(fila) }}</small>
                </dd>
              </div>

              <div class="macros__fila macros__fila--suelta">
                <dt>Fibra</dt>
                <dd>
                  <span class="macros__cifra">
                    {{ formatearNumero(plan.macros.fibra) }} <small>g</small>
                  </span>
                  <small class="macros__diferencia">El plan no fija un objetivo de fibra.</small>
                </dd>
              </div>
            </dl>
          </section>

          <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-generales">
            <header>
              <p>Resumen del plan</p>
              <h2 id="titulo-generales">Datos generales</h2>
            </header>
            <dl class="generales">
              <div>
                <dt>Objetivo</dt>
                <dd>{{ plan.objetivo || 'Sin objetivo registrado.' }}</dd>
              </div>
              <div>
                <dt>Inicio</dt>
                <dd>{{ plan.fechaInicio ? formatearFecha(plan.fechaInicio) : '—' }}</dd>
              </div>
              <div>
                <dt>Fin</dt>
                <dd>{{ plan.fechaFin ? formatearFecha(plan.fechaFin) : '—' }}</dd>
              </div>
              <div>
                <dt>Comidas al día</dt>
                <dd class="tabular">{{ formatearNumero(plan.totalComidas) }}</dd>
              </div>
            </dl>
          </section>
        </aside>
      </div>
    </div>

    <section
      v-else
      class="plan-detalle__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <XCircle :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Plan no encontrado' : 'No pudimos cargar el plan' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar()">
          <RotateCw :size="16" aria-hidden="true" />
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'alimentacion-listado' }">
          Volver a planes
        </RouterLink>
      </div>
    </section>

    <ConfirmDialog
      :abierto="Boolean(comidaSeleccionada)"
      titulo="¿Retirar esta comida?"
      :descripcion="`Se retirará del plan la comida «${etiquetaDe(TIPOS_COMIDA, comidaSeleccionada?.tipoComida)}» de las ${comidaSeleccionada?.horaSugerida || 'sin hora'}, con todos sus alimentos.`"
      :confirmando="eliminando"
      etiqueta-confirmar="Retirar comida"
      etiqueta-confirmando="Retirando…"
      @cancelar="comidaSeleccionada = null"
      @confirmar="confirmarEliminacion"
    />
  </section>
</template>

<style scoped>
.plan-detalle {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 92rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.plan-detalle .alert {
  margin: 0;
}

.plan-detalle__exito {
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

.plan-detalle__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.plan-detalle__estado > svg {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.plan-detalle__estado h2,
.plan-detalle__estado p {
  margin: 0;
}

.plan-detalle__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.plan-detalle__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.plan-detalle__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.plan-detalle__estado .btn {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
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

.detalle__situacion {
  display: inline-block;
  padding: 0.375rem 0.75rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-pill);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  white-space: nowrap;
}

.detalle__situacion--activo {
  color: var(--gb-green);
}

.detalle__situacion--inactivo {
  color: var(--gb-text-muted);
}

.detalle__rejilla {
  display: grid;
  grid-template-columns: minmax(0, 1.7fr) minmax(19rem, 0.8fr);
  gap: var(--gb-gutter);
  align-items: start;
}

.detalle__lateral {
  display: grid;
  gap: var(--gb-gutter);
}

.detalle__panel {
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.detalle__panel header {
  padding-bottom: 0.875rem;
  border-bottom: 1px solid var(--gb-border);
}

.detalle__panel header p,
.detalle__panel header h2 {
  margin: 0;
}

.detalle__panel header h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  text-transform: uppercase;
}

.detalle__panel dl {
  display: grid;
  margin: 0;
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

.macros__fila {
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.macros__fila:last-child {
  border-bottom: 0;
}

.macros__cifra {
  display: block;
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-variant-numeric: tabular-nums;
  font-weight: 800;
}

.macros__cifra small {
  color: var(--gb-text-muted);
  font-family: var(--gb-fuente-texto);
  font-size: var(--gb-tipo-sm);
  font-weight: 400;
}

.macros__barra {
  display: block;
  height: 0.375rem;
  margin-top: 0.5rem;
  overflow: hidden;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
}

.macros__barra > span {
  display: block;
  height: 100%;
  background-color: var(--gb-green);
  border-radius: var(--gb-radius-pill);
}

.macros__barra--excede > span {
  background-color: var(--gb-amber);
}

.macros__diferencia {
  display: block;
  margin-top: 0.375rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-variant-numeric: tabular-nums;
}

.macros__fila--suelta .macros__cifra {
  font-size: var(--gb-tipo-md);
}

.generales > div {
  padding: 0.875rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.generales > div:last-child {
  border-bottom: 0;
}

.tabular {
  font-variant-numeric: tabular-nums;
}

@media (max-width: 78rem) {
  .detalle__rejilla {
    grid-template-columns: 1fr;
  }

  .detalle__lateral {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    grid-template-rows: auto;
  }
}

@media (max-width: 52rem) {
  .detalle__resumen {
    grid-template-columns: auto minmax(0, 1fr);
  }

  .detalle__resumen > :last-child {
    grid-column: 1 / -1;
    justify-self: start;
  }

  .detalle__lateral {
    grid-template-columns: 1fr;
  }
}
</style>
