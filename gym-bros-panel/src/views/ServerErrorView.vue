<script setup>
import { ServerCrash } from 'lucide-vue-next'
import { RouterLink } from 'vue-router'
</script>

<template>
  <main class="gb-centrado-pantalla">
    <div class="servidor-error__panel">
      <div class="servidor-error__icono" aria-hidden="true">
        <ServerCrash :size="48" />
      </div>
      <p class="servidor-error__codigo">500</p>
      <h1 class="servidor-error__titulo">Error en el servidor</h1>
      <p class="servidor-error__texto">
        Ocurrió un problema interno inesperado en los servidores de Gym Bros. Por favor, reintenta
        en unos instantes.
      </p>

      <RouterLink class="btn btn-primary" :to="{ name: 'dashboard' }">
        Volver al inicio
      </RouterLink>
    </div>
  </main>
</template>

<style scoped>
.servidor-error__panel {
  max-width: 28rem;
  text-align: center;
}

.servidor-error__icono {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 4rem;
  height: 4rem;
  margin-bottom: 1rem;
  background-color: rgba(var(--gb-amber-rgb, 245, 158, 11), 0.12);
  border: 1px solid rgba(var(--gb-amber-rgb, 245, 158, 11), 0.3);
  border-radius: var(--gb-radius-xl);
  color: var(--gb-amber);
}

.servidor-error__codigo {
  margin: 0;
  color: var(--gb-amber);
  font-size: 3rem;
  font-weight: 800;
  line-height: 1;
}

.servidor-error__titulo {
  margin: 0.5rem 0 0.25rem;
  font-size: 1.5rem;
  text-transform: uppercase;
}

.servidor-error__texto {
  margin: 0 0 var(--gb-espacio-lg);
  color: var(--gb-text-muted);
}
</style>
