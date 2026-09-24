import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import PagoReceiptModal from '@/modules/billing/components/PagoReceiptModal.vue'
import PagosView from '@/modules/billing/views/PagosView.vue'
import {
  obtenerMetricasPagos,
  obtenerReportePagos,
} from '@/modules/billing/services/billing.service'

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

const METRICAS_MOCK = {
  totalIngresos: 45000,
  totalTransacciones: 24,
  ticketPromedio: 1875,
  totalMeses: 72,
  moneda: 'PEN',
}

const mockRoute = reactive({
  name: 'pagos',
  query: {},
})
const mockReplace = vi.fn()
const mockPush = vi.fn()

vi.mock('vue-router', () => ({
  useRoute: () => mockRoute,
  useRouter: () => ({ replace: mockReplace, push: mockPush }),
  RouterLink: { template: '<a><slot /></a>' },
}))

vi.mock('@/modules/billing/services/billing.service', () => ({
  obtenerReportePagos: vi.fn(),
  obtenerMetricasPagos: vi.fn(),
}))

describe('PagosView.vue', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    obtenerReportePagos.mockResolvedValue({
      items: PAGOS_MOCK,
      paginacion: {
        pagina: 1,
        ultimaPagina: 1,
        porPagina: 10,
        total: 1,
        desde: 1,
        hasta: 1,
      },
    })
    obtenerMetricasPagos.mockResolvedValue(METRICAS_MOCK)
  })

  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('renderiza la cabecera, métricas KPI y la tabla de pagos', async () => {
    const wrapper = mount(PagosView)
    await flushPromises()

    expect(wrapper.text()).toContain('Reportes de pagos')
    expect(wrapper.text()).toContain('Ingresos Totales')
    expect(wrapper.text()).not.toContain('Ticket Promedio')
    expect(wrapper.text()).not.toContain('Meses Vendidos')
    expect(wrapper.text()).toContain('PAG-0001')
    expect(wrapper.text()).toContain('Power Gym')
  })

  it('abre el modal de comprobante al pulsar ver', async () => {
    const wrapper = mount(PagosView)
    await flushPromises()

    const btnVer = wrapper.find('.pagos-tabla__btn-ver')
    await btnVer.trigger('click')
    await flushPromises()

    const modal = wrapper.findComponent(PagoReceiptModal)
    expect(modal.exists()).toBe(true)
    expect(modal.props('abierto')).toBe(true)
    expect(modal.props('pago')).toEqual(PAGOS_MOCK[0])
  })

  it('no muestra la barra de búsqueda y filtros', async () => {
    const wrapper = mount(PagosView)
    await flushPromises()

    expect(wrapper.find('#filtro-empresa').exists()).toBe(false)
    expect(wrapper.find('[aria-label="Filtros de pagos"]').exists()).toBe(false)
  })
})
