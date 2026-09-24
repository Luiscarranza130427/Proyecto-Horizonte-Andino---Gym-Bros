import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'
import PlanesView from '@/modules/membresias/views/PlanesView.vue'
import {
  eliminarPlanComercial,
  obtenerPlanesComerciales,
} from '@/modules/membresias/services/membresias.service'

const route = reactive({ query: {} })
const replace = vi.fn(() => Promise.resolve())
const { mockPuedeGestionar } = vi.hoisted(() => ({ mockPuedeGestionar: vi.fn() }))

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ replace }),
  }
})

vi.mock('@/modules/membresias/services/membresias.service', () => ({
  obtenerPlanesComerciales: vi.fn(),
  eliminarPlanComercial: vi.fn(),
}))

vi.mock('@/core/auth/auth.store', () => ({
  useAuthStore: () => ({ can: mockPuedeGestionar }),
}))

const RESPUESTA = {
  items: [
    {
      id: 1,
      nombre: 'Impulso',
      descripcion: 'Plan inicial.',
      precioOriginal: 249,
      precioInicial: 189,
      duracionDias: 30,
      limiteUsuarios: 100,
      activo: true,
      contenido: 'Gestión de usuarios',
      enlaceWhatsapp: 'https://wa.me/51900000001',
    },
  ],
  paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 6, total: 1, desde: 1, hasta: 1 },
}

function montar(props = { esAdministracion: true }) {
  return mount(PlanesView, {
    props,
    global: {
      stubs: { RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' } },
    },
  })
}

describe('PlanesView', () => {
  beforeEach(() => {
    route.query = {}
    replace.mockReset()
    replace.mockResolvedValue(undefined)
    obtenerPlanesComerciales.mockReset()
    eliminarPlanComercial.mockReset()
    mockPuedeGestionar.mockReturnValue(true)
  })

  it('muestra el listado en tabla obtenido del servicio', async () => {
    obtenerPlanesComerciales.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Impulso')
    expect(wrapper.text()).toContain('Gestión de usuarios')
    expect(obtenerPlanesComerciales).toHaveBeenCalledWith(
      expect.objectContaining({ pagina: 1, porPagina: 6 }),
    )
  })

  it('permite filtrar por estado y búsqueda', async () => {
    obtenerPlanesComerciales.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    const selectEstado = wrapper.find('#filtro-estado-plan')
    await selectEstado.setValue('active')
    await flushPromises()

    expect(replace).toHaveBeenCalledWith(
      expect.objectContaining({
        query: expect.objectContaining({ estado: 'active' }),
      }),
    )
  })

  it('muestra el catálogo de adquisición sin acciones CRUD a usuarios no administradores', async () => {
    mockPuedeGestionar.mockReturnValue(false)
    obtenerPlanesComerciales.mockResolvedValue(RESPUESTA)
    const wrapper = montar({ esAdministracion: false })
    await flushPromises()

    expect(wrapper.text()).toContain('Adquirir plan')
    expect(wrapper.text()).not.toContain('Nuevo plan')
    expect(wrapper.text()).not.toContain('Editar')
    expect(wrapper.find('.btn-icono-accion--peligro').exists()).toBe(false)
    expect(wrapper.find('#filtro-estado-plan').exists()).toBe(false)
  })

  it('muestra un diálogo de confirmación y elimina un plan', async () => {
    obtenerPlanesComerciales.mockResolvedValue(RESPUESTA)
    eliminarPlanComercial.mockResolvedValue({ ok: true })
    const wrapper = montar()
    await flushPromises()

    const btnEliminar = wrapper.find('.btn-icono-accion--peligro')
    await btnEliminar.trigger('click')
    await flushPromises()

    const dialogo = wrapper.findComponent(ConfirmDialog)
    expect(dialogo.exists()).toBe(true)
    expect(dialogo.props('abierto')).toBe(true)
  })

  it('muestra el rechazo de la API en lugar de callarlo (plan con suscripciones)', async () => {
    obtenerPlanesComerciales.mockResolvedValue(RESPUESTA)
    eliminarPlanComercial.mockRejectedValue(
      Object.assign(new Error('El plan tiene suscripciones o compras asociadas.'), { status: 409 }),
    )
    const wrapper = montar()
    await flushPromises()

    await wrapper.find('.btn-icono-accion--peligro').trigger('click')
    await flushPromises()
    wrapper.findComponent(ConfirmDialog).vm.$emit('confirmar')
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('suscripciones o compras asociadas')
  })
})
