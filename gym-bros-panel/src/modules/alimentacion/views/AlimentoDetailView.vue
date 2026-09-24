<script setup>
import { CheckCircle2, Pencil, Utensils, XCircle } from 'lucide-vue-next'
import { onBeforeUnmount, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

import PageHeader from '@/shared/components/PageHeader.vue'
import { TIPOS_ALIMENTO, UNIDADES, etiquetaDe } from '@/modules/alimentacion/catalogos'
import AlimentoTipoBadge from '@/modules/alimentacion/components/AlimentoTipoBadge.vue'
import { obtenerAlimento } from '@/modules/alimentacion/services/alimentacion.service'
import { formatearNumero } from '@/shared/utils/formato'

const route = useRoute()
const router = useRouter()
const estado = ref('loading')
const alimento = ref(null)
const mensajeError = ref('')
const mensajeExito = ref('')
let solicitudActual = 0

function dato(valor) {
  if (valor === null || valor === undefined || valor === '') return 'No especificado'
  return Array.isArray(valor) ? valor.join(', ') : String(valor)
}

function datoNumerico(valor, sufijo = '') {
  return valor === null || valor === undefined || valor === ''
    ? 'No especificado'
    : `${formatearNumero(valor)}${sufijo}`
}

function siNo(valor) {
  if (valor === null || valor === undefined) return 'No especificado'
  return valor ? 'Sí' : 'No'
}

async function cargar() {
  const idSolicitud = ++solicitudActual
  estado.value = 'loading'
  alimento.value = null
  mensajeError.value = ''

  try {
    const respuesta = await obtenerAlimento(route.params.id)
    if (idSolicitud !== solicitudActual) return
    alimento.value = respuesta
    estado.value = 'success'
  } catch (error) {
    if (idSolicitud !== solicitudActual) return
    mensajeError.value = error?.message || 'No pudimos cargar el alimento.'
    estado.value = error?.status === 404 ? 'not-found' : 'error'
  }
}

watch(
  () => route.params.id,
  () => {
    mensajeExito.value = ''
    const notice = route.query.notice
    if (notice === 'created') mensajeExito.value = 'Alimento creado correctamente.'
    if (notice === 'updated') mensajeExito.value = 'Alimento actualizado correctamente.'
    if (notice === 'created' || notice === 'updated') {
      router.replace({ name: 'alimento-detalle', params: { id: route.params.id } }).catch(() => {})
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
  <section class="alimento-detalle">
    <PageHeader
      :titulo="alimento?.nombre ?? 'Detalle del alimento'"
      descripcion="Consulta la ficha nutricional y el uso del alimento en las comidas."
      seccion="Catálogo de alimentos"
      :ruta-seccion="{ name: 'alimentos-listado' }"
      etiqueta="Alimentación"
      :migas="[alimento?.nombre ?? 'Alimento']"
    >
      <template v-if="estado === 'success' && alimento" #acciones>
        <RouterLink
          class="btn btn-secondary"
          :to="{ name: 'alimento-editar', params: { id: alimento.id } }"
        >
          <Pencil :size="16" aria-hidden="true" />
          <span>Editar</span>
        </RouterLink>
      </template>
    </PageHeader>

    <p v-if="mensajeExito" class="alimento-detalle__exito" role="status">
      <CheckCircle2 :size="18" aria-hidden="true" />
      {{ mensajeExito }}
    </p>
    <p v-if="mensajeError && estado === 'success'" class="alert alert-danger" role="alert">
      {{ mensajeError }}
    </p>

    <section
      v-if="estado === 'loading'"
      class="alimento-detalle__estado gb-tarjeta"
      aria-busy="true"
    >
      <span class="spinner-border" aria-hidden="true"></span>
      <p>Cargando información del alimento…</p>
    </section>

    <div v-else-if="estado === 'success' && alimento" class="detalle">
      <section class="detalle__resumen gb-tarjeta">
        <span class="detalle__icono" aria-hidden="true"
          ><Utensils :size="28" aria-hidden="true"
        /></span>
        <div>
          <p>Alimento del catálogo</p>
          <h2>{{ alimento.nombre }}</h2>
          <AlimentoTipoBadge :tipo="alimento.tipo" />
        </div>
      </section>

      <div class="detalle__rejilla">
        <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-nutricion">
          <header>
            <p>Ficha nutricional</p>
            <h2 id="titulo-nutricion">
              Valores por 100 {{ etiquetaDe(UNIDADES, alimento.unidadBase) }}
            </h2>
          </header>
          <dl>
            <div>
              <dt>Calorías</dt>
              <dd class="tabular">{{ formatearNumero(alimento.calorias) }} kcal</dd>
            </div>
            <div>
              <dt>Proteínas</dt>
              <dd class="tabular">{{ formatearNumero(alimento.proteinas) }} g</dd>
            </div>
            <div>
              <dt>Carbohidratos</dt>
              <dd class="tabular">{{ formatearNumero(alimento.carbohidratos) }} g</dd>
            </div>
            <div>
              <dt>Grasas</dt>
              <dd class="tabular">{{ formatearNumero(alimento.grasas) }} g</dd>
            </div>
            <div>
              <dt>Fibra</dt>
              <dd class="tabular">{{ formatearNumero(alimento.fibra) }} g</dd>
            </div>
            <div>
              <dt>Tipo de alimento</dt>
              <dd>{{ etiquetaDe(TIPOS_ALIMENTO, alimento.tipo) }}</dd>
            </div>
          </dl>
        </section>

        <aside class="detalle__lateral">
          <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-generales">
            <header>
              <p>Resumen operativo</p>
              <h2 id="titulo-generales">Datos generales</h2>
            </header>
            <dl class="detalle__metricas">
              <div>
                <dt>Veces usado en comidas</dt>
                <dd>{{ formatearNumero(alimento.usos) }}</dd>
              </div>
            </dl>
          </section>
        </aside>
      </div>

      <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-preparacion">
        <header>
          <p>Uso y preparación</p>
          <h2 id="titulo-preparacion">Datos del catálogo</h2>
        </header>
        <dl>
          <div>
            <dt>Estado</dt>
            <dd>{{ siNo(alimento.activo) }}</dd>
          </div>
          <div>
            <dt>Estado de preparación</dt>
            <dd>{{ dato(alimento.estadoPreparacion) }}</dd>
          </div>
          <div>
            <dt>Grupo de menú</dt>
            <dd>{{ dato(alimento.grupoMenu) }}</dd>
          </div>
          <div>
            <dt>Tipos de comida</dt>
            <dd>{{ dato(alimento.tiposComida) }}</dd>
          </div>
          <div>
            <dt>Gramos por unidad</dt>
            <dd class="tabular">{{ datoNumerico(alimento.gramosPorUnidad, ' g') }}</dd>
          </div>
          <div>
            <dt>Densidad</dt>
            <dd class="tabular">{{ datoNumerico(alimento.densidadGml, ' g/ml') }}</dd>
          </div>
        </dl>
      </section>

      <section class="detalle__panel gb-tarjeta" aria-labelledby="titulo-porcion">
        <header>
          <p>Porciones y validación</p>
          <h2 id="titulo-porcion">Configuración nutricional</h2>
        </header>
        <dl>
          <div>
            <dt>Porción mínima</dt>
            <dd class="tabular">{{ datoNumerico(alimento.porcionMin, ' g') }}</dd>
          </div>
          <div>
            <dt>Porción máxima</dt>
            <dd class="tabular">{{ datoNumerico(alimento.porcionMax, ' g') }}</dd>
          </div>
          <div>
            <dt>Paso de porción</dt>
            <dd class="tabular">{{ datoNumerico(alimento.pasoPorcion, ' g') }}</dd>
          </div>
          <div>
            <dt>Fuente nutricional</dt>
            <dd>{{ dato(alimento.fuenteNutricional) }}</dd>
          </div>
          <div>
            <dt>Nutrición verificada</dt>
            <dd>{{ siNo(alimento.nutricionVerificada) }}</dd>
          </div>
          <div>
            <dt>Restricciones verificadas</dt>
            <dd>{{ siNo(alimento.restriccionesVerificadas) }}</dd>
          </div>
        </dl>
      </section>
    </div>

    <section
      v-else
      class="alimento-detalle__estado gb-tarjeta"
      :role="estado === 'error' ? 'alert' : 'status'"
    >
      <XCircle :size="48" aria-hidden="true" />
      <h2>
        {{ estado === 'not-found' ? 'Alimento no encontrado' : 'No pudimos cargar el alimento' }}
      </h2>
      <p>{{ mensajeError }}</p>
      <div>
        <button v-if="estado === 'error'" type="button" class="btn btn-primary" @click="cargar">
          Reintentar
        </button>
        <RouterLink class="btn btn-ghost" :to="{ name: 'alimentos-listado' }">
          Volver al catálogo
        </RouterLink>
      </div>
    </section>
  </section>
</template>

<style scoped>
.alimento-detalle {
  display: grid;
  gap: var(--gb-dashboard-gap);
  width: min(100%, 86rem);
  margin: 0 auto;
  padding-bottom: var(--gb-margen);
}

.alimento-detalle__exito {
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

.alimento-detalle .alert {
  margin: 0;
}

.alimento-detalle__estado {
  display: grid;
  place-items: center;
  min-height: 28rem;
  padding: 2rem;
  border-radius: var(--gb-radius-xl);
  text-align: center;
}

.alimento-detalle__estado > svg {
  color: var(--gb-text-soft);
  font-size: 2rem;
}

.alimento-detalle__estado h2,
.alimento-detalle__estado p {
  margin: 0;
}

.alimento-detalle__estado h2 {
  margin-top: 1rem;
  font-size: var(--gb-tipo-lg);
  text-transform: uppercase;
}

.alimento-detalle__estado p {
  margin-top: 0.5rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.alimento-detalle__estado div {
  display: flex;
  gap: 0.75rem;
  margin-top: 1.25rem;
}

.alimento-detalle__estado .btn {
  text-decoration: none;
}

.detalle {
  display: grid;
  gap: var(--gb-gutter, 1.25rem);
}

.detalle__resumen {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto;
  align-items: center;
  gap: 1.25rem;
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
  grid-template-columns: minmax(0, 1.4fr) minmax(20rem, 1fr);
  gap: var(--gb-gutter, 1.25rem);
  align-items: stretch;
}

.detalle__lateral {
  display: grid;
  grid-template-rows: 1fr 1fr;
  gap: var(--gb-gutter, 1.25rem);
  height: 100%;
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

.detalle__metricas {
  grid-template-columns: 1fr !important;
}

.detalle__metricas > div {
  padding: 0.875rem 0 !important;
}

.detalle__metricas dd {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-variant-numeric: tabular-nums;
  font-weight: 800;
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

  .detalle__lateral,
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
