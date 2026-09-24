<script setup>
import { Bell } from 'lucide-vue-next'
import { onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'

import { contarNoLeidas } from '@/modules/notificaciones/services/notificaciones.service'

const sinLeer = ref(0)

onMounted(async () => {
  try {
    sinLeer.value = await contarNoLeidas()
  } catch {
    // Si el contador falla, la campana se muestra sin distintivo
  }
})
</script>

<template>
  <RouterLink class="campana" :to="{ name: 'notificaciones' }">
    <Bell :size="18" aria-hidden="true" />
    <span v-if="sinLeer > 0" class="campana__punto" aria-hidden="true"></span>
    <span class="visually-hidden">
      Notificaciones{{ sinLeer > 0 ? `: ${sinLeer} sin leer` : '' }}
    </span>
  </RouterLink>
</template>

<style scoped>
.campana {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 2.5rem;
  height: 2.5rem;
  border: 1px solid transparent;
  border-radius: var(--gb-radius-lg);
  color: var(--gb-text-soft);
  font-size: 1.125rem;
  line-height: 1;
  text-decoration: none;
  transition: background-color 0.2s ease;
}

.campana:hover {
  background-color: var(--gb-surface-high);
  border-color: var(--gb-border);
  color: var(--gb-text);
}

.campana__punto {
  position: absolute;
  top: 0.375rem;
  right: 0.5rem;
  width: 0.5rem;
  height: 0.5rem;
  background-color: var(--gb-red);
  border: 2px solid var(--gb-bg);
  border-radius: var(--gb-radius-pill);
}
</style>
