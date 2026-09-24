<script setup>
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = defineProps({
  banners: { type: Array, default: () => [] },
})

const indiceActivo = ref(0)
let temporizador = null

const slides = computed(() => props.banners.filter((banner) => banner?.imagenUrl))
const bannerActivo = computed(() => slides.value[indiceActivo.value] ?? null)

const estiloFondo = computed(() =>
  bannerActivo.value?.imagenUrl
    ? {
        backgroundImage: `linear-gradient(90deg, rgba(8, 8, 8, 0.9) 0%, rgba(8, 8, 8, 0.62) 65%, rgba(8, 8, 8, 0.12) 100%), url(${JSON.stringify(bannerActivo.value.imagenUrl)})`,
      }
    : {},
)

function irASlide(indice) {
  indiceActivo.value = indice
  reiniciarReproduccion()
}

function siguiente() {
  indiceActivo.value = (indiceActivo.value + 1) % slides.value.length
}

function iniciarReproduccion() {
  if (slides.value.length <= 1 || temporizador) return
  temporizador = window.setInterval(siguiente, 6000)
}

function detenerReproduccion() {
  if (!temporizador) return
  window.clearInterval(temporizador)
  temporizador = null
}

function reiniciarReproduccion() {
  detenerReproduccion()
  iniciarReproduccion()
}

watch(slides, (nuevosSlides) => {
  if (indiceActivo.value >= nuevosSlides.length) indiceActivo.value = 0
  reiniciarReproduccion()
})

onMounted(iniciarReproduccion)
onBeforeUnmount(detenerReproduccion)
</script>

<template>
  <article class="banner gb-tarjeta" :style="estiloFondo" aria-roledescription="carrusel">
    <div class="banner__contenido">
      <p v-if="bannerActivo?.contenido" class="banner__texto">{{ bannerActivo.contenido }}</p>
      <a
        v-if="bannerActivo?.textoBoton && bannerActivo?.enlaceBoton"
        class="btn btn-primary banner__accion"
        :href="bannerActivo.enlaceBoton"
      >
        {{ bannerActivo.textoBoton }}
      </a>
    </div>
    <template v-if="slides.length > 1">
      <div class="banner__indicadores" aria-label="Seleccionar banner">
        <button
          v-for="(slide, indice) in slides"
          :key="slide.id ?? indice"
          type="button"
          class="banner__indicador"
          :class="{ 'banner__indicador--activo': indice === indiceActivo }"
          :aria-label="`Mostrar banner ${indice + 1}`"
          :aria-current="indice === indiceActivo ? 'true' : null"
          @click="irASlide(indice)"
        />
      </div>
    </template>
  </article>
</template>

<style scoped>
.banner {
  position: relative;
  display: flex;
  align-items: center;
  height: 320px;
  padding: 35px;
  overflow: hidden;
  background-color: var(--gb-surface-lowest);
  background-position: center;
  background-size: cover;
  border-radius: var(--gb-radius-xl);
}

.banner__contenido {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  width: 75%;
  margin-top: auto;
}

.banner__texto {
  margin: 0 0 1.5rem;
  color: var(--gb-text);
  font-size: clamp(calc(1.5rem - 7px), calc(3vw - 7px), calc(2.75rem - 7px));
  font-weight: 800;
  line-height: 1.15;
  white-space: pre-line;
}

.banner__accion {
  display: inline-flex;
  align-items: center;
  min-height: 2.75rem;
  padding: 0.625rem 1.375rem;
  text-decoration: none;
}

.banner__indicadores {
  position: absolute;
  z-index: 2;
  bottom: 1rem;
  left: 50%;
  display: flex;
  gap: 0.5rem;
  transform: translateX(-50%);
}

.banner__indicador {
  width: 0.625rem;
  height: 0.625rem;
  padding: 0;
  background: rgba(255, 255, 255, 0.5);
  border: 0;
  border-radius: 50%;
  cursor: pointer;
}

.banner__indicador--activo {
  background: var(--gb-red);
}

@media (max-width: 48rem) {
  .banner {
    height: 320px;
  }

  .banner__contenido {
    width: 85%;
  }
}
</style>
