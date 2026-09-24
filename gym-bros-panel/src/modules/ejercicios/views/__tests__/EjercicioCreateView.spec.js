import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import EjercicioCreateView from '@/modules/ejercicios/views/EjercicioCreateView.vue'
import EjercicioEditView from '@/modules/ejercicios/views/EjercicioEditView.vue'
import {
  actualizarEjercicio,
  crearEjercicio,
  obtenerEjercicio,
} from '@/modules/ejercicios/services/ejercicios.service'
import { HttpError } from '@/core/api/http-error'

const route = reactive({ params: { id: '1' }, query: {} })
const push = vi.fn(() => Promise.resolve())
const replace = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ push, replace }) }
})

vi.mock('@/modules/ejercicios/services/ejercicios.service', () => ({
  crearEjercicio: vi.fn(),
  actualizarEjercicio: vi.fn(),
  obtenerEjercicio: vi.fn(),
  obtenerGruposMusculares: vi
    .fn()
    .mockResolvedValue([{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }]),
}))

const EJERCICIO = {
  id: 1,
  nombre: 'Press de banca',
  tipo: 'fuerza',
  nivel: 'intermedio',
  equipamiento: 'barra',
  descripcion: 'Empuje horizontal.',
  instrucciones: 'Empuja con control.',
  imagenEjercicio: 'ejercicios/press.webp',
  idGruposMusculares: 1,
  usos: 154,
  estado: 'active',
  fechaRegistro: '2026-01-15',
}

const OPCIONES = {
  global: {
    stubs: { RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' } },
  },
}

async function completar(wrapper) {
  await wrapper.get('#ejercicio-nombre').setValue('Hip thrust')
  await wrapper.get('#ejercicio-tipo').setValue('fuerza')
  await wrapper.get('#ejercicio-nivel').setValue('intermedio')
  await wrapper.get('#ejercicio-equipamiento').setValue('barra')
  await wrapper.get('#ejercicio-grupo').setValue('1')
  await wrapper.get('#ejercicio-instrucciones').setValue('Empuja con control.')
  await adjuntarImagen(wrapper)
}

/** jsdom no implementa createObjectURL ni deja escribir en input.files. */
async function adjuntarImagen(wrapper) {
  globalThis.URL.createObjectURL ??= () => 'blob:vista-previa'
  globalThis.URL.revokeObjectURL ??= () => {}
  const input = wrapper.get('#ejercicio-imagen')
  Object.defineProperty(input.element, 'files', {
    configurable: true,
    value: [new File(['x'], 'ejercicio.png', { type: 'image/png' })],
  })
  await input.trigger('change')
}

beforeEach(() => {
  route.params = { id: '1' }
  route.query = {}
  push.mockReset().mockResolvedValue(undefined)
  replace.mockReset().mockResolvedValue(undefined)
  crearEjercicio.mockReset()
  actualizarEjercicio.mockReset()
  obtenerEjercicio.mockReset()
})

describe('EjercicioCreateView', () => {
  it('crea y lleva al detalle anunciando el alta', async () => {
    crearEjercicio.mockResolvedValue({ ...EJERCICIO, id: 31, nombre: 'Hip thrust' })
    const wrapper = mount(EjercicioCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(crearEjercicio).toHaveBeenCalledWith(
      expect.objectContaining({ nombre: 'Hip thrust', tipo: 'fuerza' }),
    )
    expect(push).toHaveBeenCalledWith({
      name: 'ejercicio-detalle',
      params: { id: 31 },
      query: { notice: 'created' },
    })
  })

  it('reparte los errores 422 por campo sin salir de la pantalla', async () => {
    crearEjercicio.mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'Revisa los datos introducidos.',
        errors: { nombre: ['Ya existe un ejercicio con este nombre.'] },
      }),
    )
    const wrapper = mount(EjercicioCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(push).not.toHaveBeenCalled()
    expect(wrapper.text()).toContain('Ya existe un ejercicio con este nombre.')
  })

  it('muestra en cabecera un fallo que no es de validación', async () => {
    crearEjercicio.mockRejectedValue(
      new HttpError({ status: 500, message: 'Error interno del servidor.' }),
    )
    const wrapper = mount(EjercicioCreateView, OPCIONES)

    await completar(wrapper)
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Error interno del servidor.')
  })
})

describe('EjercicioEditView', () => {
  it('carga el ejercicio y guarda los cambios', async () => {
    obtenerEjercicio.mockResolvedValue(EJERCICIO)
    actualizarEjercicio.mockResolvedValue({ ...EJERCICIO, nivel: 'avanzado' })
    const wrapper = mount(EjercicioEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.get('#ejercicio-nombre').element.value).toBe('Press de banca')

    await wrapper.get('#ejercicio-nivel').setValue('avanzado')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(actualizarEjercicio).toHaveBeenCalledWith(
      '1',
      expect.objectContaining({ nivel: 'avanzado' }),
    )
    expect(push).toHaveBeenCalledWith({
      name: 'ejercicio-detalle',
      params: { id: 1 },
      query: { notice: 'updated' },
    })
  })

  it('trata un 404 como pantalla propia, no como error recuperable', async () => {
    obtenerEjercicio.mockRejectedValue(
      new HttpError({ status: 404, message: 'El ejercicio solicitado no existe.' }),
    )
    const wrapper = mount(EjercicioEditView, OPCIONES)
    await flushPromises()

    expect(wrapper.text()).toContain('no existe')
    expect(wrapper.find('form').exists()).toBe(false)
  })
})
