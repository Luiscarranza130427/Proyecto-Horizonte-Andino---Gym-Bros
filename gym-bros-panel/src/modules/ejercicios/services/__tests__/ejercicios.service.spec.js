import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const EJERCICIO_NUEVO = {
  nombre: 'Hip thrust',
  tipo: 'fuerza',
  instrucciones: 'Empuja con control.',
  nivel: 'intermedio',
  equipamiento: 'barra',
  descripcion: 'Extensión de cadera con apoyo escapular.',
  imagenEjercicio: 'ejercicios/hip-thrust.webp',
  idGruposMusculares: 1,
  estado: 'active',
}

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({
    default: { get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() },
  }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/ejercicios/services/ejercicios.service')
  await import('@/modules/ejercicios/mocks/ejercicios.mock')
  return servicio
}

async function asentarImportDinamico() {
  await vi.advanceTimersByTimeAsync(0)
}

async function completarPeticion(peticion, latencia = 250) {
  await asentarImportDinamico()
  await vi.advanceTimersByTimeAsync(latencia)
  return peticion
}

describe('ejercicios.service en modo mock', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it('lista el catálogo con paginación coherente', async () => {
    const servicio = await cargarServicioMock()

    const resultado = await completarPeticion(servicio.obtenerEjercicios({ porPagina: 8 }))

    expect(resultado.items).toHaveLength(8)
    expect(resultado.paginacion).toEqual({
      pagina: 1,
      ultimaPagina: 4,
      porPagina: 8,
      total: 30,
      desde: 1,
      hasta: 8,
    })
    expect(resultado.items[0]).toEqual(
      expect.objectContaining({
        id: expect.any(Number),
        nombre: expect.any(String),
        categoria: expect.any(String),
        nivel: expect.any(String),
        equipo: expect.any(String),
        estado: expect.stringMatching(/^(active|inactive)$/),
      }),
    )
  })

  it('busca sin distinguir tildes ni mayúsculas', async () => {
    const servicio = await cargarServicioMock()

    const resultado = await completarPeticion(servicio.obtenerEjercicios({ busqueda: 'JALON' }))

    expect(resultado.items).toHaveLength(1)
    expect(resultado.items[0].nombre).toBe('Jalón al pecho')
  })

  it('combina los filtros de categoría, nivel y equipo', async () => {
    const servicio = await cargarServicioMock()

    const resultado = await completarPeticion(
      servicio.obtenerEjercicios({ categoria: 'piernas', nivel: 'principiante', porPagina: 30 }),
    )

    expect(resultado.items).not.toHaveLength(0)
    expect(
      resultado.items.every((e) => e.categoria === 'piernas' && e.nivel === 'principiante'),
    ).toBe(true)

    const conBarra = await completarPeticion(
      servicio.obtenerEjercicios({ equipo: 'barra', porPagina: 30 }),
    )
    expect(conBarra.items.every((e) => e.equipo === 'barra')).toBe(true)
    expect(conBarra.paginacion.total).toBe(conBarra.items.length)
  })

  it('entrega una copia segura: mutarla no altera el catálogo', async () => {
    const servicio = await cargarServicioMock()

    const primera = await completarPeticion(servicio.obtenerEjercicio(1))
    primera.nombre = 'Alterado desde la vista'
    const segunda = await completarPeticion(servicio.obtenerEjercicio(1))

    expect(segunda.nombre).toBe('Press de banca')
  })

  it('crea un ejercicio y lo hace visible de inmediato', async () => {
    const servicio = await cargarServicioMock()

    const creado = await completarPeticion(servicio.crearEjercicio(EJERCICIO_NUEVO))
    expect(creado).toEqual(
      expect.objectContaining({
        id: 31,
        nombre: 'Hip thrust',
        tipo: 'fuerza',
        usos: 0,
        estado: 'active',
        fechaRegistro: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      }),
    )

    const listado = await completarPeticion(servicio.obtenerEjercicios({ busqueda: 'hip thrust' }))
    expect(listado.items).toHaveLength(1)
    expect(listado.items[0].id).toBe(creado.id)
  })

  it('rechaza un nombre duplicado con un 422 por campo', async () => {
    const servicio = await cargarServicioMock()

    const peticion = servicio.crearEjercicio({ ...EJERCICIO_NUEVO, nombre: 'jalon al pecho' })
    const rechazo = expect(peticion).rejects.toMatchObject({
      status: 422,
      errors: { nombre: ['Ya existe un ejercicio con este nombre.'] },
    })

    await asentarImportDinamico()
    await vi.advanceTimersByTimeAsync(250)
    await rechazo
  })

  it('rechaza valores fuera de catálogo con un 422 por campo', async () => {
    const servicio = await cargarServicioMock()

    const peticion = servicio.crearEjercicio({
      ...EJERCICIO_NUEVO,
      nombre: 'Ejercicio inventado',
      tipo: 'teletransporte',
      nivel: 'imposible',
    })
    const rechazo = expect(peticion).rejects.toMatchObject({
      status: 422,
      errors: expect.objectContaining({
        nivel: expect.any(Array),
      }),
    })

    await asentarImportDinamico()
    await vi.advanceTimersByTimeAsync(250)
    await rechazo
  })

  it('actualiza sólo lo editable y no deja tocar lo que calcula el backend', async () => {
    const servicio = await cargarServicioMock()

    const actualizado = await completarPeticion(
      servicio.actualizarEjercicio(1, {
        nivel: 'avanzado',
        usos: 9999,
        fechaRegistro: '2000-01-01',
      }),
    )

    expect(actualizado.nivel).toBe('avanzado')
    expect(actualizado.usos).not.toBe(9999)
    expect(actualizado.fechaRegistro).not.toBe('2000-01-01')

    const recargado = await completarPeticion(servicio.obtenerEjercicio(1))
    expect(recargado.nivel).toBe('avanzado')
  })

  it('desactiva sin eliminar', async () => {
    const servicio = await cargarServicioMock()

    const desactivado = await completarPeticion(servicio.desactivarEjercicio(2))
    const recargado = await completarPeticion(servicio.obtenerEjercicio(2))

    expect(desactivado.estado).toBe('inactive')
    expect(recargado.estado).toBe('inactive')
  })

  it('responde 404 ante un id inexistente', async () => {
    const servicio = await cargarServicioMock()

    const peticion = servicio.obtenerEjercicio(9999)
    const rechazo = expect(peticion).rejects.toMatchObject({ status: 404 })

    await asentarImportDinamico()
    await vi.advanceTimersByTimeAsync(250)
    await rechazo
  })
})

describe('ejercicios.service con API Laravel', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('normaliza el listado en snake_case y traduce los parámetros', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 7,
            name: 'Press de banca',
            category: 'pecho',
            tipo: 'fuerza',
            instrucciones: 'Mantén la espalda apoyada.',
            level: 'intermedio',
            equipment: 'barra',
            description: 'Empuje horizontal.',
            enlace_video: 'https://example.com/video',
            imagen_ejercicio: 'https://example.com/press.webp',
            series_sugeridas: 4,
            repeticiones_sugeridas: 8,
            usos_count: 154,
            status: 'active',
            estado_empresa: false,
            created_at: '2026-01-15',
          },
        ],
        current_page: 2,
        last_page: 3,
        per_page: 5,
        total: 12,
        from: 6,
        to: 6,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerEjercicios } = await import('@/modules/ejercicios/services/ejercicios.service')

    const resultado = await obtenerEjercicios({
      busqueda: 'press',
      categoria: 'pecho',
      nivel: 'intermedio',
      equipo: 'barra',
      estado: 'active',
      empresaId: 8,
      pagina: 2,
      porPagina: 5,
    })

    expect(get).toHaveBeenCalledWith('/ejercicios', {
      params: {
        search: 'press',
        category: 'pecho',
        level: 'intermedio',
        equipment: 'barra',
        status: 'active',
        id_empresas: 8,
        page: 2,
        per_page: 5,
      },
    })
    expect(resultado.items[0]).toEqual({
      id: 7,
      nombre: 'Press de banca',
      categoria: 'pecho',
      grupoMuscular: '',
      grupoMuscularTipo: '',
      idGruposMusculares: '',
      tipo: 'fuerza',
      nivel: 'intermedio',
      equipo: 'barra',
      imagen: 'https://example.com/press.webp',
      descripcion: 'Empuje horizontal.',
      instrucciones: 'Mantén la espalda apoyada.',
      enlaceVideo: 'https://example.com/video',
      seriesSugeridas: 4,
      repeticionesSugeridas: 8,
      usos: 154,
      estado: 'active',
      estadoEmpresa: 'inactive',
      fechaRegistro: '2026-01-15',
    })
    expect(resultado.paginacion).toEqual({
      pagina: 2,
      ultimaPagina: 3,
      porPagina: 5,
      total: 12,
      desde: 6,
      hasta: 6,
    })
  })

  it('traduce los campos de un 422 al vocabulario del formulario', async () => {
    const { HttpError } = await import('@/core/api/http-error')
    const post = vi.fn().mockRejectedValue(
      new HttpError(422, 'Revisa los datos introducidos.', {
        name: ['Ya existe.'],
        suggested_sets: ['Debe ser un entero.'],
      }),
    )
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearEjercicio } = await import('@/modules/ejercicios/services/ejercicios.service')

    await expect(crearEjercicio(EJERCICIO_NUEVO)).rejects.toMatchObject({
      status: 422,
      errors: {
        nombre: ['Ya existe.'],
        seriesSugeridas: ['Debe ser un entero.'],
      },
    })
  })

  it('envía sólo los campos editables, en el vocabulario del backend', async () => {
    const post = vi.fn().mockResolvedValue({ data: { id: 40 } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearEjercicio } = await import('@/modules/ejercicios/services/ejercicios.service')
    const imagen = new File(['x'], 'hip-thrust.webp', { type: 'image/webp' })

    await crearEjercicio({
      ...EJERCICIO_NUEVO,
      imagenEjercicio: imagen,
      usos: 500,
      fechaRegistro: '2000-01-01',
      id: 99,
    })

    // El alta viaja como multipart porque incluye la imagen.
    const [url, formulario] = post.mock.calls[0]
    expect(url).toBe('/ejercicios')
    expect(formulario).toBeInstanceOf(FormData)
    const { imagen_ejercicio: archivo, ...campos } = Object.fromEntries(formulario.entries())
    expect(campos).toEqual({
      nombre: 'Hip thrust',
      tipo: 'fuerza',
      instrucciones: 'Empuja con control.',
      nivel: 'intermedio',
      equipamiento: 'barra',
      descripcion: 'Extensión de cadera con apoyo escapular.',
      id_grupos_musculares: '1',
      estado: '1',
    })
    expect(archivo).toBeInstanceOf(File)
  })

  it('edita con POST y _method=PUT, sin imagen ni estado si el formulario no los trae', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 7, nombre: 'Press' } } })
    const put = vi.fn()
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post, put } }))
    const { actualizarEjercicio } = await import('@/modules/ejercicios/services/ejercicios.service')

    await actualizarEjercicio(7, { nombre: 'Press', imagenEjercicio: null })

    expect(put).not.toHaveBeenCalled()
    const [url, formulario] = post.mock.calls[0]
    expect(url).toBe('/ejercicios/7')
    const campos = Object.fromEntries(formulario.entries())
    expect(campos._method).toBe('PUT')
    expect(campos.nombre).toBe('Press')
    // Antes viajaban estado=0 (desactivaba el ejercicio) e imagen_ejercicio="undefined".
    expect(campos).not.toHaveProperty('estado')
    expect(campos).not.toHaveProperty('imagen_ejercicio')
  })

  it('actualiza el estado de la relación empresa-ejercicio con los IDs correctos', async () => {
    const put = vi.fn().mockResolvedValue({
      data: { message: 'Estado actualizado.', id_empresa: 8, id_ejercicio: 21, estado: false },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { actualizarEstadoEjercicioEmpresa } =
      await import('@/modules/ejercicios/services/ejercicios.service')

    await expect(actualizarEstadoEjercicioEmpresa(8, 21, false)).resolves.toEqual({
      estadoEmpresa: 'inactive',
      message: 'Estado actualizado.',
    })
    expect(put).toHaveBeenCalledWith('/empresas/8/ejercicios/21/estado', { estado: 0 })
  })

  it.each([422, 404, 500])(
    'conserva los errores HTTP %i de la relación por empresa',
    async (status) => {
      const put = vi.fn().mockRejectedValue({
        response: { status, data: { message: `Error ${status}.` } },
      })
      vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
      vi.doMock('@/core/api/api', () => ({ default: { put } }))
      const { actualizarEstadoEjercicioEmpresa } =
        await import('@/modules/ejercicios/services/ejercicios.service')

      await expect(actualizarEstadoEjercicioEmpresa(8, 21, true)).rejects.toMatchObject({
        status,
        message: `Error ${status}.`,
      })
    },
  )
})
