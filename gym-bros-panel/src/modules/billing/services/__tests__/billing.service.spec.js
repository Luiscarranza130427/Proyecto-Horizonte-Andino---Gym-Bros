import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({ default: { get: vi.fn() } }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/billing/services/billing.service')
  await import('@/modules/billing/mocks/billing.mock')
  return servicio
}

async function completarPeticion(peticion) {
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(220)
  return peticion
}

describe('billing.service en modo mock', () => {
  beforeEach(() => vi.resetModules())

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('obtiene el reporte de pagos con datos normalizados y paginación', async () => {
    const servicio = await cargarServicioMock()

    const { items, paginacion } = await completarPeticion(
      servicio.obtenerReportePagos({ porPagina: 5 }),
    )

    expect(items).toHaveLength(5)
    expect(paginacion.total).toBeGreaterThan(5)
    expect(items[0]).toMatchObject({
      id: expect.any(Number),
      codigo: expect.stringMatching(/^PAG-\d{4}$/),
      fecha: expect.any(String),
      empresa: expect.objectContaining({
        id: expect.any(Number),
        nombre: expect.any(String),
      }),
      plan: expect.objectContaining({
        id: expect.any(Number),
        nombre: expect.any(String),
      }),
      precio: expect.any(Number),
      moneda: 'PEN',
      cantidadMeses: expect.any(Number),
    })
  })

  it('obtiene las métricas financieras agregadas', async () => {
    const servicio = await cargarServicioMock()

    const metricas = await completarPeticion(servicio.obtenerMetricasPagos())

    expect(metricas).toMatchObject({
      totalIngresos: expect.any(Number),
      totalTransacciones: expect.any(Number),
      ticketPromedio: expect.any(Number),
      totalMeses: expect.any(Number),
      moneda: 'PEN',
    })
    expect(metricas.totalIngresos).toBeGreaterThan(0)
  })

  it('obtiene el detalle de un pago por su ID', async () => {
    const servicio = await cargarServicioMock()

    const pago = await completarPeticion(servicio.obtenerPago(1))

    expect(pago).toMatchObject({
      id: 1,
      codigo: 'PAG-0001',
      precio: expect.any(Number),
      metodoPago: expect.any(String),
      estado: 'completado',
    })
  })
})

describe('billing.service con API real', () => {
  beforeEach(() => vi.resetModules())
  afterEach(() => vi.restoreAllMocks())

  it('normaliza la respuesta de la API para pagos', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 10,
            fecha_pago: '2026-08-01',
            monto: 349,
            moneda: 'PEN',
            // `pagos` tiene `referencia`; NO tiene `codigo`. Comprobado contra
            // la API real: id, id_empresas, id_suscripciones, monto, moneda,
            // metodo_pago, referencia, estado, fecha_pago.
            referencia: 'OP-99120',
            suscripcion: {
              empresa: { id: 1, razon_social: 'Power Gym' },
              plan: { id: 2, nombre: 'Fuerza' },
              fecha_inicio: '2026-08-01',
              fecha_fin: '2026-09-01',
            },
          },
        ],
        current_page: 1,
        last_page: 1,
        per_page: 10,
        total: 1,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerReportePagos } = await import('@/modules/billing/services/billing.service')

    const { items } = await obtenerReportePagos()

    expect(items[0]).toMatchObject({
      id: 10,
      fecha: '2026-08-01',
      precio: 349,
      moneda: 'PEN',
      empresa: { id: 1, nombre: 'Power Gym' },
      plan: { id: 2, nombre: 'Fuerza' },
      cantidadMeses: 1,
    })

    /*
     * `codigo` va vacío porque la API no lo manda. Antes se fabricaba como
     * `PAG-0010` a partir del id: un identificador que no existe en ninguna
     * parte y que, impreso en un recibo, nadie podría buscar después.
     */
    expect(items[0].codigo).toBe('')
  })
})
