import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import AlimentosView from '@/modules/alimentacion/views/AlimentosView.vue'
import { obtenerAlimentos } from '@/modules/alimentacion/services/alimentacion.service'

const route = reactive({ query: {} })
// El router real devuelve una promesa: `useListadoFiltrable` hace `await
// router.replace(...)`. Un `vi.fn()` pelado devolvería undefined.
const replace = vi.fn(() => Promise.resolve())
const push = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ replace, push }) }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  obtenerAlimentos: vi.fn(),
}))

const RESPUESTA = {
  items: [
    {
      id: 4,
      nombre: 'Avena',
      tipo: 'cereal',
      calorias: 389,
      proteinas: 16.9,
      carbohidratos: 66.3,
      grasas: 6.9,
      fibra: 10.6,
      unidadBase: 'gramos',
      usos: 6,
    },
  ],
  paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 12, total: 1, desde: 1, hasta: 1 },
}

const VACIO = {
  items: [],
  paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 12, total: 0, desde: 0, hasta: 0 },
}

function montar() {
  return mount(AlimentosView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('AlimentosView', () => {
  beforeEach(() => {
    route.query = {}
    replace.mockReset().mockResolvedValue(undefined)
    push.mockReset().mockResolvedValue(undefined)
    obtenerAlimentos.mockReset()
  })

  it('muestra el catálogo con su etiqueta legible y la referencia por 100', async () => {
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Avena')
    // El catálogo guarda 'cereal'; la tarjeta muestra la etiqueta.
    expect(wrapper.text()).toContain('Cereal')
    expect(wrapper.text()).toContain('389')
    // Sin la unidad, 389 kcal se leerían como la ración y no como la medida.
    expect(wrapper.text()).toContain('kcal por 100 g')

    expect(obtenerAlimentos).toHaveBeenCalledWith(
      expect.objectContaining({ pagina: 1, porPagina: 12 }),
    )
  })

  it('traduce sus filtros al vocabulario del servicio', async () => {
    // La URL habla en inglés (`type`), el servicio en español (`tipo`).
    route.query = { type: 'proteina', search: 'pollo' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(
      expect.objectContaining({ tipo: 'proteina', busqueda: 'pollo' }),
    )
  })

  it('manda «todos» como cadena vacía y no como el literal «all»', async () => {
    // 'all' es vocabulario del `<select>`, no del backend: filtrar por un tipo
    // llamado literalmente «all» no devolvería nada.
    route.query = { type: 'all' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(expect.objectContaining({ tipo: '' }))
    expect(obtenerAlimentos).not.toHaveBeenCalledWith(expect.objectContaining({ tipo: 'all' }))
  })

  it('descarta un tipo inventado en la URL antes de llegar al servicio', async () => {
    // Sin `permitidos`, un `?type=` cualquiera viajaría al backend.
    route.query = { type: 'inventado' }
    obtenerAlimentos.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledWith(expect.objectContaining({ tipo: '' }))
    expect(obtenerAlimentos).not.toHaveBeenCalledWith(
      expect.objectContaining({ tipo: 'inventado' }),
    )
  })

  it('sustituye la rejilla por un error recuperable y reintenta', async () => {
    obtenerAlimentos
      .mockRejectedValueOnce(new Error('Servicio no disponible.'))
      .mockResolvedValueOnce(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    // Cargar es lo único que hace la pantalla: si falla, no queda nada que ver.
    expect(wrapper.find('.rejilla').exists()).toBe(false)
    expect(wrapper.get('[role="alert"]').text()).toContain('Servicio no disponible.')

    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()

    expect(obtenerAlimentos).toHaveBeenCalledTimes(2)
    expect(wrapper.find('.rejilla').exists()).toBe(true)
    expect(wrapper.text()).toContain('Avena')
  })

  it('distingue el catálogo vacío de una búsqueda sin resultados', async () => {
    obtenerAlimentos.mockResolvedValue(VACIO)
    const wrapper = montar()
    await flushPromises()

    // Sin filtros el catálogo está vacío de verdad: se invita a crear, no a
    // limpiar unos filtros que nadie puso.
    expect(wrapper.get('.alimentos__estado').text()).toContain('Aún no hay alimentos')
    expect(wrapper.find('.alimentos__estado button').exists()).toBe(false)
  })

  it('ofrece limpiar cuando el vacío lo provocan los filtros', async () => {
    route.query = { search: 'no-existe', type: 'bebida' }
    obtenerAlimentos.mockResolvedValue(VACIO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('.alimentos__estado').text()).toContain('No encontramos alimentos')

    await wrapper.get('.alimentos__estado button').trigger('click')
    expect(replace).toHaveBeenCalledWith({ name: 'alimentos-listado' })
  })
})
