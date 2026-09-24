import { computed, nextTick, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'

const RETARDO_BUSQUEDA = 350

export function useListadoFiltrable({
  nombreRuta,
  cargar,
  filtros: definicion = {},
  mapearParametros = (valores) => valores,
  porPagina = 8,
  mensajeDeError = 'No pudimos cargar el listado.',
  avisos = {},
}) {
  const route = useRoute()
  const router = useRouter()

  const PAGINACION_VACIA = {
    pagina: 1,
    ultimaPagina: 1,
    porPagina,
    total: 0,
    desde: 0,
    hasta: 0,
  }

  const claves = Object.keys(definicion)
  const porDefecto = (clave) => definicion[clave].defecto ?? 'all'

  const estadoVista = ref('idle')
  const items = ref([])
  const paginacion = ref({ ...PAGINACION_VACIA })
  const mensajeError = ref('')
  const mensajeExito = ref('')
  const mensajeExitoRef = ref(null)

  const busqueda = ref(String(route.query.search ?? ''))
  const filtros = reactive(
    Object.fromEntries(claves.map((clave) => [clave, valorValido(clave, route.query[clave])])),
  )

  let temporizadorBusqueda = null
  let solicitudActual = 0

  const hayFiltros = computed(
    () =>
      Boolean(busqueda.value.trim()) ||
      claves.some((clave) => filtros[clave] !== porDefecto(clave)),
  )

  function valorValido(clave, valor) {
    const defecto = porDefecto(clave)
    const permitidos = definicion[clave].permitidos
    const texto = String(valor ?? defecto)
    return !permitidos || permitidos.includes(texto) ? texto : defecto
  }

  function paginaValida(valor) {
    const numero = Number.parseInt(valor, 10)
    return Number.isFinite(numero) && numero > 0 ? numero : 1
  }

  function cancelarBusquedaPendiente() {
    window.clearTimeout(temporizadorBusqueda)
    temporizadorBusqueda = null
  }

  function construirQuery({ search, pagina, ...valores }) {
    const query = {}
    const termino = String(search).trim()
    if (termino) query.search = termino

    claves.forEach((clave) => {
      if (valores[clave] !== porDefecto(clave)) query[clave] = String(valores[clave])
    })

    if (Number(pagina) > 1) query.page = String(pagina)
    return query
  }

  function sonIgualesLasQueries(a, b) {
    const clavesA = Object.keys(a)
    const clavesB = Object.keys(b)
    return (
      clavesA.length === clavesB.length &&
      clavesA.every((clave) => String(a[clave]) === String(b[clave]))
    )
  }

  async function actualizarQuery(cambios = {}) {
    const actual = {
      search: busqueda.value,
      pagina: paginaValida(route.query.page),
      ...Object.fromEntries(claves.map((c) => [c, valorValido(c, route.query[c])])),
      ...cambios,
    }
    const query = construirQuery(actual)

    if (sonIgualesLasQueries(query, route.query)) return
    await router.replace({ name: nombreRuta, query })
  }

  async function cargarListado() {
    const idSolicitud = ++solicitudActual
    estadoVista.value = 'loading'
    mensajeError.value = ''

    if (temporizadorBusqueda === null) {
      busqueda.value = String(route.query.search ?? '')
    }
    claves.forEach((clave) => {
      filtros[clave] = valorValido(clave, route.query[clave])
    })

    const valores = Object.fromEntries(
      claves.map((clave) => [clave, filtros[clave] === porDefecto(clave) ? '' : filtros[clave]]),
    )

    try {
      const respuesta = await cargar({
        ...mapearParametros(valores),
        busqueda: busqueda.value.trim(),
        pagina: paginaValida(route.query.page),
        porPagina,
      })
      if (idSolicitud !== solicitudActual) return

      items.value = respuesta.items
      paginacion.value = respuesta.paginacion
      estadoVista.value = 'success'

      if (respuesta.paginacion.pagina !== paginaValida(route.query.page)) {
        await actualizarQuery({ pagina: respuesta.paginacion.pagina })
      }
    } catch (error) {
      if (idSolicitud !== solicitudActual) return
      items.value = []
      paginacion.value = { ...PAGINACION_VACIA }
      mensajeError.value = error?.message || mensajeDeError
      estadoVista.value = 'error'
    }
  }

  function cambiarBusqueda(valor) {
    busqueda.value = valor
    cancelarBusquedaPendiente()
    temporizadorBusqueda = window.setTimeout(() => {
      temporizadorBusqueda = null
      actualizarQuery({ search: valor, pagina: 1 })
    }, RETARDO_BUSQUEDA)
  }

  function cambiarFiltro(clave, valor) {
    filtros[clave] = valor
    cancelarBusquedaPendiente()
    actualizarQuery({ [clave]: valor, search: busqueda.value, pagina: 1 })
  }

  function cambiarPagina(pagina) {
    actualizarQuery({ pagina })
  }

  function limpiarFiltros() {
    cancelarBusquedaPendiente()
    busqueda.value = ''
    claves.forEach((clave) => {
      filtros[clave] = porDefecto(clave)
    })
    router.replace({ name: nombreRuta })
  }

  async function enfocarExito() {
    await nextTick()
    mensajeExitoRef.value?.focus()
  }

  async function anunciarExito(texto) {
    mensajeExito.value = texto
    await cargarListado()
    await enfocarExito()
  }

  watch(
    [() => route.query.search, () => route.query.page, ...claves.map((c) => () => route.query[c])],
    cargarListado,
    { immediate: true },
  )

  watch(
    () => route.query.notice,
    async (notice) => {
      if (!notice || !avisos[notice]) return
      mensajeExito.value = avisos[notice]
      const query = { ...route.query }
      delete query.notice
      await router.replace({ name: nombreRuta, query })
      await enfocarExito()
    },
    { immediate: true },
  )

  onBeforeUnmount(() => {
    solicitudActual += 1
    cancelarBusquedaPendiente()
  })

  return {
    estadoVista,
    items,
    paginacion,
    busqueda,
    filtros,
    hayFiltros,
    mensajeError,
    mensajeExito,
    mensajeExitoRef,
    cargarListado,
    cambiarBusqueda,
    cambiarFiltro,
    cambiarPagina,
    limpiarFiltros,
    anunciarExito,
  }
}
