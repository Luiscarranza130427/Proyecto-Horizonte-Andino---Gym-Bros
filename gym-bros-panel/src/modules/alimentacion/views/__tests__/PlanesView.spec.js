import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import PlanesView from '@/modules/alimentacion/views/PlanesView.vue'
import { obtenerAlimentos } from '@/modules/alimentacion/services/alimentacion.service'

const route = reactive({ query: {} })
const replace = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ replace, push: vi.fn(() => Promise.resolve()) }),
  }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  obtenerAlimentos: vi.fn(),
}))

const ALIMENTO = {
  id: 3,
  nombre: 'Palta',
  tipo: 'grasa',
  calorias: 160,
  proteinas: 2,
  carbohidratos: 8.5,
  grasas: 14.7,
  fibra: 6.7,
  unidadBase: 'gramos',
  usos: 0,
}

const RESPUESTA = {
  items: [ALIMENTO],
  paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 12, total: 1, desde: 1, hasta: 1 },
}

function montar() {
  return mount(PlanesView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('PlanesView', () => {
  beforeEach(() => {
    route.query = {}
    replace.mockReset()
    replace.mockResolvedValue(undefined)
    obtenerAlimentos.mockReset()
  })

  it('muestra el catálogo de alimentos en la sección de alimentación', async () => {
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Catálogo de alimentos')
    expect(wrapper.text()).toContain('Palta')
    expect(wrapper.text()).toContain('160')
  })

  it('traduce el tipo del filtro al vocabulario del servicio', async () => {
    route.query = { type: 'proteina', search: 'pollo' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(
      expect.objectContaining({ tipo: 'proteina', busqueda: 'pollo' }),
    )
  })

  it('convierte «Todos» en un filtro vacío, no en el literal «all»', async () => {
    route.query = { type: 'all' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(expect.objectContaining({ tipo: '' }))
  })

  it('un valor inventado en la URL no llega al servicio', async () => {
    route.query = { type: 'inventado' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(expect.objectContaining({ tipo: '' }))
  })

  it('un fallo de carga sustituye el listado', async () => {
    obtenerAlimentos.mockRejectedValue({ message: 'La red no responde.' })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.find('.rejilla').exists()).toBe(false)
    expect(wrapper.find('[role="alert"]').exists()).toBe(true)
    expect(wrapper.text()).toContain('No pudimos cargar el catálogo de alimentos')
  })

  it('distingue «no hay nada» de «no hay resultados con estos filtros»', async () => {
    const vacio = {
      items: [],
      paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 12, total: 0, desde: 0, hasta: 0 },
    }

    obtenerAlimentos.mockResolvedValue(vacio)
    const sinFiltros = montar()
    await flushPromises()
    const textoSinFiltros = sinFiltros.text()

    route.query = { type: 'proteina' }
    const conFiltros = montar()
    await flushPromises()

    expect(conFiltros.text()).not.toBe(textoSinFiltros)
    expect(conFiltros.text().toLowerCase()).toMatch(/filtro/)
  })
})
