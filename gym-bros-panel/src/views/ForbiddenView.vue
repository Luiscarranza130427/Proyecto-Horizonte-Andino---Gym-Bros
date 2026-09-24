<script setup>
import { ShieldAlert } from 'lucide-vue-next'
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { useAuthStore } from '@/core/auth/auth.store'

const auth = useAuthStore()

const destino = computed(() =>
  auth.estaAutenticado
    ? { nombre: { name: 'dashboard' }, etiqueta: 'Volver al panel principal' }
    : { nombre: { name: 'login' }, etiqueta: 'Iniciar sesión' },
)
</script>

<template>
  <main class="gb-centrado-pantalla">
    <div class="prohibido__panel">
      <div class="prohibido__icono" aria-hidden="true">
        <ShieldAlert :size="48" />
      </div>
      <p class="prohibido__codigo">403</p>
      <h1 class="prohibido__titulo">Acceso restringido</h1>
      <p class="prohibido__texto">
        No dispones de los permisos necesarios o tu rol actual no permite acceder a este módulo.
      </p>

      <RouterLink class="btn btn-primary" :to="destino.nombre">
        {{ destino.etiqueta }}
      </RouterLink>
    </div>
  </main>
</template>

<style scoped>
.prohibido__panel {
  max-width: 28rem;
  text-align: center;
}

.prohibido__icono {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 4rem;
  height: 4rem;
  margin-bottom: 1rem;
  background-color: rgba(var(--gb-red-rgb), 0.12);
  border: 1px solid rgba(var(--gb-red-rgb), 0.3);
  border-radius: var(--gb-radius-xl);
  color: var(--gb-red-text);
}

.prohibido__codigo {
  margin: 0;
  color: var(--gb-red-text);
  font-size: 3rem;
  font-weight: 800;
  line-height: 1;
}

.prohibido__titulo {
  margin: 0.5rem 0 0.25rem;
  font-size: 1.5rem;
  text-transform: uppercase;
}

.prohibido__texto {
  margin: 0 0 var(--gb-espacio-lg);
  color: var(--gb-text-muted);
}
</style>
