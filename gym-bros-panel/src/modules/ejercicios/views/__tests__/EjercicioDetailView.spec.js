import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import EjercicioDetailView from '@/modules/ejercicios/views/EjercicioDetailView.vue'
import {
  desactivarEjercicio,
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
  obtenerEjercicio: vi.fn(),
  desactivarEjercicio: vi.fn(),
}))

const EJERCICIO = {
  id: 1,
  nombre: 'Press de banca',
  categoria: 'pecho',
  tipo: 'fuerza',
  nivel: 'intermedio',
  equipo: 'barra',
  descripcion: 'Empuje horizontal para el pectoral mayor.',
  instrucciones: 'Mantén la espalda apoyada durante todo el movimiento.',
  enlaceVideo: 'https://example.com/video',
  imagen: 'https://example.com/press.webp',
  seriesSugeridas: 4,
  repeticionesSugeridas: 8,
  usos: 154,
  estado: 'active',
  fechaRegistro: '2026-01-15',
}

function montar() {
  return mount(EjercicioDetailView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('EjercicioDetailView', () => {
  beforeEach(() => {
    route.params = { id: '1' }
    route.query = {}
    push.mockReset().mockResolvedValue(undefined)
    replace.mockReset().mockResolvedValue(undefined)
    obtenerEjercicio.mockReset()
    desactivarEjercicio.mockReset()
  })

  it('muestra la ficha con las etiquetas legibles del catálogo', async () => {
    obtenerEjercicio.mockResolvedValue(EJERCICIO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Press de banca')
    expect(wrapper.text()).toContain('Empuje horizontal para el pectoral mayor.')
    // El servicio entrega 'barra'; la ficha muestra su etiqueta legible.
    expect(wrapper.text()).toContain('Barra')
    expect(wrapper.text()).toContain('Intermedio')
    expect(wrapper.text()).toContain('Fuerza')
    expect(wrapper.text()).toContain('Mantén la espalda apoyada durante todo el movimiento.')
    expect(wrapper.get('a[href="https://example.com/video"]').text()).toContain(
      'Ver video del ejercicio',
    )
    expect(wrapper.get('.detalle__imagen').attributes('src')).toBe('https://example.com/press.webp')
    expect(wrapper.get('.detalle__figura figcaption').text()).toContain('500 × 380 px')
    expect(wrapper.text()).not.toContain('Fecha de registro')
  })

  it('distingue un 404 de un fallo recuperable', async () => {
    obtenerEjercicio.mockRejectedValue(
      new HttpError({ status: 404, message: 'El ejercicio solicitado no existe.' }),
    )
    const wrapper = montar()
    await flushPromises()

    // Un 404 no ofrece «Reintentar»: reintentar no lo va a hacer aparecer.
    expect(wrapper.text()).toContain('no existe')
    expect(wrapper.find('[role="alert"] button').exists()).toBe(false)
  })

  it('ofrece reintentar cuando el fallo sí es recuperable', async () => {
    obtenerEjercicio
      .mockRejectedValueOnce(new HttpError({ status: 500, message: 'Error del servidor.' }))
      .mockResolvedValueOnce(EJERCICIO)
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()

    expect(obtenerEjercicio).toHaveBeenCalledTimes(2)
    expect(wrapper.text()).toContain('Press de banca')
  })

  it('consume el aviso de creación y lo retira de la URL', async () => {
    // Si no se retirara, reaparecería al recargar o al volver atrás.
    route.query = { notice: 'created' }
    obtenerEjercicio.mockResolvedValue(EJERCICIO)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('[role="status"]').text()).toMatch(/creado/i)
    expect(replace).toHaveBeenCalledWith(
      expect.objectContaining({ name: 'ejercicio-detalle', params: { id: '1' } }),
    )
  })

  it('desactiva y vuelve al listado anunciándolo', async () => {
    obtenerEjercicio.mockResolvedValue(EJERCICIO)
    desactivarEjercicio.mockResolvedValue({ ...EJERCICIO, estado: 'inactive' })
    const wrapper = montar()
    await flushPromises()

    const abrir = wrapper.findAll('button').find((b) => /desactivar/i.test(b.text()))
    expect(abrir, 'debería haber un botón para desactivar').toBeDefined()
    await abrir.trigger('click')
    await flushPromises()

    // El botón de confirmar vive DENTRO del diálogo: buscarlo por el rol evita
    // volver a pulsar el de la cabecera, que también dice «Desactivar».
    const dialogo = wrapper.get('[role="alertdialog"]')
    const confirmar = dialogo.findAll('button').find((b) => !/cancelar/i.test(b.text()))
    await confirmar.trigger('click')
    await flushPromises()

    expect(desactivarEjercicio).toHaveBeenCalledWith(1)
    expect(push).toHaveBeenCalledWith({
      name: 'ejercicios-listado',
      query: { notice: 'deactivated' },
    })
  })

  it('no ofrece desactivar un ejercicio que ya está inactivo', async () => {
    obtenerEjercicio.mockResolvedValue({ ...EJERCICIO, estado: 'inactive' })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.findAll('button').some((b) => /desactivar/i.test(b.text()))).toBe(false)
  })
})
