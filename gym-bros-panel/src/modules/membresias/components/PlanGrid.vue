<script setup>
import { ChevronLeft, ChevronRight, Inbox } from 'lucide-vue-next'

import PlanCard from './PlanCard.vue'

defineProps({
  items: {
    type: Array,
    default: () => [],
  },
  paginacion: {
    type: Object,
    default: () => ({
      pagina: 1,
      ultimaPagina: 1,
      porPagina: 6,
      total: 0,
      desde: 0,
      hasta: 0,
    }),
  },
  cargando: {
    type: Boolean,
    default: false,
  },
  gestionable: {
    type: Boolean,
    default: true,
  },
  enlaceAdquisicion: {
    type: String,
    default: '',
  },
})

const emit = defineEmits(['eliminar', 'cambiarPagina'])
</script>

<template>
  <div class="plan-grid-contenedor">
    <!-- Skeletons durante la carga -->
    <div v-if="cargando" class="plan-grid">
      <div v-for="n in 6" :key="`skeleton-${n}`" class="plan-card-skeleton gb-tarjeta">
        <div class="skeleton-header">
          <div class="skeleton-icon"></div>
          <div class="skeleton-titles">
            <div class="skeleton-line skeleton-line--title"></div>
            <div class="skeleton-line skeleton-line--subtitle"></div>
          </div>
        </div>
        <div class="skeleton-price-block"></div>
        <div class="skeleton-chips">
          <div class="skeleton-chip"></div>
          <div class="skeleton-chip"></div>
        </div>
        <div class="skeleton-services">
          <div class="skeleton-line"></div>
          <div class="skeleton-line"></div>
          <div class="skeleton-line"></div>
        </div>
        <div class="skeleton-footer"></div>
      </div>
    </div>

    <!-- Estado vacío si no hay coincidencias -->
    <div v-else-if="items.length === 0" class="plan-grid-vacio gb-tarjeta">
      <div class="plan-grid-vacio__icono-caja">
        <Inbox :size="48" class="plan-grid-vacio__icono" aria-hidden="true" />
      </div>
      <h3 class="plan-grid-vacio__titulo">No se encontraron planes comerciales</h3>
      <p class="plan-grid-vacio__texto">
        Intenta ajustar los criterios de búsqueda o registra una nueva membresía comercial.
      </p>
    </div>

    <!-- Rejilla con las tarjetas reales -->
    <div v-else class="plan-grid">
      <PlanCard
        v-for="plan in items"
        :key="plan.id"
        :plan="plan"
        :gestionable="gestionable"
        :enlace-adquisicion="enlaceAdquisicion"
        @eliminar="emit('eliminar', $event)"
      />
    </div>

    <!-- Paginación -->
    <div v-if="paginacion.total > 0" class="plan-grid__paginacion gb-tarjeta">
      <p class="plan-grid__conteo">
        Mostrando <strong>{{ paginacion.desde }}</strong> a
        <strong>{{ paginacion.hasta }}</strong> de <strong>{{ paginacion.total }}</strong> planes
      </p>

      <div class="plan-grid__controles">
        <button
          type="button"
          class="btn btn-secondary btn-sm"
          :disabled="paginacion.pagina <= 1 || cargando"
          aria-label="Página anterior"
          @click="emit('cambiarPagina', paginacion.pagina - 1)"
        >
          <ChevronLeft :size="16" aria-hidden="true" />
          <span>Anterior</span>
        </button>

        <span class="plan-grid__pagina-actual">
          Página {{ paginacion.pagina }} de {{ paginacion.ultimaPagina }}
        </span>

        <button
          type="button"
          class="btn btn-secondary btn-sm"
          :disabled="paginacion.pagina >= paginacion.ultimaPagina || cargando"
          aria-label="Página siguiente"
          @click="emit('cambiarPagina', paginacion.pagina + 1)"
        >
          <span>Siguiente</span>
          <ChevronRight :size="16" aria-hidden="true" />
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.plan-grid-contenedor {
  display: grid;
  gap: 1.5rem;
}

.plan-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(22rem, 1fr));
  gap: 1.5rem;
  align-items: stretch;
}

/* Estado Vacío */
.plan-grid-vacio {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  text-align: center;
  padding: 4rem 1.5rem;
  border-radius: var(--gb-radius-xl, 1rem);
  border: 1px solid rgba(255, 255, 255, 0.08);
  background-color: var(--gb-surface, #1c1b1b);
}

.plan-grid-vacio__icono-caja {
  display: grid;
  place-items: center;
  width: 5rem;
  height: 5rem;
  border-radius: 50%;
  background-color: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  margin-bottom: 1.25rem;
}

.plan-grid-vacio__icono {
  color: var(--gb-text-muted, #c6c6c6);
}

.plan-grid-vacio__titulo {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--gb-text, #e5e2e1);
  margin: 0 0 0.5rem;
}

.plan-grid-vacio__texto {
  font-size: 0.875rem;
  color: var(--gb-text-muted, #c6c6c6);
  max-width: 28rem;
  margin: 0;
}

/* Paginación */
.plan-grid__paginacion {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.85rem 1.25rem;
  border-radius: var(--gb-radius-lg, 0.5rem);
  border: 1px solid var(--gb-border, #333333);
  background-color: var(--gb-surface, #1c1b1b);
}

.plan-grid__conteo {
  margin: 0;
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-muted, #c6c6c6);
}

.plan-grid__controles {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.plan-grid__pagina-actual {
  font-size: var(--gb-tipo-xs, 0.75rem);
  color: var(--gb-text-soft, #e9bcb6);
}

/* Skeletons */
.plan-card-skeleton {
  padding: 1.5rem;
  border-radius: var(--gb-radius-xl, 1rem);
  border: 1px solid rgba(255, 255, 255, 0.06);
  background: var(--gb-surface, #1c1b1b);
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  min-height: 28rem;
}

.skeleton-header {
  display: flex;
  align-items: center;
  gap: 0.85rem;
}

.skeleton-icon {
  width: 3rem;
  height: 3rem;
  border-radius: var(--gb-radius-lg, 0.5rem);
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-titles {
  flex: 1;
  display: grid;
  gap: 0.4rem;
}

.skeleton-line {
  height: 0.85rem;
  border-radius: var(--gb-radius-sm, 0.25rem);
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-line--title {
  width: 60%;
  height: 1.2rem;
}

.skeleton-line--subtitle {
  width: 85%;
}

.skeleton-price-block {
  height: 4.5rem;
  border-radius: var(--gb-radius-lg, 0.5rem);
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-chips {
  display: flex;
  gap: 0.5rem;
}

.skeleton-chip {
  width: 7rem;
  height: 1.8rem;
  border-radius: var(--gb-radius-pill, 9999px);
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

.skeleton-services {
  display: grid;
  gap: 0.6rem;
  flex: 1;
}

.skeleton-footer {
  height: 2.8rem;
  border-radius: var(--gb-radius-pill, 9999px);
  background: linear-gradient(
    90deg,
    rgba(255, 255, 255, 0.05) 25%,
    rgba(255, 255, 255, 0.1) 50%,
    rgba(255, 255, 255, 0.05) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

@media (max-width: 48rem) {
  .plan-grid {
    grid-template-columns: 1fr;
  }
}
</style>
