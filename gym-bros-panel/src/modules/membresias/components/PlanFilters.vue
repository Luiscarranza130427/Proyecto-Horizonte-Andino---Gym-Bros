<script setup>
import { LayoutGrid, List, RotateCcw, Search, ShieldCheck } from 'lucide-vue-next'

defineProps({
  busqueda: {
    type: String,
    default: '',
  },
  estado: {
    type: String,
    default: 'all',
  },
  vista: {
    type: String,
    default: 'cards',
  },
  cargando: {
    type: Boolean,
    default: false,
  },
  hayFiltrosActivos: {
    type: Boolean,
    default: false,
  },
  permitirSelectorVista: {
    type: Boolean,
    default: true,
  },
})

const emit = defineEmits(['update:busqueda', 'update:estado', 'update:vista', 'limpiar'])
</script>

<template>
  <div class="planes-filtros gb-tarjeta" role="search" aria-label="Filtros de planes">
    <div class="planes-filtros__busqueda">
      <Search :size="18" class="planes-filtros__icono-busqueda" aria-hidden="true" />
      <input
        :value="busqueda"
        type="search"
        class="form-control planes-filtros__input"
        placeholder="Buscar por nombre, descripción o servicios..."
        aria-label="Buscar planes"
        :disabled="cargando"
        @input="emit('update:busqueda', $event.target.value)"
      />
    </div>

    <div class="planes-filtros__selectores">
      <div class="planes-filtros__campo">
        <label for="filtro-estado-plan" class="visually-hidden">Filtrar por estado</label>
        <ShieldCheck :size="16" class="planes-filtros__campo-icono" aria-hidden="true" />
        <select
          id="filtro-estado-plan"
          :value="estado"
          class="form-select planes-filtros__select"
          :disabled="cargando"
          @change="emit('update:estado', $event.target.value)"
        >
          <option value="all">Todos los estados</option>
          <option value="active">Disponibles (Activos)</option>
          <option value="inactive">Inactivos (Ocultos)</option>
        </select>
      </div>

      <!-- Selector de Vista (Tarjetas / Tabla) -->
      <div
        v-if="permitirSelectorVista"
        class="planes-filtros__vista-toggle"
        role="group"
        aria-label="Modo de visualización"
      >
        <button
          type="button"
          class="vista-btn"
          :class="{ 'vista-btn--activo': vista === 'cards' }"
          title="Vista en tarjetas"
          aria-label="Ver en tarjetas"
          @click="emit('update:vista', 'cards')"
        >
          <LayoutGrid :size="16" aria-hidden="true" />
          <span>Tarjetas</span>
        </button>
        <button
          type="button"
          class="vista-btn"
          :class="{ 'vista-btn--activo': vista === 'table' }"
          title="Vista en tabla"
          aria-label="Ver en tabla"
          @click="emit('update:vista', 'table')"
        >
          <List :size="16" aria-hidden="true" />
          <span>Tabla</span>
        </button>
      </div>

      <button
        v-if="hayFiltrosActivos"
        type="button"
        class="btn btn-secondary planes-filtros__limpiar"
        :disabled="cargando"
        @click="emit('limpiar')"
      >
        <RotateCcw :size="14" aria-hidden="true" />
        <span>Limpiar</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.planes-filtros {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem 1.25rem;
  border-radius: var(--gb-radius-xl, 1rem);
  border: 1px solid var(--gb-border, #333333);
  background-color: var(--gb-surface, #1c1b1b);
}

.planes-filtros__busqueda {
  position: relative;
  flex: 1 1 18rem;
  min-width: 15rem;
}

.planes-filtros__icono-busqueda {
  position: absolute;
  left: 0.85rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--gb-text-muted, #c6c6c6);
  pointer-events: none;
}

.planes-filtros__input {
  width: 100%;
  padding-left: 2.5rem;
}

.planes-filtros__selectores {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
}

.planes-filtros__campo {
  position: relative;
  display: flex;
  align-items: center;
}

.planes-filtros__campo-icono {
  position: absolute;
  left: 0.75rem;
  color: var(--gb-text-muted, #c6c6c6);
  pointer-events: none;
}

.planes-filtros__select {
  padding-left: 2.25rem;
  min-width: 12rem;
}

/* Toggle de vista */
.planes-filtros__vista-toggle {
  display: inline-flex;
  align-items: center;
  background-color: var(--gb-surface-highest, #353534);
  border: 1px solid var(--gb-border, #333333);
  border-radius: var(--gb-radius-pill, 9999px);
  padding: 0.2rem;
  gap: 0.2rem;
}

.vista-btn {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  padding: 0.35rem 0.75rem;
  font-size: 0.75rem;
  font-weight: 600;
  border-radius: var(--gb-radius-pill, 9999px);
  border: 0;
  background: transparent;
  color: var(--gb-text-muted, #c6c6c6);
  cursor: pointer;
  transition: all 0.2s ease;
}

.vista-btn:hover {
  color: #ffffff;
}

.vista-btn--activo {
  background: var(--gb-surface, #1c1b1b);
  color: var(--gb-red-text, #ffb4aa);
  box-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
}

.planes-filtros__limpiar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: var(--gb-tipo-xs, 0.75rem);
  padding: 0.45rem 0.75rem;
}

@media (max-width: 48rem) {
  .planes-filtros {
    flex-direction: column;
    align-items: stretch;
  }

  .planes-filtros__busqueda {
    width: 100%;
  }

  .planes-filtros__selectores {
    width: 100%;
    justify-content: space-between;
  }

  .planes-filtros__campo {
    flex: 1;
  }

  .planes-filtros__select {
    width: 100%;
    min-width: auto;
  }
}
</style>
