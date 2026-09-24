import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import BannersView from '@/modules/banners/views/BannersView.vue'
import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import {
  actualizarBanner,
  crearBanner,
  eliminarBanner,
  obtenerBanners,
} from '@/modules/banners/services/banners.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

vi.mock('@/modules/banners/services/banners.service', () => ({
  obtenerBanners: vi.fn(),
  crearBanner: vi.fn(),
  actualizarBanner: vi.fn(),
  eliminarBanner: vi.fn(),
}))

const BANNERS = [
  {
    id: 1,
    imagen: 'http://api.test/storage/banners-web/a.webp',
    contenido: 'Entrena con una rutina personalizada.',
    textoBoton: 'Solicitar',
    enlaceBoton: 'https://gymbros.pe',
  },
]

const OPCIONES = {
  global: { stubs: { PageHeader: { template: '<header><slot name="acciones" /></header>' } } },
}

function montar() {
  return mount(BannersView, OPCIONES)
}

async function adjuntarImagen(wrapper) {
  globalThis.URL.createObjectURL ??= () => 'blob:vista-previa'
  globalThis.URL.revokeObjectURL ??= () => {}
  const input = wrapper.get('#banner-imagen')
  Object.defineProperty(input.element, 'files', {
    configurable: true,
    value: [new File(['x'], 'banner.png', { type: 'image/png' })],
  })
  await input.trigger('change')
}

beforeEach(() => {
  vi.clearAllMocks()
  obtenerBanners.mockResolvedValue(structuredClone(BANNERS))
})

describe('BannersView', () => {
  it('lista los banners de la API', async () => {
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Entrena con una rutina personalizada.')
    expect(wrapper.get('.banner-card img').attributes('src')).toBe(BANNERS[0].imagen)
  })

  it('muestra el estado vacío y el de error con reintento', async () => {
    obtenerBanners.mockResolvedValueOnce([])
    const vacio = montar()
    await flushPromises()
    expect(vacio.text()).toContain('Aún no hay banners creados.')

    obtenerBanners.mockRejectedValueOnce(new HttpError(500, 'La API no responde.'))
    const conError = montar()
    await flushPromises()
    expect(conError.get('[role="alert"]').text()).toContain('La API no responde.')

    await conError.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(conError.text()).toContain('Entrena con una rutina personalizada.')
  })

  it('valida los campos obligatorios y la imagen antes de crear', async () => {
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('form').trigger('submit')

    expect(crearBanner).not.toHaveBeenCalled()
    expect(wrapper.text()).toContain('Ingresa el contenido del banner.')
    expect(wrapper.text()).toContain('Selecciona la imagen del banner.')
    // El error queda enlazado a su campo para los lectores de pantalla.
    expect(wrapper.get('#banner-contenido').attributes('aria-describedby')).toBe(
      'error-banner-contenido',
    )
  })

  it('respeta los máximos de la API en los campos', async () => {
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('#banner-contenido').attributes('maxlength')).toBe('100')
    expect(wrapper.get('#banner-texto-boton').attributes('maxlength')).toBe('20')
    expect(wrapper.get('#banner-enlace-boton').attributes('maxlength')).toBe('300')
    expect(wrapper.get('label[for="banner-contenido"]').text()).toContain('Contenido')
  })

  it('crea un banner y lo añade al listado', async () => {
    crearBanner.mockResolvedValue({ ...BANNERS[0], id: 2, contenido: 'Nuevo' })
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('#banner-contenido').setValue('Nuevo')
    await wrapper.get('#banner-texto-boton').setValue('Ver')
    await wrapper.get('#banner-enlace-boton').setValue('https://gymbros.pe/nuevo')
    await adjuntarImagen(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(crearBanner).toHaveBeenCalledWith(
      expect.objectContaining({ contenido: 'Nuevo', imagen: expect.any(File) }),
    )
    expect(wrapper.get('[role="status"]').text()).toContain('Banner creado correctamente.')
    expect(wrapper.findAll('.banner-card')).toHaveLength(2)
  })

  it('edita sin exigir imagen nueva y refleja el cambio', async () => {
    actualizarBanner.mockResolvedValue({ ...BANNERS[0], contenido: 'Texto editado' })
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('.banner-card .btn-secondary').trigger('click')
    expect(wrapper.get('#banner-contenido').element.value).toBe(BANNERS[0].contenido)
    await wrapper.get('#banner-contenido').setValue('Texto editado')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(actualizarBanner).toHaveBeenCalledWith(
      1,
      expect.objectContaining({ contenido: 'Texto editado', imagen: null }),
    )
    expect(wrapper.text()).toContain('Texto editado')
    expect(wrapper.get('[role="status"]').text()).toContain('Banner actualizado correctamente.')
  })

  it('muestra los errores 422 de la API por campo', async () => {
    crearBanner.mockRejectedValue(
      new HttpError(422, 'Revisa los datos.', { textoBoton: ['Máximo 20 caracteres.'] }),
    )
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('#banner-contenido').setValue('Nuevo')
    await wrapper.get('#banner-texto-boton').setValue('Ver')
    await wrapper.get('#banner-enlace-boton').setValue('https://gymbros.pe')
    await adjuntarImagen(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.text()).toContain('Máximo 20 caracteres.')
  })

  it('confirma la eliminación nombrando el banner y lo retira del listado', async () => {
    eliminarBanner.mockResolvedValue({ message: 'Banner eliminado correctamente.' })
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('.banner-card .btn-danger').trigger('click')
    const dialogo = wrapper.findComponent(ConfirmDialog)
    expect(dialogo.props('abierto')).toBe(true)
    expect(dialogo.props('descripcion')).toContain('Entrena con una rutina personalizada.')

    dialogo.vm.$emit('confirmar')
    await flushPromises()

    expect(eliminarBanner).toHaveBeenCalledWith(1)
    expect(wrapper.findAll('.banner-card')).toHaveLength(0)
  })
})
