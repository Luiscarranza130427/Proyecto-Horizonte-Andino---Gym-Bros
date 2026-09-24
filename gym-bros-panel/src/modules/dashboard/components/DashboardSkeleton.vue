<template>
  <div class="skeleton" role="status" aria-live="polite">
    <span class="visually-hidden">Cargando información del dashboard…</span>
    <div class="skeleton__banner gb-tarjeta" aria-hidden="true"></div>
    <div class="skeleton__metricas" aria-hidden="true">
      <div v-for="indice in 4" :key="indice" class="skeleton__metrica gb-tarjeta"></div>
    </div>
    <div class="skeleton__analitica" aria-hidden="true">
      <div class="skeleton__panel gb-tarjeta"></div>
      <div class="skeleton__panel gb-tarjeta"></div>
    </div>
    <div class="skeleton__actividad gb-tarjeta" aria-hidden="true"></div>
  </div>
</template>

<style scoped>
.skeleton {
  display: grid;
  gap: var(--gb-dashboard-gap);
}

.skeleton__banner,
.skeleton__metrica,
.skeleton__panel,
.skeleton__actividad {
  background-color: var(--gb-surface-high);
  animation: pulso 1.1s ease-in-out infinite alternate;
}

.skeleton__banner {
  min-height: 14rem;
}

.skeleton__metricas {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--gb-gutter);
}

.skeleton__metrica {
  min-height: 9.5rem;
}

.skeleton__analitica {
  display: grid;
  grid-template-columns: minmax(0, 2fr) minmax(18rem, 1fr);
  gap: var(--gb-gutter);
}

.skeleton__panel {
  min-height: calc(var(--gb-chart-height) + 5rem);
}

.skeleton__actividad {
  min-height: 9rem;
}

@keyframes pulso {
  from {
    opacity: 0.52;
  }
  to {
    opacity: 0.85;
  }
}

@media (max-width: 78rem) {
  .skeleton__metricas {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .skeleton__analitica {
    grid-template-columns: 1fr;
  }
}
</style>
