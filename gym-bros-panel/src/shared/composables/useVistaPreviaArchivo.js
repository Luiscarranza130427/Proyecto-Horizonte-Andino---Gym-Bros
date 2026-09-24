import { onBeforeUnmount, ref } from 'vue'

const TAMANO_MAXIMO = 2 * 1024 * 1024

export function useVistaPreviaArchivo({
  maximoBytes = TAMANO_MAXIMO,
  etiqueta = 'archivo',
  procesarImagen = null,
} = {}) {
  const url = ref('')
  const error = ref('')
  const procesando = ref(false)

  let urlTemporal = ''

  function liberar() {
    if (!urlTemporal) return
    URL.revokeObjectURL(urlTemporal)
    urlTemporal = ''
  }

  function reiniciar(urlInicial = '') {
    liberar()
    error.value = ''
    url.value = urlInicial || ''
  }

  async function seleccionar(evento, urlActual = '') {
    const archivo = evento.target.files?.[0]
    liberar()
    error.value = ''

    if (!archivo) {
      url.value = urlActual || ''
      return
    }

    if (!archivo.type.startsWith('image/')) {
      error.value = 'Selecciona un archivo de imagen.'
      evento.target.value = ''
      return
    }

    if (archivo.size > maximoBytes) {
      const megas = Math.round(maximoBytes / 1024 / 1024)
      error.value = `El ${etiqueta} no puede superar ${megas} MB.`
      evento.target.value = ''
      return
    }

    if (procesarImagen) {
      procesando.value = true
      try {
        url.value = await procesarImagen(archivo)
      } catch (err) {
        error.value = err.message || `No se pudo preparar el ${etiqueta}.`
        evento.target.value = ''
      } finally {
        procesando.value = false
      }
      return
    }

    urlTemporal = URL.createObjectURL(archivo)
    url.value = urlTemporal
  }

  onBeforeUnmount(liberar)

  return { url, error, procesando, seleccionar, reiniciar, liberar }
}
