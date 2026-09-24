import { describe, expect, it, vi } from 'vitest'

import { configurarInterceptores } from '@/core/api/interceptors'

describe('interceptores HTTP', () => {
  it('conserva Retry-After al normalizar un 429', async () => {
    let rechazarRespuesta
    const instancia = {
      interceptors: {
        request: { use: vi.fn() },
        response: {
          use: vi.fn((_, rechazar) => {
            rechazarRespuesta = rechazar
          }),
        },
      },
    }

    configurarInterceptores(instancia)

    await expect(
      rechazarRespuesta({
        response: {
          status: 429,
          data: { message: 'Demasiadas solicitudes.' },
          headers: { 'retry-after': '45' },
        },
      }),
    ).rejects.toMatchObject({ status: 429, retryAfter: '45' })
  })

  it('extrae el mensaje JSON cuando una descarga falla como blob', async () => {
    let rechazarRespuesta
    const instancia = {
      interceptors: {
        request: { use: vi.fn() },
        response: { use: vi.fn((_, rechazar) => (rechazarRespuesta = rechazar)) },
      },
    }

    configurarInterceptores(instancia)

    await expect(
      rechazarRespuesta({
        response: {
          status: 403,
          data: new Blob([JSON.stringify({ message: 'No autorizado.' })], {
            type: 'application/json',
          }),
          headers: {},
        },
      }),
    ).rejects.toMatchObject({ status: 403, message: 'No autorizado.' })
  })
})
