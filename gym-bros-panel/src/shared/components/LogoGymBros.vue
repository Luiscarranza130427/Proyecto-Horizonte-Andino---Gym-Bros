<script setup>
import { RouterLink } from 'vue-router'

import LogoSvg from '@/assets/images/brand/gym-bros-lockup.svg'

defineProps({
  ruta: { type: [String, Object], default: () => ({ name: 'dashboard' }) },
  compacto: { type: Boolean, default: false },
})
</script>

<template>
  <RouterLink :to="ruta" class="gb-logo" :class="{ 'gb-logo--compacto': compacto }">
    <img :src="LogoSvg" alt="Gym Bros" class="gb-logo__imagen" />
  </RouterLink>
</template>

<style scoped>
.gb-logo {
  display: inline-flex;
  align-items: center;
  text-decoration: none;
}

.gb-logo__imagen {
  height: 2rem;
  width: auto;
  object-fit: contain;
}

.gb-logo--compacto .gb-logo__imagen {
  height: 1.75rem;
}
</style>
