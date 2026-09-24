<script setup>
import { computed } from 'vue'
import { RouterLink } from 'vue-router'

import { useAuthStore } from '@/core/auth/auth.store'

const auth = useAuthStore()

// Se devuelve al usuario a un sitio al que realmente puede entrar.
const destino = computed(() =>
  auth.estaAutenticado
    ? { nombre: { name: 'dashboard' }, etiqueta: 'Volver al panel' }
    : { nombre: { name: 'login' }, etiqueta: 'Ir a iniciar sesión' },
)
</script>

<template>
  <main class="gb-centrado-pantalla">
    <div class="no-encontrado__panel">
      <p class="no-encontrado__codigo">404</p>
      <h1 class="no-encontrado__titulo">Página no encontrada</h1>
      <p class="no-encontrado__texto">
        La dirección que has abierto no existe o el contenido se ha movido.
      </p>

      <RouterLink class="btn btn-primary" :to="destino.nombre">
        {{ destino.etiqueta }}
      </RouterLink>
    </div>
  </main>
</template>

<style scoped>
.no-encontrado__panel {
  max-width: 28rem;
  text-align: center;
}

.no-encontrado__codigo {
  margin: 0;
  color: var(--gb-red-text);
  font-size: 3.5rem;
  font-weight: 800;
  line-height: 1;
}

.no-encontrado__titulo {
  margin: 0.5rem 0 0.25rem;
  font-size: 1.5rem;
  text-transform: uppercase;
}

.no-encontrado__texto {
  margin: 0 0 var(--gb-espacio-lg);
  color: var(--gb-text-muted);
}
</style>
