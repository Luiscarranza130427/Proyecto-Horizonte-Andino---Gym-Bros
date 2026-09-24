<script setup>
import { RouterView } from 'vue-router'
</script>

<template>
  <!-- El armazón visual lo aporta el layout de cada ruta (AuthLayout o
       DashboardLayout), por eso aquí sólo queda el punto de montaje. -->
  <RouterView />
</template>
