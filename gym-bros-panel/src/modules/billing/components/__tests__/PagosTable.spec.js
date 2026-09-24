import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PagosTable from '@/modules/billing/components/PagosTable.vue'

const PAGOS_MOCK = [
  {
    id: 1,
    codigo: 'PAG-0001',
    fecha: '2026-08-15',
    empresa: { id: 1, nombre: 'Power Gym' },
    plan: { id: 2, nombre: 'Fuerza' },
    precio: 1047,
    moneda: 'PEN',
    cantidadMeses: 3,
    metodoPago: 'Tarjeta de crédito',
    estado: 'completado',
  },
]

describe('PagosTable.vue', () => {
  it('muestra skeletons cuando cargando es true', () => {
    const wrapper = mount(PagosTable, {
      props: {
        items: [],
        cargando: true,
      },
    })

    expect(wrapper.findAll('.pagos-tabla__skeleton-fila')).toHaveLength(5)
  })

  it('muestra mensaje de vacío cuando no hay items y cargando es false', () => {
    const wrapper = mount(PagosTable, {
      props: {
        items: [],
        cargando: false,
      },
    })

    expect(wrapper.text()).toContain('No se encontraron pagos')
  })

  it('renderiza la lista de pagos y emite evento verDetalle', async () => {
    const wrapper = mount(PagosTable, {
      props: {
        items: PAGOS_MOCK,
        paginacion: {
          pagina: 1,
          ultimaPagina: 1,
          porPagina: 10,
          total: 1,
          desde: 1,
          hasta: 1,
        },
        cargando: false,
      },
    })

    expect(wrapper.text()).toContain('PAG-0001')
    expect(wrapper.text()).toContain('Power Gym')
    expect(wrapper.text()).toContain('Fuerza')

    const btnVer = wrapper.find('.pagos-tabla__btn-ver')
    await btnVer.trigger('click')

    expect(wrapper.emitted('verDetalle')).toHaveLength(1)
    expect(wrapper.emitted('verDetalle')[0][0]).toEqual(PAGOS_MOCK[0])
  })
})
