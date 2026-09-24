import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import PlanCreateView from '@/modules/membresias/views/PlanCreateView.vue'
import PlanEditView from '@/modules/membresias/views/PlanEditView.vue'
import PlanForm from '@/modules/membresias/components/PlanForm.vue'
import {
  actualizarPlanComercial,
  crearPlanComercial,
  obtenerPlanComercial,
} from '@/modules/membresias/services/membresias.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

const route = reactive({ params: { id: '3' } })
const push = vi.fn()

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal()),
  useRoute: () => route,
  useRouter: () => ({ push }),
}))

vi.mock('@/modules/membresias/services/membresias.service', () => ({
  actualizarPlanComercial: vi.fn(),
  crearPlanComercial: vi.fn(),
  obtenerPlanComercial: vi.fn(),
}))

const OPCIONES = {
  global: {
    stubs: {
      PageHeader: true,
      PlanForm: {
        name: 'PlanForm',
        props: ['modo', 'valoresIniciales', 'enviando', 'erroresServidor'],
        emits: ['submit', 'cancel'],
        template: '<form></form>',
      },
    },
  },
}

const PLAN = { id: 3, nombre: 'Pro', precio: 199 }

beforeEach(() => {
  vi.clearAllMocks()
  push.mockResolvedValue(undefined)
  obtenerPlanComercial.mockResolvedValue({ ...PLAN })
})

describe.each([
  ['PlanCreateView', PlanCreateView, crearPlanComercial, 'created', []],
  ['PlanEditView', PlanEditView, actualizarPlanComercial, 'updated', ['3']],
])('%s', (_, Vista, guardarPlan, aviso, argumentosPrevios) => {
  it('guarda y vuelve a la administración de planes con su aviso', async () => {
    guardarPlan.mockResolvedValue({ ...PLAN })
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(PlanForm).vm.$emit('submit', { nombre: 'Pro' })
    await flushPromises()

    expect(guardarPlan).toHaveBeenCalledWith(...argumentosPrevios, { nombre: 'Pro' })
    expect(push).toHaveBeenCalledWith({ name: 'planes-administrar', query: { notice: aviso } })
  })

  it('pasa los 422 al formulario y muestra un 422 sin campos como alerta', async () => {
    guardarPlan.mockRejectedValueOnce(
      new HttpError(422, 'Revisa los datos.', { nombre: ['Ya existe un plan con ese nombre.'] }),
    )
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(PlanForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.getComponent(PlanForm).props('erroresServidor')).toEqual({
      nombre: ['Ya existe un plan con ese nombre.'],
    })
    expect(wrapper.find('.alert-danger').exists()).toBe(false)

    guardarPlan.mockRejectedValueOnce(new HttpError(422, 'Datos incompletos.'))
    wrapper.getComponent(PlanForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.get('.alert-danger').text()).toBe('Datos incompletos.')

    guardarPlan.mockRejectedValueOnce(new HttpError(500, 'La API no responde.'))
    wrapper.getComponent(PlanForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.get('.alert-danger').text()).toBe('La API no responde.')
    expect(push).not.toHaveBeenCalled()
  })

  it('ignora un segundo envío mientras guarda', async () => {
    guardarPlan.mockReturnValue(new Promise(() => {}))
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(PlanForm).vm.$emit('submit', {})
    wrapper.getComponent(PlanForm).vm.$emit('submit', {})
    await flushPromises()

    expect(guardarPlan).toHaveBeenCalledTimes(1)
    expect(wrapper.getComponent(PlanForm).props('enviando')).toBe(true)
  })

  it('cancelar captura el rechazo de la navegación', async () => {
    const capturar = vi.fn()
    push.mockReturnValueOnce({ catch: capturar })
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(PlanForm).vm.$emit('cancel')

    expect(push).toHaveBeenCalledWith({ name: 'planes-administrar' })
    expect(capturar).toHaveBeenCalledWith(expect.any(Function))
  })
})

describe('PlanEditView (carga)', () => {
  it('entrega el plan al formulario en modo edición', async () => {
    const wrapper = mount(PlanEditView, OPCIONES)
    await flushPromises()

    expect(obtenerPlanComercial).toHaveBeenCalledWith('3')
    expect(wrapper.getComponent(PlanForm).props()).toEqual(
      expect.objectContaining({ modo: 'edit', valoresIniciales: PLAN }),
    )
  })

  it('muestra el error de carga y permite reintentar', async () => {
    obtenerPlanComercial.mockRejectedValueOnce(new HttpError(500, 'Falla temporal.'))
    const wrapper = mount(PlanEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Falla temporal.')
    expect(wrapper.findComponent(PlanForm).exists()).toBe(false)

    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(wrapper.findComponent(PlanForm).exists()).toBe(true)
  })
})
