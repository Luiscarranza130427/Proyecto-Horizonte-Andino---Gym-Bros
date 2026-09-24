import { enableAutoUnmount, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it } from 'vitest'

import DashboardBanner from '@/modules/dashboard/components/DashboardBanner.vue'

enableAutoUnmount(afterEach)

describe('DashboardBanner', () => {
  it('rota los banners y conserva el contenido y enlace de cada registro', async () => {
    const wrapper = mount(DashboardBanner, {
      props: {
        banners: [
          {
            id: 1,
            imagenUrl: 'https://cdn.example.com/banner.webp',
            contenido: 'Contenido principal',
            textoBoton: 'Descubrir',
            enlaceBoton: '/planes',
          },
          {
            id: 2,
            imagenUrl: 'https://cdn.example.com/banner-2.webp',
            contenido: 'Segundo banner',
            textoBoton: 'Conocer más',
            enlaceBoton: '/contacto',
          },
        ],
      },
    })

    expect(wrapper.attributes('style')).toContain('banner.webp')
    expect(wrapper.get('.banner__contenido').text()).toContain('Contenido principal')
    expect(wrapper.get('.banner__accion').text()).toBe('Descubrir')
    expect(wrapper.get('.banner__accion').attributes('href')).toBe('/planes')

    await wrapper.get('[aria-label="Mostrar banner 2"]').trigger('click')
    expect(wrapper.attributes('style')).toContain('banner-2.webp')
    expect(wrapper.get('.banner__contenido').text()).toContain('Segundo banner')
    expect(wrapper.get('.banner__accion').attributes('href')).toBe('/contacto')
  })

  it('no muestra un botón incompleto', () => {
    const wrapper = mount(DashboardBanner, {
      props: {
        banners: [
          {
            imagenUrl: '',
            contenido: 'Sin llamada a la acción',
            textoBoton: 'Descubrir',
            enlaceBoton: '',
          },
        ],
      },
    })

    expect(wrapper.find('.banner__accion').exists()).toBe(false)
  })
})
