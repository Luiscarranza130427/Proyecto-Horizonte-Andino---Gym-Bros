import { beforeEach, describe, expect, it, vi } from 'vitest'

import api from '@/core/api/api'
import { obtenerTenantActual } from '@/core/tenant/tenant.service'
import { leerSesion } from '@/core/storage/session.storage'

vi.mock('@/core/api/api', () => ({ default: { get: vi.fn() } }))
vi.mock('@/core/config/env', () => ({ USE_MOCKS: false }))
vi.mock('@/core/storage/session.storage', () => ({ leerSesion: vi.fn() }))

describe('tenant.service', () => {
  beforeEach(() => vi.clearAllMocks())

  it('pide solo la empresa de la sesión, sin sondear /tenant/current', async () => {
    vi.mocked(leerSesion).mockReturnValue({ usuario: { tenantId: 1 } })
    vi.mocked(api.get).mockResolvedValue({
      data: {
        data: {
          id: 1,
          nombre: 'Titan Gym',
          logo: 'empresas/logo.webp',
          logo_url: 'http://api.test/storage/empresas/logo.webp',
          color_1: '#111111',
          estado: 1,
        },
      },
    })

    const tenant = await obtenerTenantActual()

    // /tenant/current no existe en la API y dejaba un 404 en cada carga.
    expect(api.get).toHaveBeenCalledTimes(1)
    expect(api.get).toHaveBeenCalledWith('/empresas/1')
    expect(tenant).toMatchObject({
      id: 1,
      nombre: 'Titan Gym',
      logo: 'http://api.test/storage/empresas/logo.webp',
      activo: true,
    })
  })

  it('sin empresa en la sesión no llama a la API', async () => {
    vi.mocked(leerSesion).mockReturnValue({ usuario: {} })
    await expect(obtenerTenantActual()).rejects.toMatchObject({ status: 401 })
    expect(api.get).not.toHaveBeenCalled()
  })
})
