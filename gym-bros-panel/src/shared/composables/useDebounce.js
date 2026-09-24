import { onBeforeUnmount, ref, watch } from 'vue'

export function useDebounce(valor, retraso = 300) {
  const debounced = ref(valor.value)
  let temporizador = null

  watch(valor, (nuevo) => {
    if (temporizador) clearTimeout(temporizador)
    temporizador = setTimeout(() => {
      debounced.value = nuevo
    }, retraso)
  })

  onBeforeUnmount(() => {
    if (temporizador) clearTimeout(temporizador)
  })

  return debounced
}
