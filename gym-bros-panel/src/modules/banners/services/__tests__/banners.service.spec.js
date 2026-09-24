import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

describe('banners.service', () => {
  beforeEach(() => vi.resetModules())
  afterEach(() => vi.restoreAllMocks())

  async function cargarServicio(api) {
    vi.doMock('@/core/api/api', () => ({ default: api }))
    return import('@/modules/banners/services/banners.service')
  }

  it('lista y normaliza todos los banners de la API', async () => {
    const get = vi.fn().mockResolvedValue({
      data: {
        data: [
          {
            id: 1,
            imagen: 'banners/uno.webp',
            contenido_text: 'Uno',
            texto_boton: 'Ver',
            enlace_boton: '/uno',
          },
        ],
      },
    })
    const { obtenerBanners } = await cargarServicio({ get })

    await expect(obtenerBanners()).resolves.toEqual([
      {
        id: 1,
        imagen: expect.stringMatching(/\/storage\/banners\/uno\.webp$/),
        contenido: 'Uno',
        textoBoton: 'Ver',
        enlaceBoton: '/uno',
      },
    ])
    expect(get).toHaveBeenCalledWith('/banners')
  })

  it('crea y actualiza con FormData, sin enviar imagen en la edición si no cambia', async () => {
    const post = vi.fn().mockResolvedValue({ data: { data: { id: 1 } } })
    const put = vi.fn().mockResolvedValue({ data: { data: { id: 1 } } })
    const { crearBanner, actualizarBanner } = await cargarServicio({ post, put })
    const imagen = new File(['imagen'], 'banner.webp', { type: 'image/webp' })

    await crearBanner({ contenido: 'Texto', textoBoton: 'Ver', enlaceBoton: '/ver', imagen })
    await actualizarBanner(1, {
      contenido: 'Texto',
      textoBoton: 'Ver',
      enlaceBoton: '/ver',
      imagen: null,
    })

    const datosCreacion = post.mock.calls[0][1]
    const datosEdicion = post.mock.calls[1][1]
    expect(post.mock.calls[0][0]).toBe('/banners')
    expect(datosCreacion).toBeInstanceOf(FormData)
    expect(datosCreacion.get('imagen')).toBe(imagen)
    // Multipart en PUT llega vacío a PHP: la edición viaja como POST + _method=PUT.
    expect(put).not.toHaveBeenCalled()
    expect(post.mock.calls[1][0]).toBe('/banners/1')
    expect(datosEdicion.get('_method')).toBe('PUT')
    expect(datosEdicion.get('contenido_text')).toBe('Texto')
    expect(datosEdicion.get('imagen')).toBeNull()
  })

  it('elimina solo el registro mediante la ruta del banner', async () => {
    const deleteRequest = vi.fn().mockResolvedValue({ data: { message: 'Eliminado' } })
    const { eliminarBanner } = await cargarServicio({ delete: deleteRequest })

    await eliminarBanner(7)

    expect(deleteRequest).toHaveBeenCalledWith('/banners/7')
  })
})
