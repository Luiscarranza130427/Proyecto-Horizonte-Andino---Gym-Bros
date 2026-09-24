import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import AlimentoDetailView from '@/modules/alimentacion/views/AlimentoDetailView.vue'
import { obtenerAlimento } from '@/modules/alimentacion/services/alimentacion.service'
import { HttpError } from '@/core/api/http-error'

const route = reactive({ params: { id: '4' }, query: {} })
// El router real devuelve una promesa y la vista encadena `.catch()` sobre ella
// (regla de CLAUDE.md). Un `vi.fn()` pelado devuelve undefined y reventaría
// dentro del componente: el mock tiene que parecerse al original.
const push = vi.fn(() => Promise.resolve())
const replace = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ push, replace }) }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  obtenerAlimento: vi.fn(),
}))

/** Contrato de `normalizarAlimento`: sin `estado`, la tabla no lo tiene. */
const ALIMENTO = {
  id: 4,
  nombre: 'Avena',
  tipo: 'cereal',
  calorias: 389,
  proteinas: 16.9,
  carbohidratos: 66.3,
  grasas: 6.9,
  fibra: 10.6,
  unidadBase: 'gramos',
  usos: 0,
  activo: true,
  estadoPreparacion: 'Cocido',
  gramosPorUnidad: 45,
  densidadGml: null,
  fuenteNutricional: 'BEDCA',
  nutricionVerificada: true,
  restriccionesVerificadas: false,
  grupoMenu: 'cereal',
  tiposComida: ['desayuno'],
  porcionMin: 30,
  porcionMax: 90,
  pasoPorcion: 5,
}

function montar() {
  return mount(AlimentoDetailView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('AlimentoDetailView', () => {
  beforeEach(() => {
    route.params = { id: '4' }
    route.query = {}
    push.mockReset().mockResolvedValue(undefined)
    replace.mockReset().mockResolvedValue(undefined)
    obtenerAlimento.mockReset()
  })

  it('muestra la ficha nutricional referida a la unidad base', async () => {
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    const wrapper = montar()
    await flushPromises()

    expect(obtenerAlimento).toHaveBeenCalledWith('4')
    expect(wrapper.text()).toContain('Avena')
    // 'gramos' y 'cereal' son los valores del esquema; la ficha los traduce.
    expect(wrapper.text()).toContain('Valores por 100 g')
    expect(wrapper.text()).toContain('Cereal')
    expect(wrapper.text()).toContain('389')
    expect(wrapper.text()).toContain('16.9')
    expect(wrapper.text()).toContain('Estado de preparación')
    expect(wrapper.text()).toContain('BEDCA')
    expect(wrapper.text()).toContain('Porción mínima')
    expect(wrapper.text()).toContain('Restricciones verificadas')
  })

  it('no muestra ninguna acción para retirar el alimento', async () => {
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).not.toContain('Retirar del catálogo')
    expect(wrapper.find('.dialogo').exists()).toBe(false)
  })

  it('sustituye el contenido cuando lo que falla es la carga', async () => {
    // El caso contrario al anterior: aquí no hay ficha que conservar, así que
    // el error sí ocupa la pantalla y ofrece reintentar.
    obtenerAlimento
      .mockRejectedValueOnce(new HttpError({ status: 500, message: 'Error del servidor.' }))
      .mockResolvedValueOnce(ALIMENTO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.find('.detalle').exists()).toBe(false)
    expect(wrapper.text()).not.toContain('Avena')
    expect(wrapper.get('[role="alert"]').text()).toContain('Error del servidor.')

    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()

    expect(obtenerAlimento).toHaveBeenCalledTimes(2)
    expect(wrapper.find('.detalle').exists()).toBe(true)
  })

  it('distingue un 404 de un fallo recuperable', async () => {
    obtenerAlimento.mockRejectedValue(
      new HttpError({ status: 404, message: 'El alimento solicitado no existe.' }),
    )
    const wrapper = montar()
    await flushPromises()

    // Un 404 no ofrece «Reintentar»: reintentar no lo va a hacer aparecer.
    expect(wrapper.text()).toContain('Alimento no encontrado')
    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
    expect(wrapper.get('[role="status"]').findAll('button')).toHaveLength(0)
  })

  it('consume el aviso de creación y lo retira de la URL', async () => {
    // Si no se retirara, reaparecería al recargar o al volver atrás.
    route.query = { notice: 'created' }
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('[role="status"]').text()).toMatch(/creado/i)
    expect(replace).toHaveBeenCalledWith({ name: 'alimento-detalle', params: { id: '4' } })
  })
})
