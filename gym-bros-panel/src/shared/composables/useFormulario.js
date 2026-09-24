import { nextTick, reactive, ref, watch } from 'vue'

/**
 * Composable para formularios administrativos con gestión de errores locales y del servidor.
 *
 * @param {object} opciones
 * @param {object} opciones.modeloVacio Campos del formulario y sus valores por defecto.
 * @param {() => object} opciones.valoresIniciales Getter de la prop homónima.
 * @param {() => object} opciones.erroresServidor Getter de la prop homónima.
 * @param {Record<string, import('vue').Ref>} [opciones.referencias] Campo -> ref de plantilla.
 * @param {(formulario: object, errores: object) => void} opciones.validar Escribe en errores los fallos locales.
 * @param {(formulario: object, valores: object) => void} [opciones.alCargarValores] Callback tras cargar valores.
 */
export function useFormulario({
  modeloVacio,
  valoresIniciales,
  erroresServidor,
  referencias = {},
  validar,
  alCargarValores,
}) {
  const formulario = reactive({ ...modeloVacio })
  const erroresLocales = reactive({})
  const erroresRemotos = ref({})

  function olvidarErroresLocales() {
    Object.keys(erroresLocales).forEach((campo) => delete erroresLocales[campo])
  }

  function cargarValores(valores = {}) {
    Object.keys(modeloVacio).forEach((campo) => {
      formulario[campo] = valores[campo] ?? modeloVacio[campo]
    })
    olvidarErroresLocales()
    erroresRemotos.value = {}
    alCargarValores?.(formulario, valores)
  }

  if (typeof valoresIniciales === 'function') {
    watch(valoresIniciales, cargarValores, { immediate: true, deep: true })
  }
  if (typeof erroresServidor === 'function') {
    watch(
      erroresServidor,
      (errores) => {
        erroresRemotos.value = { ...errores }
      },
      { immediate: true, deep: true },
    )
  }

  function primerMensaje(valor) {
    return Array.isArray(valor) ? valor[0] : valor
  }

  function errorDe(campo) {
    return erroresLocales[campo] || primerMensaje(erroresRemotos.value[campo]) || ''
  }

  function limpiarError(campo) {
    delete erroresLocales[campo]
    if (!erroresRemotos.value[campo]) return
    const copia = { ...erroresRemotos.value }
    delete copia[campo]
    erroresRemotos.value = copia
  }

  async function enfocarPrimerError() {
    await nextTick()
    referencias[Object.keys(erroresLocales)[0]]?.value?.focus()
  }

  async function validarParaEnviar() {
    olvidarErroresLocales()
    validar(formulario, erroresLocales)

    if (Object.keys(erroresLocales).length > 0) {
      await enfocarPrimerError()
      return false
    }
    return true
  }

  return {
    formulario,
    erroresLocales,
    erroresRemotos,
    errorDe,
    limpiarError,
    validarParaEnviar,
  }
}
