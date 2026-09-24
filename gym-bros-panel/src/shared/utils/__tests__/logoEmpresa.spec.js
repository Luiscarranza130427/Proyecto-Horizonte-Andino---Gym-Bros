import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import {
  LOGO_EMPRESA_ALTO,
  LOGO_EMPRESA_ANCHO,
  normalizarLogoEmpresa,
} from '@/shared/utils/logoEmpresa'

describe('normalizarLogoEmpresa', () => {
  let contexto

  beforeEach(() => {
    contexto = {
      clearRect: vi.fn(),
      drawImage: vi.fn(),
      imageSmoothingEnabled: false,
      imageSmoothingQuality: 'low',
    }

    vi.stubGlobal(
      'FileReader',
      class {
        readAsDataURL() {
          this.result = 'data:image/png;base64,logo-original'
          this.onload()
        }
      },
    )

    vi.stubGlobal(
      'Image',
      class {
        naturalWidth = 1000
        naturalHeight = 1000

        set src(_valor) {
          this.onload()
        }
      },
    )

    vi.spyOn(HTMLCanvasElement.prototype, 'getContext').mockReturnValue(contexto)
    vi.spyOn(HTMLCanvasElement.prototype, 'toDataURL').mockReturnValue(
      'data:image/webp;base64,logo-normalizado',
    )
  })

  afterEach(() => {
    vi.restoreAllMocks()
    vi.unstubAllGlobals()
  })

  it('genera un lienzo de 400 por 180 sin deformar el logo', async () => {
    const archivo = new File(['logo'], 'logo.png', { type: 'image/png' })

    const resultado = await normalizarLogoEmpresa(archivo)

    expect(resultado).toBe('data:image/webp;base64,logo-normalizado')
    expect(contexto.clearRect).toHaveBeenCalledWith(0, 0, LOGO_EMPRESA_ANCHO, LOGO_EMPRESA_ALTO)
    expect(contexto.drawImage).toHaveBeenCalledWith(expect.anything(), 110, 0, 180, 180)
    expect(contexto.imageSmoothingEnabled).toBe(true)
    expect(contexto.imageSmoothingQuality).toBe('high')
  })

  it('rechaza formatos no admitidos', async () => {
    const archivo = new File(['logo'], 'logo.svg', { type: 'image/svg+xml' })

    await expect(normalizarLogoEmpresa(archivo)).rejects.toThrow(
      'El logo debe ser PNG, JPG o WebP.',
    )
  })
})
