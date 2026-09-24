<script setup>
import { Search } from 'lucide-vue-next'

defineProps({
  busqueda: { type: String, default: '' },
  estado: { type: String, default: 'all' },
  cargando: { type: Boolean, default: false },
})

defineEmits(['update:busqueda', 'update:estado'])
</script>

<template>
  <section class="filtros gb-tarjeta" aria-label="Filtros de empresas" :aria-busy="cargando">
    <div class="filtros__busqueda">
      <label class="visually-hidden" for="buscar-empresa">Buscar empresa</label>
      <Search class="filtros__icono" :size="16" aria-hidden="true" />
      <input
        id="buscar-empresa"
        :value="busqueda"
        class="form-control"
        type="search"
        name="buscarEmpresa"
        placeholder="Buscar por empresa, gerente o RUC…"
        autocomplete="off"
        @input="$emit('update:busqueda', $event.target.value)"
      />
    </div>

    <fieldset class="filtros__estados">
      <legend class="visually-hidden">Filtrar por estado de suscripción</legend>
      <label v-for="opcion in ['all', 'Activo', 'Inactivo', 'Por Vencer']" :key="opcion">
        <input
          class="visually-hidden"
          type="radio"
          name="estado-empresa"
          :value="opcion"
          :checked="estado === opcion"
          @change="$emit('update:estado', opcion)"
        />
        <span>{{ opcion === 'all' ? 'Todas' : opcion }}</span>
      </label>
    </fieldset>
  </section>
</template>

<style scoped>
.filtros {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.75rem;
  border-radius: var(--gb-radius-lg);
}

.filtros__busqueda {
  position: relative;
  flex: 1 1 24rem;
  max-width: 36rem;
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
  font-size: calc(1rem - 2px);
  min-height: 2.75rem;
  padding-left: 2.5rem;
  background-color: var(--gb-surface-lowest);
}

.filtros__estados {
  flex: none;
  display: flex;
  gap: 0.25rem;
  margin: 0;
  padding: 0.25rem;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
}

.filtros__estados label {
  cursor: pointer;
}

.filtros__estados span {
  display: block;
  padding: 0.5rem 0.875rem;
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.filtros__estados input:checked + span {
  background-color: var(--gb-surface-high);
  box-shadow: var(--gb-relieve);
  color: var(--gb-text);
}

.filtros__estados input:focus-visible + span {
  outline: 2px solid var(--gb-focus);
  outline-offset: 2px;
}

@media (max-width: 60rem) {
  .filtros {
    align-items: stretch;
    flex-direction: column;
  }

  .filtros__busqueda {
    flex-basis: auto;
    max-width: none;
  }

  .filtros__estados {
    align-self: flex-start;
  }
}
</style>
