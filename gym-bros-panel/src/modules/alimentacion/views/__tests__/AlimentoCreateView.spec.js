import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import AlimentoCreateView from '@/modules/alimentacion/views/AlimentoCreateView.vue'
import { crearAlimento } from '@/modules/alimentacion/services/alimentacion.service'
import { HttpError } from '@/core/api/http-error'

const route = reactive({ params: {}, query: {} })
// El router real devuelve una promesa y la vista encadena `.catch()` sobre ella.
const push = vi.fn(() => Promise.resolve())
const replace = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ push, replace }) }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  crearAlimento: vi.fn(),
}))

const OPCIONES = {
  global: {
    stubs: {
      RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
      Teleport: true,
    },
  },
}

async function completar(wrapper, cambios = {}) {
  const valores = {
    '#alimento-nombre': 'Avena',
    '#alimento-tipo': 'cereal',
    '#alimento-calorias': '389',
    '#alimento-proteinas': '16.9',
    '#alimento-carbohidratos': '66.3',
    '#alimento-grasas': '6.9',
    '#alimento-fibra': '10.6',
    ...cambios,
  }
  for (const [selector, valor] of Object.entries(valores)) {
    await wrapper.get(selector).setValue(valor)
  }
}

describe('AlimentoCreateView', () => {
  beforeEach(() => {
    route.params = {}
    route.query = {}
    push.mockReset().mockResolvedValue(undefined)
    replace.mockReset().mockResolvedValue(undefined)
    crearAlimento.mockReset()
  })

  it('crea el alimento y lleva a su ficha anunciando el alta', async () => {
    crearAlimento.mockResolvedValue({ id: 31, nombre: 'Avena' })
    const wrapper = mount(AlimentoCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(crearAlimento).toHaveBeenCalledWith(
      expect.objectContaining({ nombre: 'Avena', tipo: 'cereal', calorias: 389, fibra: 10.6 }),
    )
    expect(push).toHaveBeenCalledWith({
      name: 'alimento-detalle',
      params: { id: 31 },
      query: { notice: 'created' },
    })
  })

  it('reparte por campo un 422 con errores sin salir de la pantalla', async () => {
    crearAlimento.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'Revisa los datos introducidos.',
        errors: { nombre: ['Ya existe un alimento con este nombre.'] },
      }),
    )
    const wrapper = mount(AlimentoCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(push).not.toHaveBeenCalled()
    expect(wrapper.get('#error-nombre').text()).toContain('Ya existe un alimento con este nombre.')
    expect(wrapper.get('#alimento-nombre').attributes('aria-describedby')).toBe('error-nombre')
  })

  it('muestra suelto el mensaje de un 422 sin errores por campo', async () => {
    // Una regla de negocio no corresponde a ningún campo: si se repartiera por
    // campo no se vería en ninguno, y el formulario parecería no responder.
    crearAlimento.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'El catálogo de esta empresa ya alcanzó su límite de alimentos.',
        errors: null,
      }),
    )
    const wrapper = mount(AlimentoCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain(
      'El catálogo de esta empresa ya alcanzó su límite de alimentos.',
    )
    // Y lo tecleado sigue en pantalla: guardar es una acción, no una carga.
    expect(wrapper.find('form').exists()).toBe(true)
    expect(wrapper.get('#alimento-nombre').element.value).toBe('Avena')
  })

  it('muestra en cabecera un fallo que no es de validación', async () => {
    crearAlimento.mockRejectedValue(
      new HttpError({ status: 500, message: 'Error interno del servidor.' }),
    )
    const wrapper = mount(AlimentoCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Error interno del servidor.')
    expect(push).not.toHaveBeenCalled()
  })

  it('vuelve al catálogo al cancelar', async () => {
    const wrapper = mount(AlimentoCreateView, OPCIONES)

    const cancelar = wrapper.findAll('button').find((boton) => /cancelar/i.test(boton.text()))
    await cancelar.trigger('click')

    expect(push).toHaveBeenCalledWith({ name: 'alimentos-listado' })
  })
})
