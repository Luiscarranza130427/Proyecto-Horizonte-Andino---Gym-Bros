<script setup>
import {
  Activity,
  Building2,
  CreditCard,
  Dumbbell,
  Minus,
  TrendingDown,
  TrendingUp,
  UserCheck,
  Users,
} from 'lucide-vue-next'
import { computed } from 'vue'

import { formatearNumero } from '@/shared/utils/formato'

const props = defineProps({
  metrica: { type: Object, required: true },
})

const MAPA_ICONOS = {
  'bi-buildings-fill': Building2,
  'bi-people-fill': Users,
  'bi-person-arms-up': Dumbbell,
  'bi-clipboard2-pulse-fill': Activity,
  buildings: Building2,
  people: Users,
  dumbbell: Dumbbell,
  activity: Activity,
  users: Users,
  user: UserCheck,
  plan: CreditCard,
}

const iconoComponente = computed(() => MAPA_ICONOS[props.metrica.icono] || Activity)

const iconoTendencia = computed(() => {
  if (props.metrica.tendencia.tono === 'neutro') return Minus
  return props.metrica.tendencia.tono === 'negativo' ? TrendingDown : TrendingUp
})

const valorFormateado = computed(() =>
  props.metrica.tipoValor === 'texto'
    ? String(props.metrica.valor || 'Sin plan')
    : formatearNumero(props.metrica.valor),
)
const mostrarValorTendencia = computed(() => {
  const tendencia = props.metrica.tendencia
  return Boolean(Number(tendencia.valor) || tendencia.prefijo || tendencia.sufijo)
})
const mostrarTendencia = computed(
  () => mostrarValorTendencia.value || Boolean(props.metrica.tendencia.detalle),
)
const tendenciaFormateada = computed(() => {
  const tendencia = props.metrica.tendencia
  const sufijo = tendencia.sufijo ?? ''
  const separador = sufijo === '%' ? ' ' : ''
  return `${tendencia.prefijo ?? ''}${formatearNumero(tendencia.valor)}${separador}${sufijo}`
})
</script>

<template>
  <article class="metrica gb-tarjeta" :class="`metrica--${metrica.tendencia.tono}`">
    <div class="metrica__cabecera">
      <span>{{ metrica.etiqueta }}</span>
      <component :is="iconoComponente" :size="20" aria-hidden="true" />
    </div>

    <strong>{{ valorFormateado }}</strong>

    <p
      v-if="mostrarTendencia"
      class="metrica__tendencia"
      :class="`metrica__tendencia--${metrica.tendencia.tono}`"
    >
      <component :is="iconoTendencia" v-if="mostrarValorTendencia" :size="16" aria-hidden="true" />
      <b v-if="mostrarValorTendencia">{{ tendenciaFormateada }}</b>
      <span>{{ metrica.tendencia.detalle }}</span>
    </p>
  </article>
</template>

<style scoped>
.metrica {
  position: relative;
  min-width: 0;
  padding: 1.25rem;
  overflow: hidden;
  border-radius: var(--gb-radius-lg);
}

.metrica::after {
  position: absolute;
  right: 0;
  bottom: 0;
  left: 0;
  height: 0.25rem;
  background-color: var(--gb-tenant-secondary, var(--gb-border));
  content: '';
  opacity: 0.5;
}

.metrica__cabecera {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 0.75rem;
  color: var(--gb-text-muted);
}

.metrica__cabecera span {
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
  letter-spacing: 0.07em;
  text-transform: uppercase;
}

.metrica__cabecera :deep(svg) {
  color: var(--gb-text-soft);
}

.metrica > strong {
  display: block;
  overflow: hidden;
  margin-top: 1.125rem;
  font-family: var(--gb-fuente-titulo);
  font-size: calc(var(--gb-tipo-metrica) - 5px);
  font-weight: 900;
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.04em;
  line-height: 1;
  white-space: nowrap;
  text-overflow: ellipsis;
}

.metrica__tendencia {
  display: flex;
  align-items: center;
  gap: 0.375rem;
  margin: 0.875rem 0 0;
  font-size: var(--gb-tipo-xs);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.metrica__tendencia span {
  min-width: 0;
  overflow: hidden;
  color: var(--gb-text-muted);
  text-overflow: ellipsis;
}

.metrica__tendencia--positivo {
  color: var(--gb-green);
}

.metrica__tendencia--neutro {
  color: var(--gb-amber);
}

.metrica__tendencia--negativo {
  color: var(--gb-error);
}
</style>
