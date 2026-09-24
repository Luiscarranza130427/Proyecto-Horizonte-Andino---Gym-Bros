<script setup>
import { Dumbbell } from 'lucide-vue-next'

defineProps({
  size: { type: Number, default: 24 },
})
</script>

<template>
  <Dumbbell :size="size" class="gb-icono-mancuerna" aria-hidden="true" />
</template>

<style scoped>
.gb-icono-mancuerna {
  color: var(--gb-red-text);
}
</style>
