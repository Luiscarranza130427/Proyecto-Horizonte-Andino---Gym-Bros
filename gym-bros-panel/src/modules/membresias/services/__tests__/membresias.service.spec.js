import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const PLAN_NUEVO = {
  nombre: 'Escala',
  descripcion: 'Plan para empresas en expansión.',
  precioOriginal: 599,
  precioInicial: 449,
  duracionDias: 60,
  limiteUsuarios: 400,
  activo: true,
  contenido: 'Hasta 400 usuarios\nSoporte prioritario',
  enlaceWhatsapp: 'https://wa.me/51999999999',
}

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({ default: { get: vi.fn(), post: vi.fn() } }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/membresias/services/membresias.service')
  const mock = await import('@/modules/membresias/mocks/membresias.mock')
  mock.restablecerPlanesMock()
  return servicio
}

async function completarPeticion(peticion) {
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(220)
  return peticion
}

describe('membresias.service en modo mock', () => {
  beforeEach(() => vi.resetModules())

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('entrega fichas paginadas con el contrato comercial', async () => {
    const servicio = await cargarServicioMock()

    const { items, paginacion } = await completarPeticion(
      servicio.obtenerPlanesComerciales({ porPagina: 3 }),
    )

    expect(items).toHaveLength(3)
    expect(paginacion.total).toBeGreaterThan(items.length)
    expect(items[0]).toMatchObject({
      id: expect.any(Number),
      nombre: expect.any(String),
      descripcion: expect.any(String),
      precioOriginal: expect.any(Number),
      precioInicial: expect.any(Number),
      duracionDias: expect.any(Number),
      limiteUsuarios: expect.any(Number),
      activo: expect.any(Boolean),
      contenido: expect.any(String),
      enlaceWhatsapp: expect.stringMatching(/^https:/),
    })
  })

  it('crea un plan sin convertir la duración a meses', async () => {
    const servicio = await cargarServicioMock()

    const creado = await completarPeticion(servicio.crearPlanComercial(PLAN_NUEVO))
    expect(creado).toMatchObject({ nombre: 'Escala', duracionDias: 60, limiteUsuarios: 400 })

    const { items } = await completarPeticion(
      servicio.obtenerPlanesComerciales({ busqueda: 'Escala' }),
    )
    expect(items).toHaveLength(1)
    expect(items[0].precioInicial).toBe(449)
  })

  it('carga y actualiza un plan existente', async () => {
    const servicio = await cargarServicioMock()

    const antes = await completarPeticion(servicio.obtenerPlanComercial(1))
    const actualizado = await completarPeticion(
      servicio.actualizarPlanComercial(1, { ...antes, nombre: 'Impulso renovado', activo: false }),
    )

    expect(actualizado).toMatchObject({ id: 1, nombre: 'Impulso renovado', activo: false })
    const despues = await completarPeticion(servicio.obtenerPlanComercial(1))
    expect(despues.nombre).toBe('Impulso renovado')
  })

  it('rechaza duraciones no enteras y enlaces inseguros', async () => {
    const servicio = await cargarServicioMock()
    const peticion = servicio.crearPlanComercial({
      ...PLAN_NUEVO,
      duracionDias: 1.5,
      enlaceWhatsapp: 'javascript:alert(1)',
    })
    const rechazo = expect(peticion).rejects.toMatchObject({
      status: 422,
      errors: expect.objectContaining({
        duracionDias: expect.any(Array),
        enlaceWhatsapp: expect.any(Array),
      }),
    })

    await vi.advanceTimersByTimeAsync(220)
    await rechazo
  })
})

describe('membresias.service con API Laravel', () => {
  beforeEach(() => vi.resetModules())
  afterEach(() => vi.restoreAllMocks())

  it('normaliza los nombres de la base de datos', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 8,
            nombre: 'Titanio',
            descripcion: 'Plan completo',
            precio_original: '899.00',
            precio_inicial: '699.00',
            duracion_dias: 30,
            limite_usuarios: 1000,
            activo: 1,
            contenido: 'Soporte especializado',
            enlace_whatsapp: 'https://wa.me/51900000000',
          },
        ],
        current_page: 1,
        last_page: 1,
        per_page: 8,
        total: 1,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerPlanesComerciales } =
      await import('@/modules/membresias/services/membresias.service')

    const { items } = await obtenerPlanesComerciales()

    expect(items[0]).toMatchObject({
      id: 8,
      precioOriginal: 899,
      precioInicial: 699,
      duracionDias: 30,
      limiteUsuarios: 1000,
      activo: true,
      enlaceWhatsapp: 'https://wa.me/51900000000',
    })
  })

  it('serializa únicamente los campos reales de la tabla planes', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 9, ...PLAN_NUEVO } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearPlanComercial } = await import('@/modules/membresias/services/membresias.service')

    await crearPlanComercial({ ...PLAN_NUEVO, destacado: true, suscriptores: 999 })

    expect(post).toHaveBeenCalledWith('/planes', {
      nombre: 'Escala',
      descripcion: 'Plan para empresas en expansión.',
      precio_original: 599,
      precio_inicial: 449,
      duracion_dias: 60,
      limite_usuarios: 400,
      activo: true,
      contenido: 'Hasta 400 usuarios\nSoporte prioritario',
      enlace_whatsapp: 'https://wa.me/51999999999',
    })
  })

  it('actualiza usando PUT y mantiene el mismo contrato snake_case', async () => {
    const put = vi.fn().mockResolvedValue({ data: { data: { id: 9, ...PLAN_NUEVO } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { actualizarPlanComercial } =
      await import('@/modules/membresias/services/membresias.service')

    await actualizarPlanComercial(9, PLAN_NUEVO)

    expect(put).toHaveBeenCalledWith(
      '/planes/9',
      expect.objectContaining({
        precio_original: 599,
        precio_inicial: 449,
        duracion_dias: 60,
        limite_usuarios: 400,
      }),
    )
  })
})
