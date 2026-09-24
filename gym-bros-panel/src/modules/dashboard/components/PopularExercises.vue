<script setup>
import { Dumbbell } from 'lucide-vue-next'
import { computed } from 'vue'

import { formatearNumero } from '@/shared/utils/formato'

const props = defineProps({
  ejercicios: { type: Array, required: true },
})

const maximo = computed(() => Math.max(...props.ejercicios.map((ejercicio) => ejercicio.usos), 1))
</script>

<template>
  <section class="populares gb-tarjeta" aria-labelledby="titulo-populares">
    <header>
      <p>Catálogo en movimiento</p>
      <h2 id="titulo-populares">Ejercicios más usados</h2>
    </header>

    <ol v-if="ejercicios.length" class="populares__lista">
      <li v-for="(ejercicio, indice) in ejercicios" :key="ejercicio.id">
        <span class="populares__posicion">{{ String(indice + 1).padStart(2, '0') }}</span>
        <div class="populares__datos">
          <div>
            <strong>{{ ejercicio.nombre }}</strong>
            <span>{{ ejercicio.categoria }}</span>
          </div>
          <b>{{ formatearNumero(ejercicio.usos) }} <small>usos</small></b>
          <span class="populares__barra" aria-hidden="true">
            <span :style="{ width: `${(ejercicio.usos / maximo) * 100}%` }"></span>
          </span>
        </div>
      </li>
    </ol>

    <div v-else class="populares__vacio" role="status">
      <Dumbbell :size="32" aria-hidden="true" />
      <p>Aún no hay ejercicios con usos registrados.</p>
    </div>
  </section>
</template>

<style scoped>
.populares {
  min-width: 0;
  padding: 1.25rem;
  border-radius: var(--gb-radius-xl);
}

.populares header p,
.populares header h2 {
  margin: 0;
}

.populares header p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.populares header h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  font-weight: 800;
  text-transform: uppercase;
}

.populares__lista {
  display: grid;
  gap: 0.25rem;
  margin: 1rem 0 0;
  padding: 0;
  list-style: none;
}

.populares__lista li {
  display: grid;
  grid-template-columns: 2rem minmax(0, 1fr);
  gap: 0.75rem;
  padding: 0.75rem 0;
  border-bottom: 1px solid var(--gb-border);
}

.populares__lista li:last-child {
  border-bottom: 0;
}

.populares__posicion {
  color: var(--gb-red-text);
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-xs);
  font-weight: 800;
}

.populares__datos {
  min-width: 0;
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 0.5rem;
}

.populares__datos > div {
  min-width: 0;
  display: grid;
}

.populares__datos strong {
  overflow: hidden;
  font-size: var(--gb-tipo-xs);
  text-overflow: ellipsis;
  text-transform: uppercase;
  white-space: nowrap;
}

.populares__datos > div span,
.populares__datos b small {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 400;
}

.populares__datos b {
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-sm);
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.populares__barra {
  grid-column: 1 / -1;
  height: 0.25rem;
  overflow: hidden;
  background-color: var(--gb-surface-highest);
  border-radius: var(--gb-radius-pill);
}

.populares__barra > span {
  display: block;
  height: 100%;
  background-color: var(--gb-red);
  border-radius: inherit;
}

.populares__vacio {
  display: grid;
  place-items: center;
  min-height: var(--gb-chart-height);
  color: var(--gb-text-muted);
  text-align: center;
}

.populares__vacio :deep(svg) {
  color: var(--gb-text-soft);
}

.populares__vacio p {
  margin: 0.75rem 0 0;
  font-size: var(--gb-tipo-sm);
}
</style>
