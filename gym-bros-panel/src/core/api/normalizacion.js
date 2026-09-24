import { HttpError } from '@/core/api/http-error'

export function normalizarEstado(estado) {
  if (estado === 'activo' || estado === true || estado === 1) return 'active'
  if (estado === 'inactivo' || estado === false || estado === 0) return 'inactive'
  return estado === 'active' ? 'active' : 'inactive'
}

export function normalizarListado(datos = {}, normalizarItem) {
  const cuerpo = datos?.data && !Array.isArray(datos.data) ? datos.data : datos
  const itemsCrudos = Array.isArray(datos?.data)
    ? datos.data
    : Array.isArray(cuerpo?.items)
      ? cuerpo.items
      : Array.isArray(cuerpo)
        ? cuerpo
        : []
  const meta = datos?.meta ?? cuerpo?.meta ?? cuerpo?.paginacion ?? cuerpo ?? {}
  const pagina = Number(meta.current_page ?? meta.pagina ?? meta.page ?? 1)
  const porPagina = Number(meta.per_page ?? meta.porPagina ?? (itemsCrudos.length || 10))
  const total = Number(meta.total ?? itemsCrudos.length)

  return {
    items: itemsCrudos.map(normalizarItem),
    paginacion: {
      pagina,
      ultimaPagina: Number(meta.last_page ?? meta.ultimaPagina ?? meta.total_pages ?? 1),
      porPagina,
      total,
      desde: Number(meta.from ?? meta.desde ?? (total ? (pagina - 1) * porPagina + 1 : 0)),
      hasta: Number(
        meta.to ?? meta.hasta ?? (total ? (pagina - 1) * porPagina + itemsCrudos.length : 0),
      ),
    },
  }
}

export function seleccionarCamposEditables(payload = {}, campos = []) {
  return Object.fromEntries(
    campos.filter((campo) => Object.hasOwn(payload, campo)).map((campo) => [campo, payload[campo]]),
  )
}

export function crearNormalizadorDeError(diccionario = {}) {
  return function normalizarError(error) {
    if (!error) return new HttpError(500, 'Ha ocurrido un error inesperado.')

    const status = error.status ?? error.response?.status ?? 500
    const data = error.response?.data ?? error.data ?? {}
    const message = data.message ?? error.message ?? 'Ha ocurrido un error inesperado.'
    const rawErrors = error.errors ?? data.errors ?? {}

    if (status !== 422 || !rawErrors || Object.keys(rawErrors).length === 0) {
      if (error instanceof HttpError) return error
      return new HttpError({ status, message, errors: rawErrors })
    }

    const errors = Object.entries(rawErrors).reduce((acumulado, [campo, mensajes]) => {
      const patron = Object.keys(diccionario).find(
        (clave) => clave.endsWith('.*') && campo.startsWith(clave.slice(0, -1)),
      )
      const campoNormalizado = diccionario[campo] ?? diccionario[patron] ?? campo
      acumulado[campoNormalizado] = [
        ...(acumulado[campoNormalizado] ?? []),
        ...(Array.isArray(mensajes) ? mensajes : [mensajes]),
      ]
      return acumulado
    }, {})
    return new HttpError({ status, message, errors })
  }
}

export const errorPorDefecto = crearNormalizadorDeError()

export async function ejecutarPeticion(peticion, normalizarError = errorPorDefecto) {
  try {
    return await peticion()
  } catch (error) {
    throw normalizarError(error)
  }
}
