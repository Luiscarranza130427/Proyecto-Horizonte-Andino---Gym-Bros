<script setup>
import { RouterView } from 'vue-router'

import marcaHorizontalUrl from '@/assets/images/brand/gym-bros-lockup.webp'
import atletaUrl from '@/assets/images/brand/login-athlete.webp'
</script>

<template>
  <div class="acceso">
    <main class="acceso__panel">
      <section class="acceso__formulario" aria-label="Acceso administrativo">
        <div class="acceso__formulario-interior">
          <img class="acceso__marca" :src="marcaHorizontalUrl" alt="Gym Bros" />
          <RouterView />
        </div>
      </section>

      <!--
        Sin el texto que llevaba encima, la imagen es puramente decorativa: no
        aporta nada para iniciar sesión. Deja de ser una región con nombre y su
        `alt` va vacío, o un lector de pantalla anunciaría una zona entera para
        describir una foto de fondo.
      -->
      <div class="acceso__visual">
        <img :src="atletaUrl" alt="" />
      </div>
    </main>
  </div>
</template>

<style scoped>
/* A sangre: sin tarjeta, sin margen y sin bordes redondeados. */
.acceso {
  box-sizing: border-box;
  height: 100vh;
  height: 100dvh;
  overflow: hidden;
  background-color: var(--gb-bg);
}

.acceso__panel {
  display: grid;
  grid-template-columns: minmax(23.5rem, 0.84fr) minmax(0, 1.16fr);
  width: 100%;
  height: 100%;
  min-height: 0;
  overflow: hidden;
  background-color: var(--gb-surface);
}

.acceso__formulario {
  z-index: 1;
  display: grid;
  place-items: center;
  padding: clamp(1.5rem, 4vw, 3.25rem);
  background-color: var(--gb-surface);
}

.acceso__formulario-interior {
  width: min(100%, 25rem);
}

.acceso__marca {
  display: block;
  width: min(100%, 16rem);
  height: auto;
  margin: 0 0 1.5rem;
  object-fit: contain;
}

@media (min-width: 42.01rem) {
  .acceso__marca {
    width: min(100%, calc(16rem + 100px));
  }
}

.acceso__visual {
  position: relative;
  min-height: 0;
  overflow: hidden;
  background-color: var(--gb-surface-lowest);
  border-left: 1px solid var(--gb-border);
}

.acceso__visual > img {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: 54% center;
}

@media (max-height: 48rem) and (min-width: 42.01rem) {
  .acceso__formulario {
    padding-block: 1.25rem;
  }

  .acceso__marca {
    width: min(100%, calc(14rem + 100px));
    margin-bottom: 1rem;
  }
}

@media (max-width: 56rem) {
  .acceso__panel {
    grid-template-columns: minmax(22rem, 1fr) minmax(18rem, 0.75fr);
  }
}

@media (max-width: 42rem) {
  .acceso {
    height: auto;
    min-height: 100vh;
    min-height: 100dvh;
    overflow: auto;
  }

  .acceso__panel {
    grid-template-columns: 1fr;
    height: auto;
    min-height: 100vh;
    min-height: 100dvh;
  }

  .acceso__formulario {
    min-height: 100vh;
    min-height: 100dvh;
    padding: 1.5rem;
  }

  .acceso__visual {
    display: none;
  }
}
</style>
