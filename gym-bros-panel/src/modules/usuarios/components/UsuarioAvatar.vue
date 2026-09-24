<script setup>
import { computed, ref, watch } from 'vue'

import { inicialesDe } from '@/shared/utils/iniciales'

const props = defineProps({
  nombre: { type: String, required: true },
  apellido: { type: String, default: '' },
  url: { type: String, default: '' },
  grande: { type: Boolean, default: false },
})

const imagenFallida = ref(false)
const nombreCompleto = computed(() => [props.nombre, props.apellido].filter(Boolean).join(' '))
const mostrarImagen = computed(() => Boolean(props.url) && !imagenFallida.value)

watch(
  () => props.url,
  () => {
    imagenFallida.value = false
  },
)
</script>

<template>
  <span class="avatar" :class="{ 'avatar--grande': grande }">
    <img
      v-if="mostrarImagen"
      :src="url"
      :alt="`Foto de perfil de ${nombreCompleto}`"
      :width="grande ? 88 : 40"
      :height="grande ? 88 : 40"
      @error="imagenFallida = true"
    />
    <span v-else aria-hidden="true">{{ inicialesDe(nombreCompleto) }}</span>
  </span>
</template>

<style scoped>
.avatar {
  flex: none;
  display: grid;
  place-items: center;
  width: 2.5rem;
  height: 2.5rem;
  overflow: hidden;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius-pill);
  box-shadow: var(--gb-relieve);
  color: var(--gb-red-text);
  font-family: var(--gb-fuente-titulo);
  font-size: var(--gb-tipo-xs);
  font-weight: 800;
}

.avatar--grande {
  width: 5.5rem;
  height: 5.5rem;
  font-size: var(--gb-tipo-lg);
}

.avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
</style>
