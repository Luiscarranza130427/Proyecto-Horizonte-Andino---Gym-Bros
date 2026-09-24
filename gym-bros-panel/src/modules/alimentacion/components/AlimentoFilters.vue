<script setup>
import { Search, XCircle } from 'lucide-vue-next'
import { computed } from 'vue'

import { TIPOS_ALIMENTO } from '@/modules/alimentacion/catalogos'

const props = defineProps({
  busqueda: { type: String, default: '' },
  tipo: { type: String, default: 'all' },
  cargando: { type: Boolean, default: false },
})

defineEmits(['update:busqueda', 'update:tipo', 'limpiar'])

const filtrosActivos = computed(() => props.busqueda.trim() || props.tipo !== 'all')
</script>

<template>
  <section class="filtros gb-tarjeta" aria-label="Filtros del catálogo" :aria-busy="cargando">
    <div class="filtros__busqueda">
      <label class="visually-hidden" for="buscar-alimento">Buscar alimento</label>
      <Search class="filtros__icono" :size="16" aria-hidden="true" />
      <input
        id="buscar-alimento"
        :value="busqueda"
        class="form-control"
        type="search"
        name="buscarAlimento"
        placeholder="Buscar por nombre…"
        autocomplete="off"
        @input="$emit('update:busqueda', $event.target.value)"
      />
    </div>

    <div class="filtros__campo">
      <label for="filtro-tipo">Tipo</label>
      <select
        id="filtro-tipo"
        :value="tipo"
        class="form-select"
        @change="$emit('update:tipo', $event.target.value)"
      >
        <option value="all">Todos</option>
        <option v-for="opcion in TIPOS_ALIMENTO" :key="opcion.valor" :value="opcion.valor">
          {{ opcion.etiqueta }}
        </option>
      </select>
    </div>

    <button
      v-if="filtrosActivos"
      type="button"
      class="btn btn-ghost filtros__limpiar"
      @click="$emit('limpiar')"
    >
      <XCircle :size="16" aria-hidden="true" />
      Limpiar filtros
    </button>
  </section>
</template>

<style scoped>
.filtros {
  display: grid;
  grid-template-columns: minmax(17rem, 2fr) minmax(9rem, 1fr) auto;
  align-items: end;
  gap: 0.75rem;
  padding: 0.875rem;
  border-radius: var(--gb-radius-lg);
}

.filtros__busqueda {
  position: relative;
}

.filtros__busqueda :deep(svg),
.filtros__icono {
  position: absolute;
  top: 50%;
  left: 0.875rem;
  z-index: 1;
  color: var(--gb-text-muted);
  transform: translateY(-50%);
  pointer-events: none;
}

.filtros__busqueda .form-control {
  min-height: 2.75rem;
  padding-left: 2.5rem;
  background-color: var(--gb-surface-lowest);
}

.filtros__campo label {
  display: block;
  margin: 0 0 0.375rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.filtros__campo .form-select {
  min-height: 2.75rem;
  background-color: var(--gb-surface-lowest);
  font-size: var(--gb-tipo-sm);
}

.filtros__limpiar {
  display: inline-flex;
  align-items: center;
  gap: 0.375rem;
  min-height: 2.75rem;
  padding-inline: 0.75rem;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  white-space: nowrap;
}

@media (max-width: 60rem) {
  .filtros {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .filtros__busqueda {
    grid-column: 1 / -1;
  }

  .filtros__limpiar {
    justify-self: start;
  }
}

@media (max-width: 36rem) {
  .filtros {
    grid-template-columns: 1fr;
  }

  .filtros__busqueda {
    grid-column: auto;
  }
}
</style>
