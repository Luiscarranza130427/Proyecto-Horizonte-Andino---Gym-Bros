<script setup>
import { Activity, Building2, Contact, History, UserPlus } from 'lucide-vue-next'

import { formatearTiempoRelativo } from '@/shared/utils/formato'

defineProps({
  actividades: { type: Array, required: true },
  ahora: { type: Date, required: true },
})

const MAPA_ACTIVIDAD = {
  'bi-person-plus-fill': UserPlus,
  'bi-clipboard2-pulse-fill': Activity,
  'bi-buildings-fill': Building2,
  'bi-person-badge-fill': Contact,
  'person-plus': UserPlus,
  activity: Activity,
  buildings: Building2,
  contact: Contact,
}

function iconoActividad(nombre) {
  return MAPA_ACTIVIDAD[nombre] || Activity
}

function fechaValida(fecha) {
  return Number.isNaN(new Date(fecha).getTime()) ? null : fecha
}
</script>

<template>
  <section class="actividad gb-tarjeta" aria-labelledby="titulo-actividad">
    <header class="actividad__cabecera">
      <div>
        <p>Últimos movimientos</p>
        <h2 id="titulo-actividad">Actividad reciente</h2>
      </div>
      <span v-if="actividades.length">{{ actividades.length }} eventos</span>
    </header>

    <ol v-if="actividades.length" class="actividad__lista">
      <li v-for="actividad in actividades" :key="actividad.id">
        <span class="actividad__icono" aria-hidden="true">
          <component :is="iconoActividad(actividad.icono)" :size="18" aria-hidden="true" />
        </span>
        <div>
          <strong>{{ actividad.titulo }}</strong>
          <span>{{ actividad.detalle }}</span>
        </div>
        <time :datetime="fechaValida(actividad.fecha)">
          {{ formatearTiempoRelativo(actividad.fecha, ahora) }}
        </time>
      </li>
    </ol>

    <div v-else class="actividad__vacio" role="status">
      <History :size="24" aria-hidden="true" />
      <p>Aún no hay actividad registrada.</p>
    </div>
  </section>
</template>

<style scoped>
.actividad {
  overflow: hidden;
  border-radius: var(--gb-radius-xl);
}

.actividad__cabecera {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem 1.25rem;
  background-color: var(--gb-surface-high-50);
  border-bottom: 1px solid var(--gb-border);
}

.actividad__cabecera p,
.actividad__cabecera h2 {
  margin: 0;
}

.actividad__cabecera p {
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.actividad__cabecera h2 {
  margin-top: 0.25rem;
  font-size: var(--gb-tipo-md);
  font-weight: 800;
  text-transform: uppercase;
}

.actividad__cabecera > span {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
}

.actividad__lista {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 1px;
  margin: 0;
  padding: 0;
  background-color: var(--gb-border);
  list-style: none;
}

.actividad__lista li {
  display: grid;
  grid-template-columns: 2.5rem minmax(0, 1fr) auto;
  align-items: center;
  gap: 0.75rem;
  min-width: 0;
  padding: 1rem 1.25rem;
  background-color: var(--gb-surface);
}

.actividad__icono {
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-lg);
  color: var(--gb-red-text);
}

.actividad__lista div {
  min-width: 0;
  display: grid;
}

.actividad__lista strong,
.actividad__lista div span {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.actividad__lista strong {
  font-size: var(--gb-tipo-sm);
}

.actividad__lista div span,
.actividad__lista time {
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
}

.actividad__lista time {
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}

.actividad__vacio {
  display: grid;
  place-items: center;
  min-height: 8rem;
  color: var(--gb-text-muted);
  text-align: center;
}

.actividad__vacio :deep(svg) {
  color: var(--gb-text-soft);
}

.actividad__vacio p {
  margin: 0.5rem 0 0;
  font-size: var(--gb-tipo-sm);
}

@media (max-width: 90rem) {
  .actividad__lista {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 78rem) {
  .actividad__lista {
    grid-template-columns: 1fr;
  }
}
</style>
