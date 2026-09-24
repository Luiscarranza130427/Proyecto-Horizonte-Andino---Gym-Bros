import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const EMPRESA_NUEVA = {
  nombre: 'Nova Fitness',
  gerente: 'Andrea Morales',
  ruc: '20987654321',
  correo: 'contacto@novafitness.test',
  telefono: '+51 987 654 321',
  region: 'Lima',
  direccion: 'Av. Javier Prado 1550, San Isidro',
  sitioWeb: 'https://novafitness.example',
  colorPrimario: '#e50914',
  colorSecundario: '#111111',
  estado: 'active',
}

async function cargarServicioMock() {
  vi.doMock('@/core/config/env', () => ({ USE_MOCKS: true }))
  vi.doMock('@/core/api/api', () => ({
    default: { get: vi.fn(), post: vi.fn(), put: vi.fn(), delete: vi.fn() },
  }))
  vi.useFakeTimers()
  vi.spyOn(Math, 'random').mockReturnValue(0)
  const servicio = await import('@/modules/empresas/services/empresas.service')
  await import('@/modules/empresas/mocks/empresas.mock')
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

describe('empresas.service en modo mock', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.useRealTimers()
  })

  it('lista 24 empresas ficticias con paginación y latencia acotada', async () => {
    const servicio = await cargarServicioMock()
    vi.spyOn(Math, 'random').mockReturnValue(0.999)
    const temporizador = vi.spyOn(globalThis, 'setTimeout')

    const peticion = servicio.obtenerEmpresas({ pagina: 2, porPagina: 5 })
    await asentarImportDinamico()

    expect(temporizador).toHaveBeenCalledWith(expect.any(Function), 600)
    const resultado = await completarPeticion(peticion, 600)
    expect(resultado.items).toHaveLength(5)
    expect(resultado.paginacion).toEqual({
      pagina: 2,
      ultimaPagina: 5,
      porPagina: 5,
      total: 24,
      desde: 6,
      hasta: 10,
    })
    expect(resultado.items[0]).toEqual(
      expect.objectContaining({
        id: expect.any(Number),
        nombre: expect.any(String),
        estado: expect.stringMatching(/^(active|inactive)$/),
        usuarios: expect.any(Number),
      }),
    )
  })

  it('busca por texto, filtra por estado y conserva metadatos coherentes', async () => {
    const servicio = await cargarServicioMock()

    const busqueda = servicio.obtenerEmpresas({ busqueda: 'Power Gym', estado: 'active' })
    const resultado = await completarPeticion(busqueda)
    expect(resultado.items).toHaveLength(1)
    expect(resultado.items[0].nombre).toBe('Power Gym')

    const inactivas = servicio.obtenerEmpresas({ estado: 'inactive', porPagina: 24 })
    const resultadoInactivas = await completarPeticion(inactivas)
    expect(resultadoInactivas.items).not.toHaveLength(0)
    expect(resultadoInactivas.items.every(({ estado }) => estado === 'inactive')).toBe(true)
    expect(resultadoInactivas.paginacion.total).toBe(resultadoInactivas.items.length)
  })

  it('obtiene una empresa mediante una copia segura', async () => {
    const servicio = await cargarServicioMock()

    const primera = await completarPeticion(servicio.obtenerEmpresa(1))
    primera.nombre = 'Alterada desde la vista'
    const segunda = await completarPeticion(servicio.obtenerEmpresa(1))

    expect(segunda.nombre).toBe('Power Gym')
  })

  it('crea una empresa y la hace visible inmediatamente en el listado', async () => {
    const servicio = await cargarServicioMock()

    const creada = await completarPeticion(servicio.crearEmpresa(EMPRESA_NUEVA))
    expect(creada).toEqual(
      expect.objectContaining({
        id: 25,
        nombre: EMPRESA_NUEVA.nombre,
        estado: 'active',
        usuarios: 0,
        fechaRegistro: expect.stringMatching(/^\d{4}-\d{2}-\d{2}$/),
      }),
    )

    const listado = await completarPeticion(servicio.obtenerEmpresas({ busqueda: 'Nova Fitness' }))
    expect(listado.items).toHaveLength(1)
    expect(listado.items[0].id).toBe(creada.id)
  })

  it('actualiza parcialmente una empresa y persiste los cambios', async () => {
    const servicio = await cargarServicioMock()

    const actualizada = await completarPeticion(
      servicio.actualizarEmpresa(2, { gerente: 'Elena Suárez', usuarios: 71 }),
    )
    const recargada = await completarPeticion(servicio.obtenerEmpresa(2))

    expect(actualizada.gerente).toBe('Elena Suárez')
    expect(recargada.gerente).toBe('Elena Suárez')
    expect(recargada.usuarios).toBe(64)
    expect(recargada.nombre).toBe('Iron House')
  })

  it('desactiva una empresa sin eliminarla', async () => {
    const servicio = await cargarServicioMock()

    const desactivada = await completarPeticion(servicio.desactivarEmpresa(1))
    const recargada = await completarPeticion(servicio.obtenerEmpresa(1))

    expect(desactivada.estado).toBe('inactive')
    expect(recargada.estado).toBe('inactive')
  })

  it('rechaza correo y RUC duplicados con errores 422 por campo', async () => {
    const servicio = await cargarServicioMock()
    const existente = await completarPeticion(servicio.obtenerEmpresa(1))
    const peticion = servicio.crearEmpresa({
      ...EMPRESA_NUEVA,
      correo: existente.correo,
      ruc: existente.ruc,
    })
    const rechazo = expect(peticion).rejects.toMatchObject({
      status: 422,
      errors: {
        correo: ['Ya existe una empresa con este correo.'],
        ruc: ['Ya existe una empresa con este RUC.'],
      },
    })

    await vi.advanceTimersByTimeAsync(250)
    await rechazo
  })

  it('responde con 422 ante datos inválidos y con 404 ante ids inexistentes', async () => {
    const servicio = await cargarServicioMock()
    const invalida = servicio.crearEmpresa({})
    const rechazoValidacion = expect(invalida).rejects.toMatchObject({
      status: 422,
      errors: expect.objectContaining({ nombre: expect.any(Array), correo: expect.any(Array) }),
    })
    await vi.advanceTimersByTimeAsync(250)
    await rechazoValidacion

    const inexistente = servicio.obtenerEmpresa(999)
    const rechazoNoEncontrada = expect(inexistente).rejects.toMatchObject({ status: 404 })
    await vi.advanceTimersByTimeAsync(250)
    await rechazoNoEncontrada
  })

  it('mantiene el contrato de banners también en modo mock', async () => {
    const servicio = await cargarServicioMock()

    const peticion = servicio.obtenerBannersEmpresa(1)
    const banners = await completarPeticion(peticion)

    expect(banners).toHaveLength(3)
    expect(banners[0]).toEqual(
      expect.objectContaining({
        numero: 1,
        imagen: expect.any(String),
        imagenUrl: expect.any(String),
        enlace: expect.any(String),
      }),
    )
  })
})

describe('empresas.service con API Laravel', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('normaliza el listado paginado snake_case y los parámetros de consulta', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 7,
            nombre: 'Power Gym',
            gerente: 'Mariana Torres',
            ruc: '20100000001',
            correo: 'contacto@powergym.test',
            telefono: '+51 910000001',
            region: 'Lima',
            direccion: 'Av. Arequipa 1840',
            enlace_web: 'https://powergym.example',
            estado: 'active',
            cantidad_usuarios: 86,
            fecha_registro: '2024-01-15',
            logo_url: '/logos/power.svg',
            color_primario: '#e50914',
            color_secundario: '#111111',
            horario_inicio_lunes: '6.00',
            horario_fin_lunes: '22.00',
          },
        ],
        current_page: 2,
        last_page: 4,
        per_page: 5,
        total: 16,
        from: 6,
        to: 6,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerEmpresas } = await import('@/modules/empresas/services/empresas.service')

    const resultado = await obtenerEmpresas({
      busqueda: 'power',
      estado: 'active',
      pagina: 2,
      porPagina: 5,
    })

    expect(get).toHaveBeenCalledWith('/empresas', {
      params: { search: 'power', status: 'active', page: 2, per_page: 5 },
    })
    expect(resultado.items[0]).toEqual(
      expect.objectContaining({
        sitioWeb: 'https://powergym.example',
        estado: 'active',
        usuarios: 86,
        fechaRegistro: '2024-01-15',
        colorPrimario: '#e50914',
        horario_inicio_lunes: '06:00',
        horario_fin_lunes: '22:00',
      }),
    )
    expect(resultado.paginacion).toEqual({
      pagina: 2,
      ultimaPagina: 4,
      porPagina: 5,
      total: 16,
      desde: 6,
      hasta: 6,
    })
  })

  it('usa los endpoints provisionales y serializa payloads camelCase a snake_case', async () => {
    const empresaApi = {
      id: 30,
      ...EMPRESA_NUEVA,
      sitio_web: EMPRESA_NUEVA.sitioWeb,
      logo_url: '/logos/nova.svg',
      color_primario: EMPRESA_NUEVA.colorPrimario,
      color_secundario: EMPRESA_NUEVA.colorSecundario,
      estado: 'active',
      usuarios_count: 0,
      fecha_registro: '2025-02-01',
    }
    const get = vi.fn().mockResolvedValue({ data: { data: empresaApi } })
    const post = vi.fn().mockResolvedValue({ data: { data: empresaApi } })
    const put = vi
      .fn()
      .mockResolvedValue({ data: { data: { ...empresaApi, gerente: 'Nueva Gerente' } } })
    const eliminar = vi.fn().mockResolvedValue({ data: null })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get, post, put, delete: eliminar } }))
    const servicio = await import('@/modules/empresas/services/empresas.service')

    await servicio.obtenerEmpresa(30)
    await servicio.crearEmpresa(EMPRESA_NUEVA)
    await servicio.actualizarEmpresa(30, {
      gerente: 'Nueva Gerente',
      sitioWeb: 'https://nova.example',
      estado: 'inactive',
      horario_inicio_lunes: '06:00',
      horario_fin_lunes: '22:00',
      usuarios: 999,
      fechaRegistro: '2020-01-01',
    })
    put.mockResolvedValueOnce({ data: { data: { ...empresaApi, estado: 0 } } })
    const desactivada = await servicio.desactivarEmpresa(30)

    expect(get).toHaveBeenCalledWith('/empresas/30')
    expect(post).toHaveBeenCalledWith(
      '/empresas',
      expect.objectContaining({
        enlace_web: EMPRESA_NUEVA.sitioWeb,
        color_1: EMPRESA_NUEVA.colorPrimario,
        nombre_gerente: EMPRESA_NUEVA.gerente,
      }),
    )
    expect(put).toHaveBeenCalledWith('/empresas/30', {
      nombre_gerente: 'Nueva Gerente',
      enlace_web: 'https://nova.example',
      estado: 0,
      horario_inicio_lunes: '06.00',
      horario_fin_lunes: '22.00',
    })
    expect(put).toHaveBeenLastCalledWith('/empresas/30', { estado: 0 })
    expect(eliminar).not.toHaveBeenCalled()
    expect(desactivada).toEqual(expect.objectContaining({ id: 30, estado: 'inactive' }))
  })

  it('ofrece solo planes activos y envía el plan sin fechas al crear con imágenes', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [true, 1, '1', false, 0, '0'].map((activo, id) => ({
          id,
          nombre: `Plan ${id}`,
          activo,
        })),
      },
    })
    const post = vi
      .fn()
      .mockResolvedValue({ status: 201, data: { data: { id: 7, suscripcion: { id: 9 } } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get, post } }))
    const servicio = await import('@/modules/empresas/services/empresas.service')
    expect((await servicio.obtenerPlanesAsignables()).map((plan) => plan.id)).toEqual([0, 1, 2])
    const empresa = await servicio.crearEmpresa({
      ...EMPRESA_NUEVA,
      id_planes: 2,
      logoUrl: 'data:image/webp;base64,AQID',
    })
    expect(post.mock.calls[0][0]).toBe('/empresas')
    expect(post.mock.calls[0][1].get('id_planes')).toBe('2')
    expect(post.mock.calls[0][1].has('fecha_registro')).toBe(false)
    expect(empresa.suscripcion).toEqual({ id: 9 })
  })

  it('elimina por DELETE y acepta la respuesta sin contenido', async () => {
    const eliminar = vi.fn().mockResolvedValue({ status: 204 })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { delete: eliminar } }))
    const { eliminarEmpresa } = await import('@/modules/empresas/services/empresas.service')
    await expect(eliminarEmpresa(30)).resolves.toBeUndefined()
    expect(eliminar).toHaveBeenCalledExactlyOnceWith('/empresas/30', {
      data: { confirmar_eliminacion: true },
    })
  })

  it('filtra suscripciones usando el campo de Laravel independientemente del estado manual', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          { id: 1, estado: 0, estado_suscripcion: 'Activo' },
          { id: 2, estado: 1, estado_suscripcion: 'Por Vencer' },
          { id: 3, estado: 1 },
        ],
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerEmpresas } = await import('@/modules/empresas/services/empresas.service')
    const todos = await obtenerEmpresas()
    expect(todos.items.map((item) => item.estado_suscripcion)).toEqual([
      'Activo',
      'Por Vencer',
      null,
    ])
    const filtrados = await obtenerEmpresas({ estado_suscripcion: 'Activo' })
    expect(filtrados.items).toHaveLength(1)
    expect(filtrados.items[0]).toMatchObject({
      id: 1,
      estado: 'inactive',
      estado_suscripcion: 'Activo',
    })
    expect(filtrados.paginacion.total).toBe(1)
    expect(get).toHaveBeenLastCalledWith('/empresas', {
      params: expect.objectContaining({ estado_suscripcion: 'Activo' }),
    })
  })

  it('respeta cantidad_usuarios cero aunque haya valores antiguos y conserva los ausentes', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          { id: 1, cantidad_usuarios: 0, usuarios_count: 9 },
          { id: 2, cantidad_usuarios: '12' },
          { id: 3 },
        ],
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerEmpresas } = await import('@/modules/empresas/services/empresas.service')
    const { items } = await obtenerEmpresas()
    expect(items.map((empresa) => empresa.usuarios)).toEqual([0, 12, null])
  })

  it('envía el logo como archivo multipart y conserva la ruta devuelta', async () => {
    const post = vi
      .fn()
      .mockResolvedValue({ data: { id_empresa: 30, logo_url: '/storage/empresas/logo.webp' } })
    const put = vi
      .fn()
      .mockResolvedValue({ data: { data: { id: 30, logo: '/storage/empresas/logo.webp' } } })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put, post } }))
    const { actualizarEmpresa } = await import('@/modules/empresas/services/empresas.service')
    const resultado = await actualizarEmpresa(30, {
      logoUrl: 'data:image/webp;base64,AQID',
      colorPrimario: '#112233',
    })
    const [ruta, formulario, opciones] = post.mock.calls[0]
    expect(ruta).toBe('/empresas/30/logo')
    expect(formulario).toBeInstanceOf(FormData)
    expect(formulario.get('logo').type).toBe('image/webp')
    expect(formulario.get('logo').size).toBe(3)
    expect(put).toHaveBeenCalledWith('/empresas/30/personalizacion', { color_1: '#112233' })
    expect(put).not.toHaveBeenCalledWith('/empresas/30', expect.anything())
    expect(opciones.headers['Content-Type']).toBeUndefined()
    expect(resultado.logoUrl).toContain('/storage/empresas/logo.webp')
  })

  it('guarda solo colores en personalizacion sin reenviar el logo existente', async () => {
    const put = vi.fn().mockResolvedValue({ data: { data: { id: 30, color_1: '#112233' } } })
    const post = vi.fn()
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put, post } }))
    const { actualizarEmpresa } = await import('@/modules/empresas/services/empresas.service')
    await actualizarEmpresa(30, {
      logoUrl: '/storage/empresas/logo.webp',
      colorPrimario: '#112233',
    })
    expect(put).toHaveBeenCalledExactlyOnceWith('/empresas/30/personalizacion', {
      color_1: '#112233',
    })
    expect(post).not.toHaveBeenCalled()
  })

  it('traduce a camelCase los campos de un error 422 de Laravel', async () => {
    const post = vi.fn().mockRejectedValue({
      status: 422,
      message: 'Los datos no son válidos.',
      errors: {
        manager_name: ['El gerente es obligatorio.'],
        email: ['El correo ya existe.'],
        sitio_web: ['La URL no es válida.'],
        color_primario: ['El color no es válido.'],
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post } }))
    const { crearEmpresa } = await import('@/modules/empresas/services/empresas.service')

    await expect(crearEmpresa(EMPRESA_NUEVA)).rejects.toMatchObject({
      name: 'HttpError',
      status: 422,
      errors: {
        gerente: ['El gerente es obligatorio.'],
        correo: ['El correo ya existe.'],
        sitioWeb: ['La URL no es válida.'],
        colorPrimario: ['El color no es válido.'],
      },
    })
  })
})

describe('banners de la empresa', () => {
  beforeEach(() => {
    vi.resetModules()
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  /*
   * LA PRUEBA QUE IMPORTA.
   *
   * `updateBanners` de Laravel asigna `$request->banner_1` y sus cinco hermanos
   * sin comprobar si vinieron en la petición: lo que no se envía se guarda como
   * `null`. Un envío parcial no actualiza un banner —borra los otros dos y sus
   * tres enlaces—. Ya ocurrió una vez contra datos reales.
   */
  it('envía SIEMPRE los seis campos, aunque sólo cambie uno', async () => {
    const put = vi.fn().mockResolvedValue({ data: {} })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { guardarBannersEmpresa } = await import('@/modules/empresas/services/empresas.service')

    // Sólo se toca el enlace del segundo banner; las imágenes ya están guardadas.
    await guardarBannersEmpresa(7, [
      { numero: 1, imagen: 'empresas/uno.webp', enlace: 'https://uno.test' },
      { numero: 2, imagen: 'empresas/dos.webp', enlace: 'https://dos.test' },
      { numero: 3, imagen: '', enlace: '' },
    ])

    const enviado = put.mock.calls[0][1]
    expect(put).toHaveBeenCalledWith('/empresa/banners/7', expect.any(Object))
    expect(Object.keys(enviado).sort()).toEqual([
      'banner_1',
      'banner_2',
      'banner_3',
      'link_boton_1',
      'link_boton_2',
      'link_boton_3',
    ])
    expect(enviado.banner_1).toBe('empresas/uno.webp')
    expect(enviado.link_boton_2).toBe('https://dos.test')
    // El hueco vacío viaja como null explícito, no ausente.
    expect(enviado.banner_3).toBeNull()
    expect(enviado.link_boton_3).toBeNull()
  })

  it('sube una imagen nueva como archivo a /personalizacion, no como texto data:', async () => {
    const post = vi.fn().mockResolvedValue({
      data: { data: { banner_1: 'empresas/nuevo.webp', banner_2: 'empresas/dos.webp' } },
    })
    const put = vi.fn()
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { post, put } }))
    const { guardarBannersEmpresa } = await import('@/modules/empresas/services/empresas.service')

    const banners = await guardarBannersEmpresa(7, [
      { numero: 1, imagen: 'data:image/webp;base64,AAAA', enlace: 'https://uno.test' },
      { numero: 2, imagen: 'empresas/dos.webp', enlace: '' },
      { numero: 3, imagen: '', enlace: '' },
    ])

    // La columna es varchar(300): una cadena data: de cientos de KB no cabe.
    expect(put).not.toHaveBeenCalled()
    const [url, formulario] = post.mock.calls[0]
    expect(url).toBe('/empresas/7/personalizacion')
    expect(formulario.get('_method')).toBe('PUT')
    expect(formulario.get('banner_1')).toBeInstanceOf(Blob)
    expect(formulario.get('banner_1').type).toBe('image/webp')
    expect(formulario.get('banner_2')).toBe('empresas/dos.webp')
    expect(formulario.get('banner_3')).toBe('')
    expect(formulario.get('link_boton_1')).toBe('https://uno.test')
    expect(banners[0].imagen).toBe('empresas/nuevo.webp')
  })

  it('normaliza los tres huecos aunque el backend devuelva nulos', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        banner_1: 'banners/promo.webp',
        banner_2: null,
        banner_3: null,
        link_boton_1: 'https://gymbros.pe/promo',
        link_boton_2: null,
        link_boton_3: null,
      },
    })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { get } }))
    const { obtenerBannersEmpresa } = await import('@/modules/empresas/services/empresas.service')

    const banners = await obtenerBannersEmpresa(1)

    // Siempre tres huecos: la interfaz pinta tres marcos pase lo que pase.
    expect(banners).toHaveLength(3)
    expect(banners.map((b) => b.numero)).toEqual([1, 2, 3])
    expect(banners[0].enlace).toBe('https://gymbros.pe/promo')
    // Un nulo se convierte en cadena vacía: un `null` en un `value` de input
    // pinta la palabra «null» en el campo.
    expect(banners[1].imagen).toBe('')
    expect(banners[1].enlace).toBe('')
  })

  it('recorta los espacios del enlace y guarda null si queda vacío', async () => {
    const put = vi.fn().mockResolvedValue({ data: {} })
    vi.doMock('@/core/config/env', () => ({ USE_MOCKS: false }))
    vi.doMock('@/core/api/api', () => ({ default: { put } }))
    const { guardarBannersEmpresa } = await import('@/modules/empresas/services/empresas.service')

    await guardarBannersEmpresa(1, [
      { numero: 1, imagen: 'x', enlace: '  https://gymbros.pe  ' },
      { numero: 2, imagen: 'y', enlace: '   ' },
      { numero: 3, imagen: '', enlace: '' },
    ])

    const enviado = put.mock.calls[0][1]
    expect(enviado.link_boton_1).toBe('https://gymbros.pe')
    expect(enviado.link_boton_2).toBeNull()
  })
})
