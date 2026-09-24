<script setup>
import { Menu } from 'lucide-vue-next'

import NotificationButton from '@/app/layouts/NotificationButton.vue'
import UserMenu from '@/app/layouts/UserMenu.vue'
import { useUiStore } from '@/shared/stores/ui.store'

const ui = useUiStore()
</script>

<template>
  <header class="header">
    <div class="header__izquierda">
      <button
        type="button"
        class="gb-boton-icono header__toggle"
        :aria-pressed="ui.sidebarCompacto"
        aria-controls="menu-lateral"
        @click="ui.alternarSidebar()"
      >
        <Menu :size="18" aria-hidden="true" />
        <span class="visually-hidden">
          {{ ui.sidebarCompacto ? 'Expandir menú lateral' : 'Contraer menú lateral' }}
        </span>
      </button>
    </div>

    <div class="header__acciones">
      <NotificationButton />
      <UserMenu />
    </div>
  </header>
</template>

<style scoped>
.header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--gb-espacio);
  min-width: 0;
  min-height: var(--gb-header-alto);
  padding: 0 var(--gb-gutter);
  background-color: var(--gb-bg);
  border-bottom: 1px solid var(--gb-border);
}

.header__izquierda {
  display: flex;
  align-items: center;
  gap: 1.25rem;
  height: 100%;
  min-width: 0;
  flex: 1;
}

.header__toggle {
  flex: none;
  font-size: 1.125rem;
  line-height: 1;
}

.header__acciones {
  flex: none;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  height: 100%;
}

@media (max-width: 64rem) {
  .header__toggle {
    display: none;
  }
}

@media (max-width: 38rem) {
  .header {
    padding-inline: 1rem;
  }
}
</style>
