import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import MetricCard from '@/modules/dashboard/components/MetricCard.vue'

describe('MetricCard', () => {
  it('no muestra una tendencia cero cuando el backend no proporciona tendencia', () => {
    const wrapper = mount(MetricCard, {
      props: {
        metrica: {
          id: 'usuarios',
          etiqueta: 'Usuarios',
          valor: 4,
          icono: 'users',
          tipoValor: 'numero',
          tendencia: { valor: 0, prefijo: '', sufijo: '', detalle: '', tono: 'neutro' },
        },
      },
    })

    expect(wrapper.text()).toContain('4')
    expect(wrapper.find('.metrica__tendencia').exists()).toBe(false)
  })
})
