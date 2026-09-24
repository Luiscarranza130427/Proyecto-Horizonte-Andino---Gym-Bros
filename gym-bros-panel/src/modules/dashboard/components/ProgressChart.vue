<script setup>
import { computed, nextTick, onBeforeUnmount, onMounted, useTemplateRef, watch } from 'vue'
import {
  CategoryScale,
  Chart,
  LineController,
  LineElement,
  LinearScale,
  PointElement,
  Tooltip,
} from 'chart.js'

import { TrendingUp } from 'lucide-vue-next'
import { formatearNumero } from '@/shared/utils/formato'

Chart.register(CategoryScale, LinearScale, PointElement, LineElement, LineController, Tooltip)

const props = defineProps({
  progreso: { type: Object, required: true },
})

const lienzo = useTemplateRef('lienzo')
let grafico = null

const tieneDatos = computed(
  () =>
    props.progreso.etiquetas.length > 0 &&
    props.progreso.etiquetas.length === props.progreso.valores.length,
)

const descripcion = computed(() => {
  if (!tieneDatos.value) return 'No hay datos de progreso disponibles.'

  return props.progreso.etiquetas
    .map(
      (etiqueta, indice) =>
        `${etiqueta}: ${formatearNumero(props.progreso.valores[indice])} ${props.progreso.unidad}`,
    )
    .join('. ')
})

function leerToken(nombre) {
  return getComputedStyle(document.documentElement).getPropertyValue(nombre).trim()
}

function destruirGrafico() {
  grafico?.destroy()
  grafico = null
}

function crearGrafico() {
  destruirGrafico()
  if (!tieneDatos.value || !lienzo.value) return

  const reducirMovimiento = window.matchMedia?.('(prefers-reduced-motion: reduce)').matches
  const rojo = leerToken('--gb-red')
  const texto = leerToken('--gb-text-muted')
  const borde = leerToken('--gb-border')
  const superficie = leerToken('--gb-surface-high')

  grafico = new Chart(lienzo.value, {
    type: 'line',
    data: {
      labels: props.progreso.etiquetas,
      datasets: [
        {
          data: props.progreso.valores,
          borderColor: rojo,
          backgroundColor: rojo,
          borderWidth: 2,
          pointBackgroundColor: superficie,
          pointBorderColor: rojo,
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 5,
          tension: 0.28,
        },
      ],
    },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: reducirMovimiento ? 0 : 350 },
      interaction: { intersect: false, mode: 'index' },
      plugins: {
        legend: { display: false },
        tooltip: {
          displayColors: false,
          callbacks: {
            label: (contexto) => `${formatearNumero(contexto.parsed.y)} ${props.progreso.unidad}`,
          },
        },
      },
      scales: {
        x: {
          grid: { display: false },
          border: { color: borde },
          ticks: { color: texto, font: { size: 11 } },
        },
        y: {
          beginAtZero: false,
          grid: { color: borde },
          border: { display: false },
          ticks: {
            color: texto,
            font: { size: 11 },
            maxTicksLimit: 5,
            callback: (valor) => formatearNumero(valor),
          },
        },
      },
    },
  })
}

onMounted(() => nextTick(crearGrafico))
watch(
  [() => props.progreso.etiquetas, () => props.progreso.valores],
  () => nextTick(crearGrafico),
  { deep: true },
)
onBeforeUnmount(destruirGrafico)
</script>

<template>
  <section class="progreso gb-tarjeta" aria-labelledby="titulo-progreso">
    <header class="progreso__cabecera">
      <div>
        <p>Rendimiento agregado</p>
        <h2 id="titulo-progreso">{{ progreso.titulo }}</h2>
        <span>{{ progreso.descripcion }}</span>
      </div>

      <p v-if="tieneDatos" class="progreso__resumen">
        <span>{{ progreso.resumen.etiqueta }}</span>
        <strong>{{ formatearNumero(progreso.resumen.valor) }}</strong>
        <small>{{ progreso.resumen.detalle }}</small>
      </p>
    </header>

    <div v-if="tieneDatos" class="progreso__grafico">
      <canvas ref="lienzo" role="img" :aria-label="descripcion"></canvas>
      <dl class="visually-hidden">
        <template v-for="(etiqueta, indice) in progreso.etiquetas" :key="etiqueta">
          <dt>{{ etiqueta }}</dt>
          <dd>{{ formatearNumero(progreso.valores[indice]) }} {{ progreso.unidad }}</dd>
        </template>
      </dl>
    </div>

    <div v-else class="estado-vacio" role="status">
      <TrendingUp :size="32" aria-hidden="true" />
      <p>Aún no hay progreso suficiente para construir la gráfica.</p>
    </div>
  </section>
</template>

<style scoped>
.progreso {
  min-width: 0;
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.progreso__cabecera {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1.5rem;
  margin-bottom: 1rem;
}

.progreso__cabecera p,
.progreso__cabecera h2,
.progreso__cabecera span {
  margin: 0;
}

.progreso__cabecera > div > p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.progreso__cabecera h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  font-weight: 800;
  text-transform: uppercase;
}

.progreso__cabecera > div > span {
  display: block;
  margin-top: 0.375rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.progreso__resumen {
  flex: none;
  display: grid;
  text-align: right;
}

.progreso__resumen span,
.progreso__resumen small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.progreso__resumen strong {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-lg);
  font-variant-numeric: tabular-nums;
}

.progreso__resumen small {
  color: var(--gb-green);
}

.progreso__grafico {
  position: relative;
  height: var(--gb-chart-height);
}

.estado-vacio {
  display: grid;
  place-items: center;
  min-height: var(--gb-chart-height);
  padding: 2rem;
  color: var(--gb-text-muted);
  text-align: center;
}

.estado-vacio i {
  color: var(--gb-text-soft);
  font-size: 1.75rem;
}

.estado-vacio p {
  max-width: 24rem;
  margin: 0.75rem 0 0;
  font-size: var(--gb-tipo-sm);
}

@media (max-width: 44rem) {
  .progreso__cabecera {
    display: grid;
  }

  .progreso__resumen {
    text-align: left;
  }
}
</style>
