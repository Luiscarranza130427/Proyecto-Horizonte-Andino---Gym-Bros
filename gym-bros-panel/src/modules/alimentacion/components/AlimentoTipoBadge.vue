<script setup>
import { computed } from 'vue'

import { TIPOS_ALIMENTO, etiquetaDe } from '@/modules/alimentacion/catalogos'

/**
 * Tipo de un alimento como distintivo de color.
 *
 * Los diez tipos del catálogo se reparten en cuatro familias para que una
 * rejilla de doce tarjetas se pueda recorrer con la vista sin leer cada
 * etiqueta. Es una ayuda de lectura, no una clasificación nutricional: el dato
 * que manda sigue siendo el texto del distintivo.
 *
 * Un tipo que no esté aquí cae en la familia neutra y conserva su etiqueta, así
 * que ampliar `TIPOS_ALIMENTO` no deja huecos de color.
 */
const FAMILIAS = {
  proteina: 'proteica',
  lacteo: 'proteica',
  carbohidrato: 'energetica',
  cereal: 'energetica',
  legumbre: 'energetica',
  fruta: 'vegetal',
  verdura: 'vegetal',
}

const props = defineProps({
  tipo: { type: String, required: true },
})

const etiqueta = computed(() => etiquetaDe(TIPOS_ALIMENTO, props.tipo))
const familia = computed(() => FAMILIAS[props.tipo] ?? 'neutra')
</script>

<template>
  <span class="tipo" :class="`tipo--${familia}`">{{ etiqueta }}</span>
</template>

<style scoped>
.tipo {
  display: inline-block;
  padding: 0.25rem 0.5rem;
  background-color: var(--gb-surface-high);
  border: 1px solid var(--gb-border);
  border-radius: var(--gb-radius);
  color: var(--gb-text-muted);
  font-size: var(--gb-tipo-xxs);
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  white-space: nowrap;
}

.tipo--proteica {
  color: var(--gb-red-text);
}

.tipo--energetica {
  color: var(--gb-amber);
}

.tipo--vegetal {
  color: var(--gb-green);
}
</style>
