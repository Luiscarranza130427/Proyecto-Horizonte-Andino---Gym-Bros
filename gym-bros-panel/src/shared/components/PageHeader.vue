<script setup>
import { RouterLink } from 'vue-router'

defineProps({
  titulo: { type: String, required: true },
  descripcion: { type: String, default: '' },
  seccion: { type: String, default: '' },
  rutaSeccion: { type: [String, Object], default: null },
  etiqueta: { type: String, default: '' },
  migas: { type: Array, default: () => [] },
})
</script>

<template>
  <header class="gb-page-header">
    <div class="gb-page-header__contexto">
      <nav v-if="seccion || migas.length" class="gb-page-header__migas" aria-label="Migas de pan">
        <ol>
          <li>
            <RouterLink v-if="rutaSeccion" :to="rutaSeccion">{{ seccion }}</RouterLink>
            <span v-else>{{ seccion }}</span>
          </li>
          <li v-for="(miga, indice) in migas" :key="indice">
            <span aria-hidden="true">/</span>
            <span>{{ miga }}</span>
          </li>
        </ol>
      </nav>

      <p v-if="etiqueta" class="gb-page-header__etiqueta">
        <span aria-hidden="true"></span>
        {{ etiqueta }}
      </p>

      <h1 class="gb-page-header__titulo">{{ titulo }}</h1>
      <p v-if="descripcion" class="gb-page-header__descripcion">{{ descripcion }}</p>
    </div>

    <div v-if="$slots.acciones" class="gb-page-header__acciones">
      <slot name="acciones" />
    </div>
  </header>
</template>

<style scoped>
.gb-page-header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-end;
  justify-content: space-between;
  gap: 1.5rem;
  padding-bottom: 0.5rem;
}

.gb-page-header__contexto {
  display: grid;
  gap: 0.25rem;
}

.gb-page-header__migas ol {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0 0 0.5rem;
  padding: 0;
  list-style: none;
  font-size: var(--gb-tipo-xs);
  color: var(--gb-text-muted);
}

.gb-page-header__migas a {
  color: var(--gb-text-muted);
  text-decoration: none;
}

.gb-page-header__migas a:hover {
  color: var(--gb-red-text);
}

.gb-page-header__etiqueta {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  margin: 0;
  color: var(--gb-red-text);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.1em;
  text-transform: uppercase;
}

.gb-page-header__etiqueta span {
  width: 0.5rem;
  height: 0.5rem;
  background-color: var(--gb-green);
  border-radius: var(--gb-radius-pill);
}

.gb-page-header__titulo {
  margin: 0;
  font-size: var(--gb-tipo-xl);
  font-weight: 900;
  line-height: 1.1;
  text-transform: uppercase;
}

.gb-page-header__descripcion {
  margin: 0.25rem 0 0;
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-sm);
}

.gb-page-header__acciones {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

@media (max-width: 48rem) {
  .gb-page-header {
    flex-direction: column;
    align-items: stretch;
    gap: 1rem;
  }

  .gb-page-header__acciones {
    width: 100%;
    flex-wrap: wrap;
    justify-content: flex-start;
  }

  .gb-page-header__acciones :deep(.btn) {
    flex: 1 1 auto;
    justify-content: center;
  }

  .gb-page-header__titulo {
    font-size: 1.5rem;
  }
}

@media (max-width: 32rem) {
  .gb-page-header__migas ol {
    flex-wrap: wrap;
  }

  .gb-page-header__acciones {
    flex-direction: column;
  }

  .gb-page-header__acciones :deep(.btn) {
    width: 100%;
  }
}
</style>
