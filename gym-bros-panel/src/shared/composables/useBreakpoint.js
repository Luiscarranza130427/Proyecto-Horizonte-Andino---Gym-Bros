import { onBeforeUnmount, onMounted, ref } from 'vue'

export function useBreakpoint(query = '(max-width: 52rem)') {
  const coincide = ref(false)
  let mediaQueryList = null

  function actualizar(e) {
    coincide.value = e.matches
  }

  onMounted(() => {
    if (typeof window !== 'undefined' && window.matchMedia) {
      mediaQueryList = window.matchMedia(query)
      coincide.value = mediaQueryList.matches
      mediaQueryList.addEventListener('change', actualizar)
    }
  })

  onBeforeUnmount(() => {
    if (mediaQueryList) {
      mediaQueryList.removeEventListener('change', actualizar)
    }
  })

  return { coincide }
}
