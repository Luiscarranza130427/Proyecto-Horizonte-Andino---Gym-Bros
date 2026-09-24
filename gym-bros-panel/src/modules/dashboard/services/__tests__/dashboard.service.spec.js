import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const RESPUESTA_API = {
  data: {
    id_usuario: 7,
    tipo_usuario: 'Administrador',
    cantidad_usuarios: 42,
    cantidad_empresas: 3,
    cantidad_ejercicios_activos: 28,
    cantidad_ejercicios: 34,
    plan_empresa: { id: 2, nombre: 'Plan Pro' },
  },
}

const RESPUESTA_BANNERS = {
  data: [
    {
      id: 1,
      imagen: 'banners/inicio.webp',
      contenido_text: 'Entrena con propósito',
      texto_boton: 'Conocer más',
      enlace_boton: 'https://gymbros.test/planes',
    },
    {
      id: 2,
      imagen: 'banners/planes.webp',
      contenido_text: 'Planes para tu gimnasio',
      texto_boton: 'Ver planes',
      enlace_boton: '/planes',
    },
  ],
}

describe('dashboard.service', () => {
  beforeEach(() => {
    vi.resetModules()
    vi.doMock('@/core/storage/session.storage', () => ({
      leerSesion: () => ({ usuario: { id: 7 } }),
    }))
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it('devuelve el resumen mock con una latencia entre 300 y 600 ms', async () => {
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
    vi.doMock('@/core/api/api', () => ({ default: { get: vi.fn() } }))
    vi.useFakeTimers()
    vi.spyOn(Math, 'random').mockReturnValue(0.5)
    const temporizador = vi.spyOn(globalThis, 'setTimeout')
    const { obtenerDashboard } = await import('@/modules/dashboard/services/dashboard.service')
    await import('@/modules/dashboard/mocks/dashboard.mock')

    const peticion = obtenerDashboard()

    await vi.advanceTimersByTimeAsync(0)
    expect(temporizador).toHaveBeenCalledWith(expect.any(Function), 450)
    await vi.advanceTimersByTimeAsync(450)

    const resumen = await peticion
    expect(resumen.metricas).toHaveLength(4)
    expect(resumen.progreso.valores).not.toHaveLength(0)
    expect(resumen.ejerciciosPopulares[0].nombre).toBe('Press de banca')
    expect(resumen.actividadReciente[0].fecha).toMatch(/^\d{4}-\d{2}-\d{2}T/)
  })

  it('entrega copias independientes para que una carga no contamine la siguiente', async () => {
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
    vi.doMock('@/core/api/api', () => ({ default: { get: vi.fn() } }))
    vi.useFakeTimers()
    vi.spyOn(Math, 'random').mockReturnValue(0)
    const { obtenerDashboard } = await import('@/modules/dashboard/services/dashboard.service')
    await import('@/modules/dashboard/mocks/dashboard.mock')

    const primeraPeticion = obtenerDashboard()
    await vi.advanceTimersByTimeAsync(0)
    await vi.advanceTimersByTimeAsync(300)
    const primeraCarga = await primeraPeticion
    primeraCarga.metricas[0].valor = -1

    const segundaPeticion = obtenerDashboard()
    await vi.advanceTimersByTimeAsync(0)
    await vi.advanceTimersByTimeAsync(300)
    const segundaCarga = await segundaPeticion

    expect(segundaCarga.metricas[0].valor).toBe(14)
  })

  it('consulta el resumen web del usuario y crea sus recuadros', async () => {
    const get = vi.fn().mockResolvedValue({ data: RESPUESTA_API })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerDashboard } = await import('@/modules/dashboard/services/dashboard.service')

    const resumen = await obtenerDashboard()

    expect(get).toHaveBeenCalledOnce()
    expect(get).toHaveBeenCalledWith('/usuarios/7/resumen-web')
    expect(resumen.metricas.map(({ id, valor }) => ({ id, valor }))).toEqual([
      { id: 'usuarios', valor: 42 },
      { id: 'empresas', valor: 3 },
      { id: 'ejercicios-activos', valor: 28 },
      { id: 'ejercicios-total', valor: 34 },
      { id: 'plan-empresa', valor: 'Plan Pro' },
    ])
  })

  it('consulta la tabla independiente de banners y normaliza todos sus registros', async () => {
    const get = vi.fn().mockResolvedValue({ data: RESPUESTA_BANNERS })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerBanners } = await import('@/modules/dashboard/services/dashboard.service')

    const banners = await obtenerBanners()

    expect(get).toHaveBeenCalledOnce()
    expect(get).toHaveBeenCalledWith('/banners')
    expect(banners).toEqual([
      {
        imagenUrl: '/storage/banners/inicio.webp',
        contenido: 'Entrena con propósito',
        textoBoton: 'Conocer más',
        enlaceBoton: 'https://gymbros.test/planes',
      },
      {
        imagenUrl: '/storage/banners/planes.webp',
        contenido: 'Planes para tu gimnasio',
        textoBoton: 'Ver planes',
        enlaceBoton: '/planes',
      },
    ])
  })

  it('normaliza listas ausentes como vacías sin romper el estado vacío', async () => {
    const get = vi.fn().mockResolvedValue({ data: {} })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerDashboard } = await import('@/modules/dashboard/services/dashboard.service')

    const resumen = await obtenerDashboard()

    expect(resumen.metricas.map((metrica) => metrica.id)).toEqual([
      'usuarios',
      'empresas',
      'plan-empresa',
    ])
    expect(resumen.progreso.etiquetas).toEqual([])
    expect(resumen.progreso.valores).toEqual([])
    expect(resumen.ejerciciosPopulares).toEqual([])
    expect(resumen.actividadReciente).toEqual([])
  })
})
