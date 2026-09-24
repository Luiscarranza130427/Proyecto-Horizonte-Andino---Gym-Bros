import { ref } from 'vue'
import { defineStore } from 'pinia'

export const useUiStore = defineStore('ui', () => {
  const sidebarCompacto = ref(false)

  function alternarSidebar() {
    sidebarCompacto.value = !sidebarCompacto.value
  }

  return {
    sidebarCompacto,
    alternarSidebar,
  }
})
