import { flushPromises, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it, vi } from 'vitest'

import EmpresaBanners from '@/modules/empresas/components/EmpresaBanners.vue'
import { normalizarBannerEmpresa } from '@/shared/utils/bannerEmpresa'

vi.mock('@/shared/utils/bannerEmpresa', async (importOriginal) => {
  const actual = await importOriginal()
  return {
    ...actual,
    normalizarBannerEmpresa: vi.fn(() => Promise.resolve('data:image/webp;base64,PROCESADA')),
  }
})

const BANNERS = [
  {
    numero: 1,
    imagen: 'banners/promo.webp',
    imagenUrl: 'http://api.test/storage/banners/promo.webp',
    enlace: 'https://gymbros.pe/promo',
  },
  { numero: 2, imagen: '', imagenUrl: '', enlace: '' },
  { numero: 3, imagen: '', imagenUrl: '', enlace: '' },
]

const montar = (props = {}) => mount(EmpresaBanners, { props: { banners: BANNERS, ...props } })

const guardarCon = async (wrapper) => {
  const boton = wrapper.findAll('button').find((b) => /guardar banners/i.test(b.text()))
  await boton.trigger('click')
  await flushPromises()
  return boton
}

describe('EmpresaBanners', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('siempre pinta los tres huecos, aunque sólo uno tenga imagen', async () => {
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.findAll('.banner')).toHaveLength(3)
    expect(wrapper.findAll('.banner__lienzo--vacio')).toHaveLength(2)
  })

  it('avisa de la medida exacta que usa la aplicación móvil', async () => {
    const wrapper = montar()
    await flushPromises()

    // Sin decirla, cada quien sube una imagen de una proporción distinta y el
    // recorte automático se lleva por delante la mitad del cartel.
    expect(wrapper.find('.banners__aviso').text()).toContain('500 × 380 px')
  })

  /*
   * `immediate: true` en el watcher. La ficha monta este componente cuando los
   * banners YA se cargaron; sin él, el formulario aparecería vacío encima de
   * datos que existen, y guardar los borraría.
   */
  it('carga los valores recibidos al montarse, no sólo al cambiar', async () => {
    const wrapper = montar()
    await flushPromises()

    const enlace = wrapper.find('#banner-enlace-1')
    expect(enlace.element.value).toBe('https://gymbros.pe/promo')
    expect(wrapper.find('.banner__lienzo img').attributes('src')).toContain('promo.webp')
  })

  it('explica cuando Laravel no publica el archivo del banner', async () => {
    const wrapper = montar()
    await flushPromises()

    await wrapper.find('.banner__lienzo img').trigger('error')

    expect(wrapper.text()).toContain('Imagen no disponible en storage')
  })

  it('abre el selector desde un botón real sin enfocar un input desplazado', async () => {
    const wrapper = montar()
    await flushPromises()
    const entrada = wrapper.get('#banner-archivo-1')
    const abrir = vi.spyOn(entrada.element, 'click').mockImplementation(() => {})

    const boton = wrapper.find('.banner__elegir')
    expect(boton.element.tagName).toBe('BUTTON')
    await boton.trigger('click')

    expect(abrir).toHaveBeenCalledOnce()
    expect(entrada.classes()).toContain('banner__archivo')
  })

  it('muestra el archivo local directamente mientras conserva la imagen procesada para guardar', async () => {
    const crearUrl = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:banner-local')
    vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {})
    const wrapper = montar()
    await flushPromises()
    const entrada = wrapper.get('#banner-archivo-2')
    const archivo = new File(['imagen'], 'promocion.webp', { type: 'image/webp' })
    Object.defineProperty(entrada.element, 'files', { configurable: true, value: [archivo] })

    await entrada.trigger('change')
    await flushPromises()

    expect(normalizarBannerEmpresa).toHaveBeenCalledWith(archivo)
    expect(crearUrl).toHaveBeenCalledWith(archivo)
    expect(wrapper.findAll('.banner__lienzo img')[1].attributes('src')).toBe('blob:banner-local')

    await wrapper.get('#banner-enlace-2').setValue('https://gymbros.pe/promocion')
    await guardarCon(wrapper)
    expect(wrapper.emitted('guardar')[0][0][1].imagen).toBe('data:image/webp;base64,PROCESADA')
  })

  it('no deja guardar si no se ha tocado nada', async () => {
    const wrapper = montar()
    await flushPromises()

    const boton = wrapper.findAll('button').find((b) => /guardar banners/i.test(b.text()))
    expect(boton.attributes('disabled')).toBeDefined()
  })

  it('rechaza un enlace que no sea una URL completa', async () => {
    const wrapper = montar()
    await flushPromises()

    await wrapper.find('#banner-enlace-1').setValue('gymbros.pe/promo')
    await guardarCon(wrapper)

    expect(wrapper.emitted('guardar')).toBeUndefined()
    expect(wrapper.find('.campo__error').text()).toContain('http://')
  })

  /*
   * Un enlace sin imagen produce un banner invisible en el móvil: hay destino,
   * pero nada que pulsar. Es peor que no configurarlo, porque parece hecho.
   */
  it('no admite un enlace en un hueco sin imagen', async () => {
    const wrapper = montar()
    await flushPromises()

    await wrapper.find('#banner-enlace-2').setValue('https://gymbros.pe/sedes')
    await guardarCon(wrapper)

    expect(wrapper.emitted('guardar')).toBeUndefined()
    expect(wrapper.text()).toContain('sin imagen no se ve')
  })

  /*
   * Emitir los TRES siempre, no sólo el que cambió: el endpoint reemplaza el
   * registro entero y un envío parcial borraría los otros dos.
   */
  it('emite los tres banners aunque sólo se edite uno', async () => {
    const wrapper = montar()
    await flushPromises()

    await wrapper.find('#banner-enlace-1').setValue('https://gymbros.pe/otra')
    await guardarCon(wrapper)

    const emitido = wrapper.emitted('guardar')?.[0][0]
    expect(emitido).toHaveLength(3)
    expect(emitido.map((b) => b.numero)).toEqual([1, 2, 3])
    expect(emitido[0].enlace).toBe('https://gymbros.pe/otra')
    // El primero conserva su imagen: editar el enlace no puede perderla.
    expect(emitido[0].imagen).toBe('banners/promo.webp')
  })

  it('deja vaciar un hueco quitando su imagen', async () => {
    const wrapper = montar()
    await flushPromises()

    const quitar = wrapper.findAll('button').find((b) => /quitar/i.test(b.text()))
    await quitar.trigger('click')
    await flushPromises()

    expect(wrapper.findAll('.banner__lienzo--vacio')).toHaveLength(3)

    // Al quitar la imagen, su enlace ya no puede quedarse solo.
    await guardarCon(wrapper)
    expect(wrapper.emitted('guardar')).toBeUndefined()
    expect(wrapper.text()).toContain('sin imagen no se ve')
  })

  it('bloquea el guardado mientras la petición está en curso', async () => {
    const wrapper = montar({ guardando: true })
    await flushPromises()

    const boton = wrapper.findAll('button').find((b) => /guardando/i.test(b.text()))
    expect(boton.attributes('disabled')).toBeDefined()
  })
})
