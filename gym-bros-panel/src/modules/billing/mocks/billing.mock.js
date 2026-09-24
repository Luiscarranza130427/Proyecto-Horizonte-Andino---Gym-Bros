import { HttpError } from '@/core/api/http-error'
import { EMPRESAS_PAGOS, PLANES_PAGOS } from '@/modules/billing/catalogos'

const LATENCIA_MINIMA = 220
const LATENCIA_MAXIMA = 520

const PAGOS_INICIALES = Array.from({ length: 24 }, (_, indice) => {
  const plan = PLANES_PAGOS[indice % PLANES_PAGOS.length]
  const empresa = EMPRESAS_PAGOS[indice % EMPRESAS_PAGOS.length]
  const cantidadMeses = plan.id === 4 ? 12 : (indice % 3) + 1
  const dia = String((indice % 28) + 1).padStart(2, '0')
  const mes = String(8 - Math.floor(indice / 6)).padStart(2, '0')
  const anio = 2026

  return {
    id: indice + 1,
    codigo: `PAG-${String(indice + 1).padStart(4, '0')}`,
    fecha: `${anio}-${mes}-${dia}`,
    empresa: { id: empresa.id, nombre: empresa.nombre },
    plan: { id: plan.id, nombre: plan.nombre },
    precio: plan.precio * cantidadMeses,
    moneda: 'PEN',
    cantidadMeses,
    metodoPago: indice % 2 === 0 ? 'Tarjeta de crédito' : 'Transferencia bancaria',
    estado: 'completado',
  }
})

const esperar = (ms) => new Promise((resolve) => setTimeout(resolve, ms))

function calcularLatencia() {
  return Math.floor(LATENCIA_MINIMA + Math.random() * (LATENCIA_MAXIMA - LATENCIA_MINIMA + 1))
}

function normalizarPagina(valor, porDefecto) {
  const numero = Number.parseInt(valor, 10)
  return Number.isFinite(numero) && numero > 0 ? numero : porDefecto
}

function sinTildes(texto = '') {
  return texto
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
}

function filtrarPagos(pagos, { busqueda = '', empresaId = '', planId = '' } = {}) {
  const termino = sinTildes(busqueda).trim()
  return pagos.filter((pago) => {
    const coincideTexto =
      !termino ||
      sinTildes(pago.empresa.nombre).includes(termino) ||
      sinTildes(pago.plan.nombre).includes(termino) ||
      sinTildes(pago.codigo).includes(termino)
    const coincideEmpresa = !empresaId || pago.empresa.id === Number(empresaId)
    const coincidePlan = !planId || pago.plan.id === Number(planId)

    return coincideTexto && coincideEmpresa && coincidePlan
  })
}

export async function obtenerReportePagosMock({
  busqueda = '',
  empresaId = '',
  planId = '',
  pagina = 1,
  porPagina = 10,
} = {}) {
  await esperar(calcularLatencia())

  const base = structuredClone(PAGOS_INICIALES).sort((a, b) => b.fecha.localeCompare(a.fecha))
  const filtrados = filtrarPagos(base, { busqueda, empresaId, planId })
  const cantidadPorPagina = Math.min(normalizarPagina(porPagina, 10), 100)
  const total = filtrados.length
  const ultimaPagina = Math.max(1, Math.ceil(total / cantidadPorPagina))
  const paginaActual = Math.min(normalizarPagina(pagina, 1), ultimaPagina)
  const inicio = (paginaActual - 1) * cantidadPorPagina
  const items = filtrados.slice(inicio, inicio + cantidadPorPagina)

  return {
    items,
    paginacion: {
      pagina: paginaActual,
      ultimaPagina,
      porPagina: cantidadPorPagina,
      total,
      desde: total ? inicio + 1 : 0,
      hasta: total ? inicio + items.length : 0,
    },
  }
}

export async function obtenerMetricasPagosMock(params = {}) {
  await esperar(calcularLatencia())

  const filtrados = filtrarPagos(structuredClone(PAGOS_INICIALES), params)
  const totalIngresos = filtrados.reduce((acumulado, pago) => acumulado + pago.precio, 0)
  const totalTransacciones = filtrados.length
  const ticketPromedio = totalTransacciones > 0 ? Math.round(totalIngresos / totalTransacciones) : 0
  const totalMeses = filtrados.reduce((acumulado, pago) => acumulado + pago.cantidadMeses, 0)

  return {
    totalIngresos,
    totalTransacciones,
    ticketPromedio,
    totalMeses,
    moneda: 'PEN',
  }
}

export async function obtenerPagoMock(id) {
  await esperar(calcularLatencia())

  const pago = PAGOS_INICIALES.find((p) => p.id === Number(id))
  if (!pago) {
    throw new HttpError(404, 'Comprobante de pago no encontrado.')
  }

  return structuredClone(pago)
}
