<script setup>
import { computed } from 'vue'

const props = defineProps({
  estado: { type: String, default: '' },
  suscripcion: { type: Boolean, default: false },
})

const activo = computed(() => props.estado === 'active')
const etiqueta = computed(() =>
  props.suscripcion
    ? ['Activo', 'Inactivo', 'Por Vencer'].includes(props.estado)
      ? props.estado
      : 'Sin información'
    : activo.value
      ? 'Activa'
      : 'Inactiva',
)
const clase = computed(() =>
  props.suscripcion
    ? ({ Activo: 'activo', Inactivo: 'rojo', 'Por Vencer': 'amarillo' }[props.estado] ?? 'inactivo')
    : activo.value
      ? 'activo'
      : 'inactivo',
)
</script>

<template>
  <span class="estado" :class="`estado--${clase}`">
    <span aria-hidden="true"></span>
    {{ etiqueta }}
  </span>
</template>

<style scoped>
.estado {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  padding: 0.25rem 0.5rem;
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  white-space: nowrap;
}

.estado > span {
  width: 0.375rem;
  height: 0.375rem;
  border-radius: var(--gb-radius-pill);
}

.estado--activo {
  background-color: rgba(var(--gb-green-rgb), 0.08);
  border-color: rgba(var(--gb-green-rgb), 0.3);
  color: var(--gb-green);
}

.estado--activo > span {
  background-color: var(--gb-green);
}

.estado--inactivo {
  background-color: var(--gb-surface-high);
  color: var(--gb-text-muted);
}

.estado--rojo {
  color: var(--gb-error);
  border-color: currentColor;
}
.estado--amarillo {
  color: var(--gb-warning, #ffb800);
  border-color: currentColor;
}
.estado--rojo > span,
.estado--amarillo > span {
  background-color: currentColor;
}

.estado--inactivo > span {
  background-color: var(--gb-text-muted);
}
</style>
