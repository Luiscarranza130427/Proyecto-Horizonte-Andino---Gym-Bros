import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import AlimentoEditView from '@/modules/alimentacion/views/AlimentoEditView.vue'
import {
  actualizarAlimento,
  obtenerAlimento,
} from '@/modules/alimentacion/services/alimentacion.service'
import { HttpError } from '@/core/api/http-error'

const route = reactive({ params: { id: '4' }, query: {} })
// El router real devuelve una promesa y la vista encadena `.catch()` sobre ella.
const push = vi.fn(() => Promise.resolve())
const replace = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ push, replace }) }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  obtenerAlimento: vi.fn(),
  actualizarAlimento: vi.fn(),
}))

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
}

const OPCIONES = {
  global: {
    stubs: {
      RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
      Teleport: true,
    },
  },
}

describe('AlimentoEditView', () => {
  beforeEach(() => {
    route.params = { id: '4' }
    route.query = {}
    push.mockReset().mockResolvedValue(undefined)
    replace.mockReset().mockResolvedValue(undefined)
    obtenerAlimento.mockReset()
    actualizarAlimento.mockReset()
  })

  it('carga la ficha en el formulario y guarda los cambios', async () => {
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    actualizarAlimento.mockResolvedValue({ ...ALIMENTO, calorias: 370 })
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.get('#alimento-nombre').element.value).toBe('Avena')
    expect(wrapper.get('#alimento-tipo').element.value).toBe('cereal')

    await wrapper.get('#alimento-calorias').setValue('370')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(actualizarAlimento).toHaveBeenCalledWith('4', expect.objectContaining({ calorias: 370 }))
    expect(push).not.toHaveBeenCalled()
    expect(wrapper.get('[role="status"]').text()).toContain('Alimento actualizado correctamente.')
    expect(wrapper.get('#alimento-calorias').element.value).toBe('370')
  })

  it('reparte por campo un 422 con errores y deja el formulario en pantalla', async () => {
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    actualizarAlimento.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'Revisa los datos introducidos.',
        errors: { calorias: ['La energía no puede superar 900 kcal por 100 g.'] },
      }),
    )
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    await wrapper.get('#alimento-calorias').setValue('9000')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(push).not.toHaveBeenCalled()
    expect(wrapper.get('#error-calorias').text()).toContain(
      'La energía no puede superar 900 kcal por 100 g.',
    )
    expect(wrapper.get('#alimento-calorias').element.value).toBe('9000')
  })

  it('muestra suelto el mensaje de un 422 sin errores por campo', async () => {
    obtenerAlimento.mockResolvedValue(ALIMENTO)
    actualizarAlimento.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'El alimento se usa en 6 comidas y no admite cambiar de tipo.',
        errors: null,
      }),
    )
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    await wrapper.get('#alimento-tipo').setValue('bebida')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain(
      'El alimento se usa en 6 comidas y no admite cambiar de tipo.',
    )
    // Guardar es una ACCIÓN: lo tecleado sigue ahí para poder corregirlo.
    expect(wrapper.find('form').exists()).toBe(true)
    expect(wrapper.get('#alimento-tipo').element.value).toBe('bebida')
  })

  it('muestra en el selector los errores de tipos_comida y conserva la selección', async () => {
    obtenerAlimento.mockResolvedValue({ ...ALIMENTO, tiposComida: ['desayuno'] })
    actualizarAlimento.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'Revisa los tipos de comida.',
        errors: { tiposComida: ['Selecciona un tipo válido.'] },
      }),
    )
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    await wrapper.get('#alimento-tipos-comida').setValue(['almuerzo', 'cena'])
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('#alimento-tipos-comida').findAll('option:checked')).toHaveLength(2)
    expect(wrapper.text()).toContain('Selecciona un tipo válido.')
  })

  it('trata un 404 de carga como pantalla propia, no como error recuperable', async () => {
    obtenerAlimento.mockRejectedValue(
      new HttpError({ status: 404, message: 'El alimento solicitado no existe.' }),
    )
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.text()).toContain('Alimento no encontrado')
    expect(wrapper.find('form').exists()).toBe(false)
    expect(wrapper.get('[role="status"]').findAll('button')).toHaveLength(0)
  })

  it('ofrece reintentar cuando la carga falla de forma recuperable', async () => {
    obtenerAlimento
      .mockRejectedValueOnce(new HttpError({ status: 500, message: 'Error del servidor.' }))
      .mockResolvedValueOnce(ALIMENTO)
    const wrapper = mount(AlimentoEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.find('form').exists()).toBe(false)
    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()

    expect(obtenerAlimento).toHaveBeenCalledTimes(2)
    expect(wrapper.get('#alimento-nombre').element.value).toBe('Avena')
  })
})
