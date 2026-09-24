import api from '@/core/api/api'
import { HttpError } from '@/core/api/http-error'
import { USE_MOCKS } from '@/core/config/env'
import { leerSesion } from '@/core/storage/session.storage'
import { resolverUrlStorage } from '@/shared/utils/storage'

const cargarMock = () => import('@/modules/dashboard/mocks/dashboard.mock')

const RESUMEN_VACIO = {
  metricas: [],
  progreso: {
    titulo: '',
    descripcion: '',
    unidad: 'usuarios activos',
    etiquetas: [],
    valores: [],
    resumen: { etiqueta: '', valor: 0, detalle: '' },
  },
  ejerciciosPopulares: [],
  actividadReciente: [],
}

const copiarLista = (lista) =>
  Array.isArray(lista) ? lista.map((elemento) => ({ ...elemento })) : []

function normalizarMetricas(metricas) {
  return copiarLista(metricas).map((metrica) => ({
    ...metrica,
    tendencia: {
      valor: 0,
      prefijo: '',
      sufijo: '',
      detalle: '',
      tono: 'neutro',
      ...metrica.tendencia,
    },
  }))
}

function crearMetrica(id, etiqueta, valor, icono, detalle = '') {
  return {
    id,
    etiqueta,
    valor,
    icono,
    tipoValor: typeof valor === 'number' ? 'numero' : 'texto',
    tendencia: { valor: 0, prefijo: '', sufijo: '', detalle, tono: 'neutro' },
  }
}

function metricasDesdeResumenWeb(resumen) {
  const metricas = [
    crearMetrica('usuarios', 'Usuarios', Number(resumen.cantidad_usuarios ?? 0), 'users'),
    crearMetrica('empresas', 'Empresas', Number(resumen.cantidad_empresas ?? 0), 'buildings'),
  ]

  if (resumen.cantidad_ejercicios_activos != null) {
    metricas.push(
      crearMetrica(
        'ejercicios-activos',
        'Ejercicios activos',
        Number(resumen.cantidad_ejercicios_activos),
        'activity',
      ),
    )
  }

  if (resumen.cantidad_ejercicios != null) {
    metricas.push(
      crearMetrica(
        'ejercicios-total',
        'Ejercicios creados',
        Number(resumen.cantidad_ejercicios),
        'dumbbell',
      ),
    )
  }

  const nombrePlan = resumen.plan_empresa?.nombre ?? resumen.plan_empresa ?? 'Sin plan'
  metricas.push(crearMetrica('plan-empresa', 'Plan de la empresa', nombrePlan, 'plan'))
  return metricas
}

function normalizarProgreso(progreso) {
  const serie = progreso ?? {}

  return {
    ...RESUMEN_VACIO.progreso,
    ...serie,
    etiquetas: Array.isArray(serie.etiquetas) ? [...serie.etiquetas] : [],
    valores: Array.isArray(serie.valores) ? [...serie.valores] : [],
    resumen: { ...RESUMEN_VACIO.progreso.resumen, ...serie.resumen },
  }
}

function extraerBanners(datos) {
  if (Array.isArray(datos)) return datos
  if (Array.isArray(datos?.data)) return datos.data
  if (Array.isArray(datos?.banners)) return datos.banners
  const banner = datos?.data ?? datos?.banner ?? datos
  return banner && typeof banner === 'object' ? [banner] : []
}

function normalizarEnlace(enlace) {
  if (typeof enlace !== 'string') return ''
  const valor = enlace.trim()
  if (!valor) return ''
  if (valor.startsWith('/') && !valor.startsWith('//')) return valor

  try {
    const url = new URL(valor)
    return url.protocol === 'http:' || url.protocol === 'https:' ? url.href : ''
  } catch {
    return ''
  }
}

function normalizarBanner(banner = {}) {
  return {
    imagenUrl: resolverUrlStorage(banner.imagen ?? ''),
    contenido: String(banner.contenido_text ?? banner.contenido ?? '').trim(),
    textoBoton: String(banner.texto_boton ?? banner.textoBoton ?? '').trim(),
    enlaceBoton: normalizarEnlace(banner.enlace_boton ?? banner.enlaceBoton),
  }
}

function normalizarDashboard(datos) {
  const resumen = datos?.data ?? datos?.dashboard ?? datos ?? {}
  const metricas = Array.isArray(resumen.metricas)
    ? normalizarMetricas(resumen.metricas)
    : metricasDesdeResumenWeb(resumen)

  return {
    empresaId: resumen.id_empresa ?? null,
    metricas,
    progreso: normalizarProgreso(resumen.progreso),
    ejerciciosPopulares: copiarLista(resumen.ejerciciosPopulares),
    actividadReciente: copiarLista(resumen.actividadReciente),
  }
}

export async function obtenerDashboard() {
  if (USE_MOCKS) {
    const { obtenerDashboardMock } = await cargarMock()
    const datos = await obtenerDashboardMock()
    return normalizarDashboard(datos.dashboard)
  }

  const idUsuario = leerSesion()?.usuario?.id
  if (!idUsuario) throw new HttpError(401, 'La sesión no identifica al usuario del dashboard.')

  const { data } = await api.get(`/usuarios/${Number(idUsuario)}/resumen-web`)
  return normalizarDashboard(data)
}

export async function obtenerBannerPrincipal() {
  const [banner] = await obtenerBanners()
  return banner ?? normalizarBanner()
}

export async function obtenerBanners() {
  if (USE_MOCKS) {
    const { obtenerDashboardMock } = await cargarMock()
    const datos = await obtenerDashboardMock()
    return extraerBanners(datos.banner)
      .map(normalizarBanner)
      .filter((banner) => banner.imagenUrl)
  }

  const { data } = await api.get('/banners')
  return extraerBanners(data)
    .map(normalizarBanner)
    .filter((banner) => banner.imagenUrl)
}
