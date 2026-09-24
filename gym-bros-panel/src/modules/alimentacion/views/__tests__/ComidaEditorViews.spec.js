import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import ComidaCreateView from '@/modules/alimentacion/views/ComidaCreateView.vue'
import ComidaEditView from '@/modules/alimentacion/views/ComidaEditView.vue'
import ComidaForm from '@/modules/alimentacion/components/ComidaForm.vue'
import {
  actualizarComida,
  crearComida,
  obtenerAlimentosParaElegir,
  obtenerPlan,
} from '@/modules/alimentacion/services/alimentacion.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

const route = reactive({ params: { idPlan: '4', idComida: '11' } })
const push = vi.fn()

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal()),
  useRoute: () => route,
  useRouter: () => ({ push }),
}))

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  actualizarComida: vi.fn(),
  crearComida: vi.fn(),
  obtenerAlimentosParaElegir: vi.fn(),
  obtenerPlan: vi.fn(),
}))

const COMIDA = { id: 11, tipoComida: 'desayuno', horaSugerida: '07:30', alimentos: [] }
const PLAN = { id: 4, usuario: { nombre: 'Carlos' }, comidas: [COMIDA] }
const CATALOGO = [{ id: 1, nombre: 'Avena' }]

const OPCIONES = {
  global: {
    stubs: {
      PageHeader: {
        props: ['titulo', 'descripcion', 'migas'],
        template: '<header><h1>{{ titulo }}</h1><p>{{ descripcion }}</p></header>',
      },
      RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
      ComidaForm: {
        name: 'ComidaForm',
        props: [
          'modo',
          'valoresIniciales',
          'enviando',
          'erroresServidor',
          'catalogo',
          'cargandoCatalogo',
          'errorCatalogo',
        ],
        emits: ['submit', 'cancel', 'recargar-catalogo'],
        template: '<form></form>',
      },
    },
  },
}

beforeEach(() => {
  vi.clearAllMocks()
  route.params.idPlan = '4'
  route.params.idComida = '11'
  push.mockResolvedValue(undefined)
  obtenerPlan.mockResolvedValue(structuredClone(PLAN))
  obtenerAlimentosParaElegir.mockResolvedValue(structuredClone(CATALOGO))
})

describe.each([
  ['ComidaCreateView', ComidaCreateView, crearComida, ['4'], 'created'],
  ['ComidaEditView', ComidaEditView, actualizarComida, ['4', '11'], 'updated'],
])('%s', (_, Vista, guardarComida, argumentos, aviso) => {
  it('guarda y vuelve a la ficha del plan con su aviso', async () => {
    guardarComida.mockResolvedValue({ ...COMIDA })
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    const form = wrapper.getComponent(ComidaForm)
    expect(form.props('catalogo')).toEqual(CATALOGO)
    form.vm.$emit('submit', { tipoComida: 'cena' })
    await flushPromises()

    expect(guardarComida).toHaveBeenCalledWith(...argumentos, { tipoComida: 'cena' })
    expect(push).toHaveBeenCalledWith({
      name: 'plan-alimentacion-detalle',
      params: { id: '4' },
      query: { notice: aviso },
    })
  })

  it('reparte los 422 por campo y muestra una regla de negocio sin campos', async () => {
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    guardarComida.mockRejectedValueOnce(
      new HttpError(422, 'Revisa los datos.', { horaSugerida: ['Hora inválida.'] }),
    )
    wrapper.getComponent(ComidaForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.getComponent(ComidaForm).props('erroresServidor')).toEqual({
      horaSugerida: ['Hora inválida.'],
    })
    expect(wrapper.find('.alert-danger').exists()).toBe(false)

    guardarComida.mockRejectedValueOnce(new HttpError(422, 'Ya hay un desayuno en el plan.'))
    wrapper.getComponent(ComidaForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.get('.alert-danger').text()).toBe('Ya hay un desayuno en el plan.')
    expect(push).not.toHaveBeenCalled()
  })

  it('mantiene el formulario si falla el catálogo y permite recargarlo', async () => {
    obtenerAlimentosParaElegir.mockRejectedValueOnce(new Error('Catálogo caído.'))
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    const form = wrapper.getComponent(ComidaForm)
    expect(form.props('errorCatalogo')).toBe('Catálogo caído.')
    expect(form.props('catalogo')).toEqual([])

    form.vm.$emit('recargar-catalogo')
    await flushPromises()
    expect(wrapper.getComponent(ComidaForm).props('catalogo')).toEqual(CATALOGO)
    expect(wrapper.getComponent(ComidaForm).props('errorCatalogo')).toBe('')
  })

  it('distingue un plan inexistente de un fallo recuperable', async () => {
    obtenerPlan.mockRejectedValueOnce(new HttpError(404, 'No existe.'))
    const noExiste = mount(Vista, OPCIONES)
    await flushPromises()
    expect(noExiste.get('[role="status"]').text()).toContain('no encontrad')
    expect(noExiste.find('button').exists()).toBe(false)

    obtenerPlan.mockRejectedValueOnce(new HttpError(500, 'Falla temporal.'))
    const conError = mount(Vista, OPCIONES)
    await flushPromises()
    expect(conError.get('[role="alert"]').text()).toContain('Falla temporal.')
    await conError.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(conError.findComponent(ComidaForm).exists()).toBe(true)
  })

  it('cancelar vuelve al plan y captura el rechazo de la navegación', async () => {
    const capturar = vi.fn()
    push.mockReturnValueOnce({ catch: capturar })
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(ComidaForm).vm.$emit('cancel')

    expect(push).toHaveBeenCalledWith({
      name: 'plan-alimentacion-detalle',
      params: { id: '4' },
      query: {},
    })
    expect(capturar).toHaveBeenCalledWith(expect.any(Function))
  })
})

describe('ComidaEditView (carga)', () => {
  it('carga la comida del plan en modo edición', async () => {
    const wrapper = mount(ComidaEditView, OPCIONES)
    await flushPromises()

    const form = wrapper.getComponent(ComidaForm)
    expect(form.props('modo')).toBe('edit')
    expect(form.props('valoresIniciales')).toEqual(COMIDA)
    expect(wrapper.text()).toContain('Actualiza la comida de las 07:30 del plan.')
  })

  it('avisa si la comida ya no forma parte del plan', async () => {
    route.params.idComida = '99'
    const wrapper = mount(ComidaEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.findComponent(ComidaForm).exists()).toBe(false)
    expect(wrapper.get('[role="status"]').text()).toContain(
      'La comida solicitada ya no forma parte de este plan.',
    )
  })

  it('pasa a "no encontrada" si la comida desaparece al guardar', async () => {
    actualizarComida.mockRejectedValue(new HttpError(404, 'La comida ya no existe.'))
    const wrapper = mount(ComidaEditView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(ComidaForm).vm.$emit('submit', {})
    await flushPromises()

    expect(wrapper.findComponent(ComidaForm).exists()).toBe(false)
    expect(wrapper.text()).toContain('Comida no encontrada')
  })
})

describe('ComidaCreateView (encabezado)', () => {
  it('nombra al usuario del plan', async () => {
    const wrapper = mount(ComidaCreateView, OPCIONES)
    await flushPromises()

    expect(wrapper.text()).toContain('Añade una comida al horario de Carlos.')
  })
})
