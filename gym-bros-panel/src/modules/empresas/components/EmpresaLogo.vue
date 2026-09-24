<script setup>
import { computed, ref, watch } from 'vue'

import { inicialesDe } from '@/shared/utils/iniciales'

const props = defineProps({
  nombre: { type: String, required: true },
  url: { type: String, default: '' },
  grande: { type: Boolean, default: false },
})

const imagenFallida = ref(false)
const mostrarImagen = computed(() => Boolean(props.url) && !imagenFallida.value)

watch(
  () => props.url,
  () => {
    imagenFallida.value = false
  },
)
</script>

<template>
  <span class="logo" :class="{ 'logo--grande': grande }">
    <img
      v-if="mostrarImagen"
      :src="url"
      :alt="`Logo de ${nombre}`"
      :width="grande ? 80 : 36"
      :height="grande ? 80 : 36"
      @error="imagenFallida = true"
    />
    <span v-else aria-hidden="true">{{ inicialesDe(nombre) }}</span>
  </span>
</template>

<style scoped>
.logo {
  flex: none;
  display: grid;
  place-items: center;
  width: 2.25rem;
  height: 2.25rem;
  overflow: hidden;
  background-color: var(--gb-surface-lowest);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  color: var(--gb-red-text);
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-xs);
  font-weight: 800;
}

.logo--grande {
  width: 5rem;
  height: 5rem;
  font-size: var(--gb-tipo-lg);
}

.logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
