import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const NOTIFICACION_NUEVA = {
  tipo: 'recordatorio',
  titulo: 'Evaluación de composición corporal',
  mensaje: 'Recuerda registrar tus métricas antes del fin de semana.',
  programar: false,
}

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({ default: { get: vi.fn(), post: vi.fn() } }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/notificaciones/services/notificaciones.service')
  const mock = await import('@/modules/notificaciones/mocks/notificaciones.mock')
  mock.reiniciarNotificacionesMock()
  return servicio
}

async function completarPeticion(peticion) {
  await vi.advanceTimersByTimeAsync(0)
  await vi.advanceTimersByTimeAsync(350)
  return peticion
}

describe('notificaciones.service en modo mock', () => {
  beforeEach(() => vi.resetModules())

  afterEach(() => {
    vi.useRealTimers()
    vi.restoreAllMocks()
  })

  it('lista notificaciones programadas con fecha y estado no enviado', async () => {
    const servicio = await cargarServicioMock()

    const programadas = await completarPeticion(servicio.obtenerNotificacionesProgramadas())

    expect(programadas.length).toBeGreaterThan(0)
    expect(programadas[0]).toMatchObject({
      id: expect.any(Number),
      titulo: expect.any(String),
      mensaje: expect.any(String),
      enviada: false,
      fechaEnvio: expect.any(String),
    })
  })

  it('lista historial de notificaciones enviadas con paginación', async () => {
    const servicio = await cargarServicioMock()

    const { items, paginacion } = await completarPeticion(
      servicio.obtenerNotificacionesEnviadas({ porPagina: 2 }),
    )

    expect(items).toHaveLength(2)
    expect(paginacion.total).toBeGreaterThan(items.length)
    expect(items.every((n) => n.enviada)).toBe(true)
  })

  it('crea una notificación inmediata con enviada en true', async () => {
    const servicio = await cargarServicioMock()

    const creada = await completarPeticion(servicio.crearNotificacion(NOTIFICACION_NUEVA))

    expect(creada.id).toBeDefined()
    expect(creada.titulo).toBe(NOTIFICACION_NUEVA.titulo)
    expect(creada.enviada).toBe(true)
  })

  it('crea una notificación programada con fecha futura', async () => {
    const servicio = await cargarServicioMock()

    const fechaFutura = new Date(Date.now() + 86400000).toISOString()
    const creada = await completarPeticion(
      servicio.crearNotificacion({
        ...NOTIFICACION_NUEVA,
        programar: true,
        fechaEnvio: fechaFutura,
      }),
    )

    expect(creada.enviada).toBe(false)
    expect(creada.fechaEnvio).toBe(fechaFutura)
  })

  it('fuerza el envío inmediato de una notificación programada', async () => {
    const servicio = await cargarServicioMock()

    const programadas = await completarPeticion(servicio.obtenerNotificacionesProgramadas())
    const id = programadas[0].id

    const enviada = await completarPeticion(servicio.enviarNotificacionAhora(id))
    expect(enviada.enviada).toBe(true)
  })

  it('elimina una notificación existente', async () => {
    const servicio = await cargarServicioMock()

    const programadasAntes = await completarPeticion(servicio.obtenerNotificacionesProgramadas())
    const totalAntes = programadasAntes.length
    const id = programadasAntes[0].id

    await completarPeticion(servicio.eliminarNotificacion(id))

    const programadasDespues = await completarPeticion(servicio.obtenerNotificacionesProgramadas())
    expect(programadasDespues.length).toBe(totalAntes - 1)
  })
})

describe('notificaciones.service con API', () => {
  beforeEach(() => vi.resetModules())

  afterEach(() => vi.restoreAllMocks())

  it('cuenta las notificaciones no leídas devueltas por GET /notificaciones/activas', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          { id: 1, leida: 0 },
          { id: 2, leida: false },
          { id: 3, leida: 1 },
        ],
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { contarNoLeidas } =
      await import('@/modules/notificaciones/services/notificaciones.service')

    await expect(contarNoLeidas()).resolves.toBe(2)
    expect(get).toHaveBeenCalledOnce()
    expect(get).toHaveBeenCalledWith('/notificaciones/activas')
  })

  it('envía contenido y alcance al backend sin resolver usuarios en Vue', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 9, enviada: true } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearNotificacion } =
      await import('@/modules/notificaciones/services/notificaciones.service')

    await crearNotificacion({
      alcance: 'empresa',
      idEmpresas: 2,
      tipo: 'recordatorio',
      titulo: 'Aviso',
      mensaje: 'Mensaje para la empresa.',
      programar: false,
      fechaEnvio: null,
    })

    const payload = post.mock.calls[0][1]
    expect(payload).toMatchObject({
      alcance: 'empresa',
      id_empresas: 2,
      titulo: 'Aviso',
      mensaje: 'Mensaje para la empresa.',
    })
    expect(payload).not.toHaveProperty('id_usuarios')
  })
})
