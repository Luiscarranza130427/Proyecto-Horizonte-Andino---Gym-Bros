<script setup>
import { computed } from 'vue'

const props = defineProps({
  estado: { type: String, required: true },
})

const activo = computed(() => props.estado === 'active')
</script>

<template>
  <span class="estado" :class="activo ? 'estado--activo' : 'estado--inactivo'">
    <span aria-hidden="true"></span>
    {{ activo ? 'Activo' : 'Inactivo' }}
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

.estado--inactivo > span {
  background-color: var(--gb-text-muted);
}
</style>
