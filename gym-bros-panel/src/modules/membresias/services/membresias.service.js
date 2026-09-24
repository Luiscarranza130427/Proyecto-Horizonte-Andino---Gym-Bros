import api from '@/core/api/api'
import {
  crearNormalizadorDeError,
  ejecutarPeticion as ejecutar,
  normalizarListado as normalizarListadoBase,
  seleccionarCamposEditables as seleccionarEditables,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'

const cargarMock = () => import('@/modules/membresias/mocks/membresias.mock')

const CAMPOS_ERROR = {
  precio_original: 'precioOriginal',
  precio_inicial: 'precioInicial',
  duracion_dias: 'duracionDias',
  limite_usuarios: 'limiteUsuarios',
  enlace_whatsapp: 'enlaceWhatsapp',
  contenido: 'servicios',
  content: 'servicios',
}

const CAMPOS_EDITABLES = [
  'nombre',
  'descripcion',
  'precioOriginal',
  'precioInicial',
  'duracionDias',
  'limiteUsuarios',
  'activo',
  'contenido',
  'enlaceWhatsapp',
]

function normalizarBooleano(valor) {
  return valor === true || valor === 1 || valor === '1' || valor === 'true'
}

export function normalizarPlan(datos = {}) {
  return {
    id: datos.id,
    nombre: datos.nombre ?? datos.name ?? '',
    descripcion: datos.descripcion ?? datos.description ?? '',
    precioOriginal: Number(datos.precio_original ?? datos.precioOriginal ?? 0),
    precioInicial: Number(datos.precio_inicial ?? datos.precioInicial ?? 0),
    duracionDias: Number(datos.duracion_dias ?? datos.duracionDias ?? 0),
    limiteUsuarios: Number(datos.limite_usuarios ?? datos.limiteUsuarios ?? 0),
    activo: normalizarBooleano(datos.activo ?? datos.active),
    contenido: datos.contenido ?? datos.content ?? '',
    enlaceWhatsapp: datos.enlace_whatsapp ?? datos.enlaceWhatsapp ?? '',
  }
}

function prepararPayload(payload) {
  const campos = {
    nombre: payload.nombre,
    descripcion: payload.descripcion,
    precio_original: payload.precioOriginal,
    precio_inicial: payload.precioInicial,
    duracion_dias: payload.duracionDias,
    limite_usuarios: payload.limiteUsuarios,
    activo: payload.activo,
    contenido: payload.contenido,
    enlace_whatsapp: payload.enlaceWhatsapp,
  }

  return Object.fromEntries(Object.entries(campos).filter(([, valor]) => valor !== undefined))
}

function prepararParametros({ busqueda = '', estado = '', pagina = 1, porPagina = 6 } = {}) {
  return {
    search: busqueda,
    estado,
    page: pagina,
    per_page: porPagina,
  }
}

const normalizarError = crearNormalizadorDeError(CAMPOS_ERROR)
const ejecutarPeticion = (peticion) => ejecutar(peticion, normalizarError)
const normalizarListado = (datos) => normalizarListadoBase(datos, normalizarPlan)
const seleccionarCamposEditables = (payload) => seleccionarEditables(payload, CAMPOS_EDITABLES)

export async function obtenerPlanesComerciales(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerPlanesComercialesMock(params)

  return ejecutarPeticion(async () => {
    const { data } = await api.get('/planes', { params: prepararParametros(params) })
    return normalizarListado(data)
  })
}

export async function obtenerPlanComercial(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerPlanComercialMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.get(`/planes/${id}`)
    return normalizarPlan(data.data ?? data)
  })
}

export async function crearPlanComercial(payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).crearPlanComercialMock(datosEditables)

  return ejecutarPeticion(async () => {
    const { data } = await api.post('/planes', prepararPayload(datosEditables))
    return normalizarPlan(data.data ?? data)
  })
}

export async function actualizarPlanComercial(id, payload) {
  const datosEditables = seleccionarCamposEditables(payload)
  if (USE_MOCKS) return (await cargarMock()).actualizarPlanComercialMock(id, datosEditables)

  return ejecutarPeticion(async () => {
    const { data } = await api.put(`/planes/${id}`, prepararPayload(datosEditables))
    return normalizarPlan(data.data ?? data)
  })
}

export async function eliminarPlanComercial(id) {
  if (USE_MOCKS) return (await cargarMock()).eliminarPlanComercialMock(id)

  return ejecutarPeticion(async () => {
    const { data } = await api.delete(`/planes/${id}`)
    return data.data ?? data
  })
}
