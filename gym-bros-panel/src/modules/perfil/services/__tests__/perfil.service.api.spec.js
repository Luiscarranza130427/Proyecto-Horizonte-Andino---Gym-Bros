import { beforeEach, describe, expect, it, vi } from 'vitest'

import api from '@/core/api/api'
import { leerSesion } from '@/core/storage/session.storage'
import { actualizarLogoEmpresa, obtenerPerfil } from '@/modules/perfil/services/perfil.service'

vi.mock('@/core/api/api', () => ({ default: { get: vi.fn(), post: vi.fn() } }))
vi.mock('@/core/config/env', () => ({ USE_MOCKS: false }))
vi.mock('@/core/storage/session.storage', () => ({ leerSesion: vi.fn() }))

describe('perfil.service con la API real', () => {
  beforeEach(() => vi.clearAllMocks())

  it('compone el perfil con la empresa de la sesión sin sondear /perfil', async () => {
    vi.mocked(leerSesion).mockReturnValue({ usuario: { tenantId: 1, rol: 'Administrador' } })
    vi.mocked(api.get).mockImplementation(async (url) => {
      if (url === '/empresas/1') {
        return {
          data: { data: { id: 1, nombre: 'Titan Gym', estado: 1, fecha_registro: '2026-09-01' } },
        }
      }
      if (url === '/usuarios') {
        return { data: { data: [{ id_empresas: 1 }, { id_empresas: 1 }, { id_empresas: 2 }] } }
      }
      if (url === '/perfil/preferencias') {
        return { data: { data: { idioma: 'es', tema: 'oscuro', notifEmail: false } } }
      }
      throw Object.assign(new Error('no esperado'), { status: 404 })
    })

    const perfil = await obtenerPerfil()

    // `GET /perfil` no existe en la API: pedirlo dejaba un 404 en cada carga.
    expect(api.get).not.toHaveBeenCalledWith('/perfil')
    expect(api.get).toHaveBeenCalledWith('/empresas/1')
    expect(perfil).toMatchObject({ id: 1, nombre: 'Titan Gym', estado: 'activo' })
    expect(perfil.estadisticas.miembrosActivos).toBe(2)
    expect(perfil.preferencias.notifEmail).toBe(false)
  })

  it('sube el logo como archivo a POST /empresas/{id}/logo', async () => {
    vi.mocked(api.post).mockResolvedValue({
      data: { logo: 'empresas/x.webp', logo_url: 'http://api.test/storage/empresas/x.webp' },
    })

    const resultado = await actualizarLogoEmpresa(1, 'data:image/webp;base64,AAAA')

    const [url, formulario] = api.post.mock.calls[0]
    expect(url).toBe('/empresas/1/logo')
    expect(formulario.get('logo')).toBeInstanceOf(Blob)
    expect(formulario.get('logo').type).toBe('image/webp')
    expect(resultado).toEqual({
      logo: 'empresas/x.webp',
      logoUrl: 'http://api.test/storage/empresas/x.webp',
    })
    await expect(actualizarLogoEmpresa(1, 'no-es-imagen')).rejects.toMatchObject({ status: 422 })
  })
})
