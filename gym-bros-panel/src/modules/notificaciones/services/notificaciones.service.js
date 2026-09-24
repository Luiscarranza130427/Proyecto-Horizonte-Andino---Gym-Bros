import api from '@/core/api/api'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarListado as normalizarListadoBase,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'

const cargarMock = () => import('@/modules/notificaciones/mocks/notificaciones.mock')

const CAMPOS_ERROR = {
  alcance: 'alcance',
  id_empresas: 'idEmpresas',
  id_usuarios: 'idUsuarios',
  fecha_envio: 'fechaEnvio',
  tipo: 'tipo',
  titulo: 'titulo',
  mensaje: 'mensaje',
}

const normalizarError = crearNormalizadorDeError(CAMPOS_ERROR)

export function normalizarNotificacion(datos = {}) {
  return {
    id: datos.id,
    idEmpresas: datos.id_empresas ?? datos.idEmpresas ?? null,
    nombreEmpresa: datos.nombre_empresa ?? datos.nombreEmpresa ?? null,
    idUsuarios: datos.id_usuarios ?? datos.idUsuarios ?? null,
    nombreUsuario: datos.nombre_usuario ?? datos.nombreUsuario ?? null,
    tipo: datos.tipo ?? 'otro',
    titulo: datos.titulo ?? '',
    mensaje: datos.mensaje ?? '',
    fechaEnvio: datos.fecha_envio ?? datos.fechaEnvio ?? '',
    leida: Boolean(datos.leida),
    enviada: Boolean(datos.enviada),
    creadaEn: datos.created_at ?? datos.creadaEn ?? '',
  }
}

function prepararPayload(payload) {
  return {
    alcance: payload.alcance,
    id_empresas: payload.idEmpresas ? Number(payload.idEmpresas) : null,
    tipo: payload.tipo || 'otro',
    titulo: payload.titulo,
    mensaje: payload.mensaje,
    fecha_envio: payload.fechaEnvio || null,
    programar: Boolean(payload.programar),
  }
}

export async function contarNoLeidas() {
  if (USE_MOCKS) {
    const { contarNoLeidasMock } = await cargarMock()
    return contarNoLeidasMock()
  }

  const { data } = await api.get('/notificaciones/activas')
  const notificaciones = Array.isArray(data) ? data : (data?.data ?? [])

  if (Array.isArray(notificaciones)) {
    return notificaciones.filter((notificacion) => !notificacion.leida).length
  }

  return Number(data?.total ?? data?.meta?.total ?? 0)
}

export async function obtenerNotificacionesRecibidas() {
  if (USE_MOCKS) {
    const { listarNotificacionesRecibidasMock } = await cargarMock()
    const respuesta = await listarNotificacionesRecibidasMock()
    return respuesta.map(normalizarNotificacion)
  }

  const { data } = await api.get('/notificaciones/activas')
  const notificaciones = Array.isArray(data) ? data : (data?.data ?? [])

  return Array.isArray(notificaciones) ? notificaciones.map(normalizarNotificacion) : []
}

export async function obtenerNotificacionesProgramadas() {
  if (USE_MOCKS) {
    const { listarNotificacionesProgramadasMock } = await cargarMock()
    const respuesta = await listarNotificacionesProgramadasMock()
    return respuesta.map(normalizarNotificacion)
  }

  return ejecutar(async () => {
    const { data } = await api.get('/notificaciones/programadas')
    const coleccion = Array.isArray(data) ? data : (data?.data ?? [])
    return coleccion.map(normalizarNotificacion)
  }, normalizarError)
}

export async function obtenerNotificacionesEnviadas({
  pagina = 1,
  porPagina = 6,
  tipo = '',
  busqueda = '',
} = {}) {
  if (USE_MOCKS) {
    const { listarNotificacionesEnviadasMock } = await cargarMock()
    const respuesta = await listarNotificacionesEnviadasMock({
      pagina,
      porPagina,
      tipo,
      busqueda,
    })
    return {
      items: respuesta.items.map(normalizarNotificacion),
      paginacion: respuesta.paginacion,
    }
  }

  return ejecutar(async () => {
    const { data } = await api.get('/notificaciones', {
      params: {
        page: pagina,
        per_page: porPagina,
        enviada: true,
        tipo: tipo || undefined,
        search: busqueda || undefined,
      },
    })
    return normalizarListadoBase(data, normalizarNotificacion, pagina, porPagina)
  }, normalizarError)
}

export async function crearNotificacion(datos) {
  if (USE_MOCKS) {
    const { crearNotificacionMock } = await cargarMock()
    const respuesta = await crearNotificacionMock(datos)
    return normalizarNotificacion(respuesta)
  }

  return ejecutar(async () => {
    const { data } = await api.post('/notificaciones', prepararPayload(datos))
    return normalizarNotificacion(data?.data ?? data)
  }, normalizarError)
}

export async function enviarNotificacionAhora(id) {
  if (USE_MOCKS) {
    const { enviarNotificacionAhoraMock } = await cargarMock()
    const respuesta = await enviarNotificacionAhoraMock(id)
    return normalizarNotificacion(respuesta)
  }

  return ejecutar(async () => {
    const { data } = await api.post(`/notificaciones/${id}/enviar-ahora`)
    return normalizarNotificacion(data?.data ?? data)
  }, normalizarError)
}

export async function eliminarNotificacion(id) {
  if (USE_MOCKS) {
    const { eliminarNotificacionMock } = await cargarMock()
    return eliminarNotificacionMock(id)
  }

  return ejecutar(async () => {
    const { data } = await api.delete(`/notificaciones/${id}`)
    return data
  }, normalizarError)
}
