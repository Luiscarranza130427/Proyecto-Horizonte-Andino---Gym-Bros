<script setup>
import { Building2, Layers, RotateCcw, Search } from 'lucide-vue-next'
import { EMPRESAS_PAGOS, PLANES_PAGOS } from '@/modules/billing/catalogos'

defineProps({
  busqueda: {
    type: String,
    default: '',
  },
  empresaId: {
    type: String,
    default: '',
  },
  planId: {
    type: String,
    default: '',
  },
  cargando: {
    type: Boolean,
    default: false,
  },
  hayFiltrosActivos: {
    type: Boolean,
    default: false,
  },
})

const emit = defineEmits(['update:busqueda', 'update:empresaId', 'update:planId', 'limpiar'])
</script>

<template>
  <div class="pagos-filtros gb-tarjeta" role="search" aria-label="Filtros de pagos">
    <div class="pagos-filtros__busqueda">
      <Search :size="18" class="pagos-filtros__icono-busqueda" aria-hidden="true" />
      <input
        :value="busqueda"
        type="search"
        class="form-control pagos-filtros__input"
        placeholder="Buscar por empresa, plan o #PAG-0001..."
        aria-label="Buscar pagos"
        :disabled="cargando"
        @input="emit('update:busqueda', $event.target.value)"
      />
    </div>

    <div class="pagos-filtros__selectores">
      <div class="pagos-filtros__campo">
        <label for="filtro-empresa" class="visually-hidden">Filtrar por empresa</label>
        <Building2 :size="16" class="pagos-filtros__campo-icono" aria-hidden="true" />
        <select
          id="filtro-empresa"
          :value="empresaId"
          class="form-select pagos-filtros__select"
          :disabled="cargando"
          @change="emit('update:empresaId', $event.target.value)"
        >
          <option value="">Todas las empresas</option>
          <option v-for="emp in EMPRESAS_PAGOS" :key="emp.id" :value="String(emp.id)">
            {{ emp.nombre }}
          </option>
        </select>
      </div>

      <div class="pagos-filtros__campo">
        <label for="filtro-plan" class="visually-hidden">Filtrar por plan</label>
        <Layers :size="16" class="pagos-filtros__campo-icono" aria-hidden="true" />
        <select
          id="filtro-plan"
          :value="planId"
          class="form-select pagos-filtros__select"
          :disabled="cargando"
          @change="emit('update:planId', $event.target.value)"
        >
          <option value="">Todos los planes</option>
          <option v-for="pl in PLANES_PAGOS" :key="pl.id" :value="String(pl.id)">
            {{ pl.nombre }}
          </option>
        </select>
      </div>

      <button
        v-if="hayFiltrosActivos"
        type="button"
        class="btn btn-ghost pagos-filtros__limpiar"
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
.pagos-filtros {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 1rem 1.25rem;
  border-radius: var(--gb-radius-lg);
  border: 1px solid var(--gb-border);
  background-color: var(--gb-surface);
}

.pagos-filtros__busqueda {
  position: relative;
  flex: 1 1 18rem;
  min-width: 15rem;
}

.pagos-filtros__icono-busqueda {
  position: absolute;
  left: 0.85rem;
  top: 50%;
  transform: translateY(-50%);
  color: var(--gb-text-muted);
  pointer-events: none;
}

.pagos-filtros__input {
  width: 100%;
  padding-left: 2.5rem;
}

.pagos-filtros__selectores {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.75rem;
}

.pagos-filtros__campo {
  position: relative;
  display: flex;
  align-items: center;
}

.pagos-filtros__campo-icono {
  position: absolute;
  left: 0.75rem;
  color: var(--gb-text-muted);
  pointer-events: none;
}

.pagos-filtros__select {
  padding-left: 2.25rem;
  min-width: 11rem;
}

.pagos-filtros__limpiar {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: var(--gb-tipo-xs, 0.75rem);
  padding: 0.45rem 0.75rem;
}

@media (max-width: 48rem) {
  .pagos-filtros {
    flex-direction: column;
    align-items: stretch;
  }

  .pagos-filtros__busqueda {
    width: 100%;
  }

  .pagos-filtros__selectores {
    width: 100%;
    flex-direction: column;
    align-items: stretch;
  }

  .pagos-filtros__campo {
    width: 100%;
  }

  .pagos-filtros__select {
    width: 100%;
    min-width: auto;
  }
}
</style>
