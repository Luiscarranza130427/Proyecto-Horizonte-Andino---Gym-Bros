import { beforeEach, describe, expect, it, vi } from 'vitest'

import api from '@/core/api/api'
import {
  iniciarSesion,
  restablecerContrasena,
  solicitarRestablecimientoContrasena,
} from '@/core/auth/auth.service'

vi.mock('@/core/api/api', () => ({ default: { post: vi.fn() } }))
vi.mock('@/core/config/env', () => ({ IS_DEV: false, USE_MOCKS: false }))

describe('auth.service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('envía el correo al endpoint de recuperación con JSON', async () => {
    vi.mocked(api.post).mockResolvedValue({
      data: { message: 'Si el correo está registrado, recibirás las instrucciones.' },
    })

    await expect(solicitarRestablecimientoContrasena(' Atleta@GymBros.test ')).resolves.toEqual({
      message: 'Si el correo está registrado, recibirás las instrucciones.',
    })

    expect(api.post).toHaveBeenCalledWith(
      '/auth/forgot-password',
      { correo: 'atleta@gymbros.test' },
      { headers: { Accept: 'application/json', 'Content-Type': 'application/json' } },
    )
  })

  it('obtiene token y usuario desde data.data de la respuesta de Laravel', async () => {
    vi.mocked(api.post).mockResolvedValue({
      data: {
        data: {
          token: 'token-real-del-backend',
          token_type: 'Bearer',
          usuario: {
            id: 9,
            nombre: 'Juan Pérez',
            correo: 'juan@gymbros.test',
            id_empresas: 3,
            tipo_usuario: 'Empresa',
          },
        },
      },
    })

    await expect(
      iniciarSesion({ correo: ' Juan@GymBros.test ', contrasena: 'secreto' }),
    ).resolves.toEqual({
      token: 'token-real-del-backend',
      usuario: {
        id: 9,
        nombre: 'Juan Pérez',
        nombres: '',
        apellidos: '',
        apodo: '',
        correo: 'juan@gymbros.test',
        rol: 'Empresa',
        tenantId: 3,
        foto: '',
      },
    })
  })

  it('compone el nombre completo con los campos reales de UsuarioResource', async () => {
    vi.mocked(api.post).mockResolvedValue({
      data: {
        data: {
          token: 'token-administrador',
          usuario: {
            id: 1,
            nombres: 'Juanito',
            apellidos: 'Perezz',
            apodo: 'Juan',
            correo: 'juan@gmail.com',
            id_empresas: 1,
            tipo_usuario: 'Administrador',
          },
        },
      },
    })

    await expect(iniciarSesion({ correo: 'juan@gmail.com', contrasena: '1234' })).resolves.toEqual({
      token: 'token-administrador',
      usuario: {
        id: 1,
        nombre: 'Juanito Perezz',
        nombres: 'Juanito',
        apellidos: 'Perezz',
        apodo: 'Juan',
        correo: 'juan@gmail.com',
        rol: 'Administrador',
        tenantId: 1,
        foto: '',
      },
    })
  })

  it('envía los datos del enlace al endpoint de restablecimiento', async () => {
    vi.mocked(api.post).mockResolvedValue({ data: { message: 'Contraseña actualizada.' } })
    const payload = {
      correo: 'atleta@gymbros.test',
      token: 'token-seguro',
      password: 'NuevaClave2026',
      password_confirmation: 'NuevaClave2026',
    }

    await expect(restablecerContrasena(payload)).resolves.toEqual({
      message: 'Contraseña actualizada.',
    })
    expect(api.post).toHaveBeenCalledWith('/auth/reset-password', payload, {
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
    })
  })
})

describe('cerrarSesion', () => {
  it('revoca el token en /auth/logout (antes llamaba a /logout, que no existe)', async () => {
    const { cerrarSesion } = await import('@/core/auth/auth.service')
    vi.mocked(api.post).mockResolvedValue({ data: { message: 'Sesion cerrada correctamente.' } })

    await cerrarSesion()

    expect(api.post).toHaveBeenCalledWith('/auth/logout')
  })

  it('no falla si la API no responde: la sesión local se cierra igual', async () => {
    const { cerrarSesion } = await import('@/core/auth/auth.service')
    vi.mocked(api.post).mockRejectedValue(new Error('Network Error'))

    await expect(cerrarSesion()).resolves.toBeUndefined()
  })
})

describe('foto de perfil al iniciar sesión', () => {
  it('usa la URL normalizada por la API antes que la ruta cruda de Windows', async () => {
    vi.mocked(api.post).mockResolvedValue({
      data: {
        data: {
          token: 't',
          usuario: {
            id: 1,
            nombres: 'Juanito',
            apellidos: 'Perezz',
            tipo_usuario: 'Administrador',
            id_empresas: 1,
            foto_perfil: String.raw`C:\laragon\www\gym-bros\storage\app\public\usuario\a.jpg`,
            foto_perfil_url: 'http://api.test/storage/usuario/a.jpg',
          },
        },
      },
    })

    const { usuario } = await iniciarSesion({ correo: 'juan@gmail.com', contrasena: 'x' })

    expect(usuario.nombre).toBe('Juanito Perezz')
    expect(usuario.foto).toBe('http://api.test/storage/usuario/a.jpg')
  })
})
