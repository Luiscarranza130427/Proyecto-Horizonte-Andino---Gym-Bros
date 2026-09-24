import api from '@/core/api/api'
import {
  ejecutarPeticion as ejecutar,
  normalizarListado as normalizarListadoBase,
} from '@/core/api/normalizacion'
import { USE_MOCKS } from '@/core/config/env'

const cargarMock = () => import('@/modules/billing/mocks/billing.mock')

function mesesEntre(fechaInicio, fechaFin) {
  const inicio = new Date(`${fechaInicio}T00:00:00Z`)
  const fin = new Date(`${fechaFin}T00:00:00Z`)
  if (Number.isNaN(inicio.getTime()) || Number.isNaN(fin.getTime()) || fin <= inicio) return 0
  return Math.max(1, Math.round((fin.getTime() - inicio.getTime()) / 2_592_000_000))
}

function normalizarEmpresa(datos = {}) {
  return {
    id: datos.id ?? datos.id_empresas ?? null,
    nombre: datos.nombre ?? datos.name ?? datos.razon_social ?? '',
  }
}

function normalizarPlan(datos = {}) {
  return {
    id: datos.id ?? datos.id_planes ?? null,
    nombre: datos.nombre ?? datos.name ?? '',
  }
}

export function normalizarPago(datos = {}) {
  const suscripcion = datos.suscripcion ?? datos.subscription ?? {}
  const empresa = datos.empresa ?? datos.company ?? suscripcion.empresa ?? {}
  const plan = datos.plan ?? suscripcion.plan ?? {}
  const fechaInicio =
    suscripcion.fecha_inicio ?? suscripcion.fechaInicio ?? suscripcion.start_date ?? ''
  const fechaFin = suscripcion.fecha_fin ?? suscripcion.fechaFin ?? suscripcion.end_date ?? ''

  const cantidadMesesApi = datos.cantidad_meses ?? datos.cantidadMeses ?? datos.months
  const monto = datos.monto ?? datos.precio ?? datos.amount ?? null

  return {
    id: datos.id,
    codigo: datos.codigo ?? '',
    fecha: datos.fecha_pago ?? datos.fecha ?? datos.paid_at ?? '',
    empresa: normalizarEmpresa(empresa),
    plan: normalizarPlan(plan),
    precio: monto == null ? null : Number(monto),
    moneda: datos.moneda ?? datos.currency ?? '',
    cantidadMeses:
      cantidadMesesApi != null
        ? Number(cantidadMesesApi)
        : fechaInicio && fechaFin
          ? mesesEntre(fechaInicio, fechaFin)
          : null,
    // Un método de pago inventado en un recibo es un dato contable falso.
    metodoPago: datos.metodo_pago ?? datos.metodoPago ?? '',
    estado: datos.estado ?? datos.status ?? '',
  }
}

function prepararParametros({
  busqueda = '',
  empresaId = '',
  planId = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  return {
    search: busqueda,
    empresa_id: empresaId,
    plan_id: planId,
    page: pagina,
    per_page: porPagina,
  }
}

const normalizarListado = (datos) => normalizarListadoBase(datos, normalizarPago)

export async function obtenerReportePagos(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerReportePagosMock(params)

  return ejecutar(
    async () => {
      const { data } = await api.get('/pagos', { params: prepararParametros(params) })
      return normalizarListado(data)
    },
    (error) => error,
  )
}

export async function obtenerMetricasPagos(params = {}) {
  if (USE_MOCKS) return (await cargarMock()).obtenerMetricasPagosMock(params)

  return ejecutar(
    async () => {
      const { data } = await api.get('/pagos/metricas', { params: prepararParametros(params) })
      return data.data ?? data
    },
    (error) => error,
  )
}

export async function obtenerPago(id) {
  if (USE_MOCKS) return (await cargarMock()).obtenerPagoMock(id)

  return ejecutar(
    async () => {
      const { data } = await api.get(`/pagos/${id}`)
      return normalizarPago(data.data ?? data)
    },
    (error) => error,
  )
}
