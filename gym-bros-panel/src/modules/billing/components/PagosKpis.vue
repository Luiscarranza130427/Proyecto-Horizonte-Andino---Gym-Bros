<script setup>
import { CreditCard, DollarSign } from 'lucide-vue-next'
import { computed } from 'vue'

const props = defineProps({
  metricas: {
    type: Object,
    default: () => ({
      totalIngresos: 0,
      totalTransacciones: 0,
      moneda: 'PEN',
    }),
  },
  cargando: {
    type: Boolean,
    default: false,
  },
})

const formatearMonto = (monto) => {
  return new Intl.NumberFormat('es-PE', {
    style: 'currency',
    currency: 'PEN',
    minimumFractionDigits: 2,
  }).format(monto || 0)
}

const itemsKpi = computed(() => [
  {
    id: 'ingresos',
    titulo: 'Ingresos Totales',
    valor: formatearMonto(props.metricas?.totalIngresos),
    detalle: 'Volumen facturado acumulado',
    icono: DollarSign,
    color: 'var(--gb-accent)',
    bg: 'rgba(238, 255, 0, 0.1)',
  },
  {
    id: 'transacciones',
    titulo: 'Transacciones',
    valor: (props.metricas?.totalTransacciones || 0).toLocaleString('es-PE'),
    detalle: 'Pagos cobrados con éxito',
    icono: CreditCard,
    color: 'var(--gb-emerald, #10b981)',
    bg: 'rgba(16, 185, 129, 0.1)',
  },
])
</script>

<template>
  <section class="pagos-kpis" aria-label="Métricas clave de pagos">
    <div
      v-for="kpi in itemsKpi"
      :key="kpi.id"
      class="gb-tarjeta pagos-kpi-card"
      :class="{ 'pagos-kpi-card--loading': cargando }"
    >
      <div class="pagos-kpi-card__header">
        <span class="pagos-kpi-card__titulo">{{ kpi.titulo }}</span>
        <div
          class="pagos-kpi-card__icono"
          :style="{ color: kpi.color, backgroundColor: kpi.bg }"
          aria-hidden="true"
        >
          <component :is="kpi.icono" :size="20" />
        </div>
      </div>

      <div class="pagos-kpi-card__cuerpo">
        <div v-if="cargando" class="pagos-kpi-card__skeleton"></div>
        <span v-else class="pagos-kpi-card__valor">{{ kpi.valor }}</span>
        <p class="pagos-kpi-card__detalle">{{ kpi.detalle }}</p>
      </div>
    </div>
  </section>
</template>

<style scoped>
.pagos-kpis {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(15rem, 1fr));
  gap: 1rem;
}

.pagos-kpi-card {
  padding: 1.25rem;
  display: flex;
  flex-direction: column;
  justify-content: space-between;
  border-radius: var(--gb-radius-lg);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
  transition:
    transform 0.2s ease,
    border-color 0.2s ease;
}

.pagos-kpi-card:hover {
  border-color: var(--gb-border-focus, rgba(238, 255, 0, 0.3));
  transform: translateY(-2px);
}

.pagos-kpi-card__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}

.pagos-kpi-card__titulo {
  font-size: var(--gb-tipo-xs, 0.75rem);
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--gb-text-soft, #a3a3a3);
}

.pagos-kpi-card__icono {
  display: grid;
  place-items: center;
  width: 2.25rem;
  height: 2.25rem;
  border-radius: var(--gb-radius-md);
}

.pagos-kpi-card__valor {
  display: block;
  font-size: 1.5rem;
  font-weight: 800;
  color: var(--gb-text, #ffffff);
  line-height: 1.2;
}

.pagos-kpi-card__detalle {
  margin: 0.35rem 0 0;
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-muted, #737373);
}

.pagos-kpi-card__skeleton {
  height: 1.8rem;
  width: 65%;
  border-radius: var(--gb-radius-sm);
  background: linear-gradient(
    90deg,
    var(--gb-surface-high) 25%,
    var(--gb-surface-highest) 50%,
    var(--gb-surface-high) 75%
  );
  background-size: 200% 100%;
  animation: skeleton-shine 1.5s infinite;
}

@keyframes skeleton-shine {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>
