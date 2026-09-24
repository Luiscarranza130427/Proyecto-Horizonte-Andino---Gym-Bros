import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

const EMPRESAS = [
  { id: 1, nombre: 'Titan Gym', estado: 'active' },
  { id: 2, nombre: 'Segundo Fitness', estado: 'active' },
]

const USUARIOS_API = [
  {
    id: 1,
    nombre: null,
    apellidos: 'Pérez Ramírez',
    correo: 'juan.perez@gmail.com',
    tipo_documento: 'DNI',
    numero_documento: '70123456',
    telefono: '987654321',
    direccion: 'Jr. Los Pinos 123',
    foto_perfil: 'usuarios/juan.webp',
    fecha_registro: '2026-01-10',
    fecha_nacimiento: '1998-05-15',
    asistencia_semanal: '2026-08-24 08:30:00',
    tipo_usuario: 'Usuario',
    estado: 1,
    id_empresas: 1,
  },
  {
    id: 2,
    nombre: 'Ana',
    apellidos: 'Torres Flores',
    correo: 'ana.torres@segundo.pe',
    tipo_documento: 'Pasaporte',
    numero_documento: 'PE123456',
    telefono: '983210987',
    fecha_registro: '2026-01-15',
    tipo_usuario: 'Empresa',
    estado: 0,
    id_empresas: 2,
  },
  {
    id: 3,
    nombre: 'Luis',
    apellidos: 'Vargas Díaz',
    correo: 'luis.vargas@segundo.pe',
    tipo_documento: 'DNI',
    numero_documento: '75678901',
    telefono: '982109876',
    fecha_registro: '2026-02-01',
    tipo_usuario: 'Entrenador',
    estado: 1,
    id_empresas: 2,
  },
]

async function cargarServicio({
  get = vi.fn().mockResolvedValue({ data: { data: USUARIOS_API } }),
  post = vi.fn(),
  put = vi.fn(),
  eliminar = vi.fn(),
} = {}) {
  vi.doMock('@/core/api/api', () => ({ default: { get, post, put, delete: eliminar } }))
  vi.doMock('@/modules/empresas/services/empresas.service', () => ({
    obtenerEmpresas: vi.fn().mockResolvedValue({ items: EMPRESAS }),
  }))
  const servicio = await import('@/modules/usuarios/services/usuarios.service')
  return { servicio, get, post, put, eliminar }
}

describe('usuarios.service con API Laravel', () => {
  it.each([
    ['dni', 'DNI'],
    ['passport', 'PASAPORTE'],
    ['other', 'OTRO'],
  ])(
    'envía el documento %s con el valor exacto aceptado por Laravel',
    async (tipoDocumento, esperado) => {
      const put = vi.fn().mockResolvedValue({ data: { data: USUARIOS_API[0] } })
      const { servicio } = await cargarServicio({ put })
      await servicio.actualizarUsuario(1, { tipoDocumento })
      expect(put).toHaveBeenCalledWith('/usuarios/1', { tipo_documento: esperado })
    },
  )
  it('sube la foto como archivo y utiliza la ruta devuelta por Laravel', async () => {
    const put = vi.fn().mockResolvedValue({ data: { data: USUARIOS_API[0] } })
    const post = vi.fn().mockResolvedValue({
      data: {
        foto_perfil: 'usuario/nueva.webp',
        foto_url: 'http://localhost/storage/usuario/nueva.webp',
      },
    })
    const { servicio } = await cargarServicio({ put, post })
    const resultado = await servicio.actualizarUsuario(1, {
      fotoPerfil: 'data:image/webp;base64,AQID',
    })
    expect(put).not.toHaveBeenCalled()
    expect(post.mock.calls[0][0]).toBe('/usuarios/1/foto-perfil')
    expect(post.mock.calls[0][1].get('foto_perfil').size).toBe(3)
    expect(post.mock.calls[0][1].get('foto_perfil').type).toBe('image/webp')
    expect(resultado.fotoPerfil).toBe('http://localhost/storage/usuario/nueva.webp')
  })
  beforeEach(() => {
    vi.resetModules()
    sessionStorage.clear()
  })

  afterEach(() => {
    sessionStorage.clear()
    vi.restoreAllMocks()
    vi.doUnmock('@/core/api/api')
    vi.doUnmock('@/modules/empresas/services/empresas.service')
  })

  it('normaliza la respuesta real y completa la empresa asociada', async () => {
    const { servicio, get } = await cargarServicio()

    const resultado = await servicio.obtenerUsuarios({ pagina: 1, porPagina: 10 })

    expect(get).toHaveBeenCalledWith('/usuarios', {
      params: expect.objectContaining({ page: 1, per_page: 10 }),
    })
    expect(resultado.items[0]).toEqual(
      expect.objectContaining({
        nombre: '',
        apellido: 'Pérez Ramírez',
        tipoDocumento: 'dni',
        rol: 'member',
        estado: 'active',
        empresa: { id: 1, nombre: 'Titan Gym' },
        actividad: expect.objectContaining({ ultimaActividad: '2026-08-24 08:30:00' }),
      }),
    )
    expect(resultado.items[0].fotoPerfil).toContain('/storage/usuarios/juan.webp')
  })

  it('limita el listado y las opciones a la empresa de la sesión', async () => {
    sessionStorage.setItem(
      'gym_bros_session',
      JSON.stringify({ usuario: { id: 5, rol: 'Empresa', tenantId: 2 } }),
    )
    const { servicio, get } = await cargarServicio()

    const resultado = await servicio.obtenerUsuarios()
    const opciones = await servicio.obtenerOpcionesEmpresas()

    expect(get).toHaveBeenCalledWith(
      '/usuarios',
      expect.objectContaining({
        params: expect.objectContaining({ id_empresas: 2 }),
      }),
    )
    expect(resultado.items).toHaveLength(2)
    expect(resultado.items.every((item) => item.empresa.id === 2)).toBe(true)
    expect(opciones).toEqual([{ id: 2, nombre: 'Segundo Fitness', estado: 'active' }])
  })

  it('aplica búsqueda, filtros y paginación cuando Laravel devuelve un arreglo completo', async () => {
    const { servicio } = await cargarServicio()

    const porEmpresa = await servicio.obtenerUsuarios({ empresaId: 2, pagina: 1, porPagina: 1 })
    expect(porEmpresa.items).toHaveLength(1)
    expect(porEmpresa.items[0].id).toBe(2)
    expect(porEmpresa.paginacion).toEqual({
      pagina: 1,
      ultimaPagina: 2,
      porPagina: 1,
      total: 2,
      desde: 1,
      hasta: 1,
    })

    const buscado = await servicio.obtenerUsuarios({ busqueda: 'vargas diaz', rol: 'trainer' })
    expect(buscado.items.map(({ id }) => id)).toEqual([3])

    const inactivo = await servicio.obtenerUsuarios({ estado: 'inactive' })
    expect(inactivo.items.map(({ id }) => id)).toEqual([2])
  })

  it('obtiene el detalle desde el listado mientras no exista GET /usuarios/:id', async () => {
    const { servicio, get } = await cargarServicio()

    await expect(servicio.obtenerUsuario(3)).resolves.toEqual(
      expect.objectContaining({ id: 3, nombre: 'Luis', rol: 'trainer' }),
    )
    await expect(servicio.obtenerUsuario(999)).rejects.toMatchObject({ status: 404 })
    expect(get).not.toHaveBeenCalledWith('/usuarios/3')
  })

  it('serializa los valores del formulario al vocabulario actual de Laravel', async () => {
    const respuesta = { ...USUARIOS_API[0], id: 9, nombre: 'Rosa', apellidos: 'Quispe' }
    const post = vi.fn().mockResolvedValue({ data: { data: respuesta } })
    const put = vi.fn().mockResolvedValue({ data: { data: respuesta } })
    const eliminar = vi.fn().mockResolvedValue({ data: null })
    const { servicio } = await cargarServicio({ post, put, eliminar })
    const payload = {
      nombre: 'Rosa',
      apellido: 'Quispe',
      correo: 'rosa@example.com',
      tipoDocumento: 'dni',
      numeroDocumento: '79999999',
      rol: 'member',
      estado: 'active',
      empresaId: 1,
    }

    await servicio.crearUsuario(payload)
    await servicio.actualizarUsuario(9, { rol: 'trainer', estado: 'inactive', genero: 'Mujer' })
    await servicio.desactivarUsuario(9)

    expect(post).toHaveBeenCalledWith('/usuarios', {
      nombres: 'Rosa',
      apellidos: 'Quispe',
      correo: 'rosa@example.com',
      tipo_documento: 'DNI',
      numero_documento: '79999999',
      tipo_usuario: 'Usuario',
      estado: 1,
      id_empresas: 1,
    })
    expect(put).toHaveBeenCalledWith('/usuarios/9', {
      genero: 'Mujer',
      tipo_usuario: 'Entrenador',
      estado: 0,
    })
    expect(put).toHaveBeenCalledWith('/usuarios/9/estado', { estado: 0 })
    expect(eliminar).not.toHaveBeenCalled()
  })

  it('informa con claridad cuando Laravel todavía no publica una escritura', async () => {
    const post = vi.fn().mockRejectedValue({ status: 405, message: 'Method Not Allowed' })
    const { servicio } = await cargarServicio({ post })

    await expect(servicio.crearUsuario({ nombre: 'Rosa' })).rejects.toMatchObject({
      status: 501,
      message: expect.stringContaining('aún no permite crear usuarios'),
    })
  })

  it('solicita la exportación como blob sin enviar filtros ni alcance', async () => {
    const get = vi.fn().mockResolvedValue({ data: new Blob(['id,nombre']) })
    const { servicio } = await cargarServicio({ get })

    await servicio.exportarUsuarios()

    expect(get).toHaveBeenCalledWith('/usuarios/exportar', { responseType: 'blob' })
  })

  it('traduce errores 422 y distingue el historial ausente del vacío', async () => {
    const post = vi.fn().mockRejectedValue({
      status: 422,
      message: 'Datos inválidos.',
      errors: {
        apellidos: ['Los apellidos son obligatorios.'],
        tipo_usuario: ['Selecciona un rol válido.'],
      },
    })
    const get = vi.fn().mockRejectedValue({ status: 404, message: 'Not Found' })
    const { servicio } = await cargarServicio({ get, post })

    await expect(servicio.crearUsuario({})).rejects.toMatchObject({
      status: 422,
      errors: {
        apellido: ['Los apellidos son obligatorios.'],
        rol: ['Selecciona un rol válido.'],
      },
    })
    /*
     * `null`, no `[]`. Devolviendo una colección vacía la ficha no puede
     * distinguir «este usuario no tiene cambios» de «la API no tiene el
     * endpoint», y acaba afirmando lo primero para siempre.
     */
    await expect(servicio.obtenerHistorialUsuario(1)).resolves.toBeNull()
  })

  it('un historial vacío de verdad sí es una colección vacía', async () => {
    // El endpoint existe y responde sin eventos: eso SÍ es «sin cambios», y la
    // ficha debe mostrarlo en lugar de esconder la sección.
    const get = vi.fn().mockResolvedValue({ data: [] })
    const { servicio } = await cargarServicio({ get })

    await expect(servicio.obtenerHistorialUsuario(1)).resolves.toEqual([])
  })
})
