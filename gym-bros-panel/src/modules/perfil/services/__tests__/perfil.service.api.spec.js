import { beforeEach, describe, expect, it, vi } from 'vitest'

import api from '@/core/api/api'
import { leerSesion } from '@/core/storage/session.storage'
import { obtenerPerfil } from '@/modules/perfil/services/perfil.service'

vi.mock('@/core/api/api', () => ({ default: { get: vi.fn() } }))
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
      throw Object.assign(new Error('no esperado'), { status: 404 })
    })

    const perfil = await obtenerPerfil()

    // `GET /perfil` no existe en la API: pedirlo dejaba un 404 en cada carga.
    expect(api.get).not.toHaveBeenCalledWith('/perfil')
    expect(api.get).toHaveBeenCalledWith('/empresas/1')
    expect(perfil).toMatchObject({ id: 1, nombre: 'Titan Gym', estado: 'activo' })
    expect(perfil.estadisticas.miembrosActivos).toBe(2)
  })
})
