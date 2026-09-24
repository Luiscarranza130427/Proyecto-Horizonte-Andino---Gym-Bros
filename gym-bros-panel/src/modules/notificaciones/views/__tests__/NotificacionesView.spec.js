import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import NotificacionesView from '@/modules/notificaciones/views/NotificacionesView.vue'
import NotificacionCard from '@/modules/notificaciones/components/NotificacionCard.vue'
import NotificacionForm from '@/modules/notificaciones/components/NotificacionForm.vue'
import {
  crearNotificacion,
  eliminarNotificacion,
  enviarNotificacionAhora,
  obtenerNotificacionesEnviadas,
  obtenerNotificacionesProgramadas,
  obtenerNotificacionesRecibidas,
} from '@/modules/notificaciones/services/notificaciones.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

const { mockProgramadas, mockEnviadas, mockRecibidas, replace } = vi.hoisted(() => ({
  mockProgramadas: [
    {
      id: 1,
      tipo: 'recordatorio',
      titulo: 'Mantenimiento del área de cardio',
      mensaje: 'Las cintas estarán en calibración el domingo.',
      fechaEnvio: '2026-10-01T10:00:00.000Z',
      enviada: false,
      leida: false,
    },
  ],
  mockEnviadas: [
    {
      id: 2,
      tipo: 'sistema',
      titulo: 'Nueva versión de Gym Bros',
      mensaje: 'Consulta todas las novedades en el perfil.',
      fechaEnvio: '2026-08-01T10:00:00.000Z',
      enviada: true,
      leida: true,
    },
  ],
  mockRecibidas: [
    {
      id: 3,
      tipo: 'rutina',
      titulo: 'Nueva rutina asignada',
      mensaje: 'Revisa tu rutina semanal.',
      fechaEnvio: '2026-09-20T10:00:00.000Z',
      enviada: true,
      leida: false,
    },
  ],
  replace: vi.fn(),
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ query: {} }),
  useRouter: () => ({ replace, push: vi.fn() }),
}))

vi.mock('@/core/auth/auth.store', () => ({
  useAuthStore: () => ({ rol: 'admin' }),
}))

vi.mock('@/core/tenant/tenant.store', () => ({
  useTenantStore: () => ({
    tenant: null,
    nombreTenant: 'Mi Gimnasio',
  }),
}))

vi.mock('@/modules/notificaciones/services/notificaciones.service', () => ({
  obtenerNotificacionesRecibidas: vi.fn(),
  obtenerNotificacionesProgramadas: vi.fn(),
  obtenerNotificacionesEnviadas: vi.fn(),
  crearNotificacion: vi.fn(),
  enviarNotificacionAhora: vi.fn(),
  eliminarNotificacion: vi.fn(),
}))

// Misma forma que `normalizarListado` da a la respuesta paginada de Laravel.
function paginaEnviadas(items = mockEnviadas, paginacion = {}) {
  return {
    items,
    paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 6, total: items.length, ...paginacion },
  }
}

function montar() {
  return mount(NotificacionesView, {
    global: {
      stubs: {
        PageHeader: {
          template: '<header><h1>{{ titulo }}</h1></header>',
          props: ['titulo'],
        },
        ConfirmDialog: {
          name: 'ConfirmDialog',
          props: ['abierto', 'mensaje'],
          emits: ['confirmar', 'cancelar'],
          template: '<div></div>',
        },
      },
    },
  })
}

async function abrirPestana(wrapper, indice) {
  await wrapper.findAll('.notificaciones__tab')[indice].trigger('click')
  await flushPromises()
}

describe('NotificacionesView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    vi.useRealTimers()
    replace.mockResolvedValue(undefined)
    obtenerNotificacionesRecibidas.mockResolvedValue(structuredClone(mockRecibidas))
    obtenerNotificacionesProgramadas.mockResolvedValue(structuredClone(mockProgramadas))
    obtenerNotificacionesEnviadas.mockResolvedValue(paginaEnviadas())
    crearNotificacion.mockResolvedValue({ id: 99, enviada: true })
    enviarNotificacionAhora.mockResolvedValue({ id: 1, enviada: true })
    eliminarNotificacion.mockResolvedValue({ ok: true })
  })

  it('renderiza Recibidas como la pestaña inicial', async () => {
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Notificaciones')
    const tabs = wrapper.findAll('.notificaciones__tab')
    expect(tabs).toHaveLength(4)
    expect(tabs[0].text()).toContain('Recibidas')
    expect(tabs[1].text()).toContain('Redactar')
    expect(tabs[2].text()).toContain('Programadas')
    expect(tabs[3].text()).toContain('Historial enviadas')
    expect(wrapper.text()).toContain('Nueva rutina asignada')
  })

  it('permite alternar a la pestaña de Programadas y muestra las notificaciones', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 2)

    expect(wrapper.text()).toContain('Mantenimiento del área de cardio')
  })

  it('permite alternar a la pestaña de Enviadas y muestra el historial', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 3)

    expect(wrapper.text()).toContain('Nueva versión de Gym Bros')
  })

  it('marca la pestaña activa sin declarar un patrón de pestañas que no implementa', async () => {
    const wrapper = montar()
    await flushPromises()

    const tabs = wrapper.findAll('.notificaciones__tab')
    expect(tabs[0].attributes('aria-current')).toBe('true')
    expect(tabs[1].attributes('aria-current')).toBeUndefined()
    expect(wrapper.find('[role="tab"]').exists()).toBe(false)
  })

  it('pagina el historial con el contrato del servicio (pagina / ultimaPagina)', async () => {
    obtenerNotificacionesEnviadas.mockResolvedValue(
      paginaEnviadas(mockEnviadas, { ultimaPagina: 3, total: 14 }),
    )
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 3)

    const pie = wrapper.get('.notificaciones__paginacion')
    expect(pie.text()).toContain('Página 1 de 3 (14')
    expect(pie.findAll('.notificaciones__btn-pagina').map((boton) => boton.text())).toEqual([
      '1',
      '2',
      '3',
    ])
    await pie.findAll('button').at(-1).trigger('click')
    expect(obtenerNotificacionesEnviadas).toHaveBeenLastCalledWith(
      expect.objectContaining({ pagina: 2, porPagina: 6 }),
    )
  })

  it('busca en el historial tras una pausa y descarta respuestas obsoletas', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 3)
    vi.useFakeTimers()
    obtenerNotificacionesEnviadas.mockClear()

    let resolverLenta
    obtenerNotificacionesEnviadas
      .mockReturnValueOnce(new Promise((resolve) => (resolverLenta = resolve)))
      .mockResolvedValueOnce(paginaEnviadas([{ ...mockEnviadas[0], titulo: 'Resultado actual' }]))

    const busqueda = wrapper.get('#busqueda-notif')
    expect(wrapper.get('label[for="busqueda-notif"]').text()).toBe('Buscar en el historial')
    expect(busqueda.attributes('maxlength')).toBe('150')
    await busqueda.setValue('ve')
    await busqueda.setValue('versión')
    expect(obtenerNotificacionesEnviadas).not.toHaveBeenCalled()

    await vi.advanceTimersByTimeAsync(300)
    expect(obtenerNotificacionesEnviadas).toHaveBeenCalledTimes(1)
    expect(obtenerNotificacionesEnviadas).toHaveBeenLastCalledWith(
      expect.objectContaining({ busqueda: 'versión', pagina: 1 }),
    )

    await wrapper.get('#filtro-tipo-notif').setValue('sistema')
    await flushPromises()
    resolverLenta(paginaEnviadas([{ ...mockEnviadas[0], titulo: 'Resultado obsoleto' }]))
    await flushPromises()

    expect(wrapper.text()).toContain('Resultado actual')
    expect(wrapper.text()).not.toContain('Resultado obsoleto')
  })

  it('tras crear lleva a Enviadas o a Programadas según el resultado', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 1)

    wrapper.getComponent(NotificacionForm).vm.$emit('submit', { titulo: '[QA] aviso' })
    await flushPromises()
    expect(replace).toHaveBeenLastCalledWith({ query: { tab: 'enviadas' } })
    expect(wrapper.get('[role="status"]').text()).toContain('enviada correctamente')

    await abrirPestana(wrapper, 1)
    crearNotificacion.mockResolvedValueOnce({ id: 100, enviada: false })
    wrapper.getComponent(NotificacionForm).vm.$emit('submit', { titulo: '[QA] luego' })
    await flushPromises()
    expect(replace).toHaveBeenLastCalledWith({ query: { tab: 'programadas' } })
    expect(obtenerNotificacionesProgramadas).toHaveBeenCalledTimes(2)
  })

  it('pasa los 422 al formulario y avisa de otros errores', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 1)

    crearNotificacion.mockRejectedValueOnce(
      new HttpError(422, 'Revisa los datos.', { titulo: ['El título es obligatorio.'] }),
    )
    wrapper.getComponent(NotificacionForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.getComponent(NotificacionForm).props('erroresServidor')).toEqual({
      titulo: ['El título es obligatorio.'],
    })

    crearNotificacion.mockRejectedValueOnce(new HttpError(500, 'La API no responde.'))
    wrapper.getComponent(NotificacionForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.get('.alert-danger').text()).toContain('La API no responde.')
  })

  it('envía ahora y cancela una programada tras confirmar', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 2)

    wrapper.getComponent(NotificacionCard).vm.$emit('enviar-ahora', 1)
    await flushPromises()
    expect(enviarNotificacionAhora).toHaveBeenCalledWith(1)
    expect(wrapper.get('[role="status"]').text()).toContain('enviada inmediatamente')

    wrapper.getComponent(NotificacionCard).vm.$emit('eliminar', mockProgramadas[0])
    await flushPromises()
    const dialogo = wrapper.getComponent({ name: 'ConfirmDialog' })
    expect(dialogo.props('abierto')).toBe(true)
    expect(dialogo.props('mensaje')).toContain('Mantenimiento del área de cardio')

    dialogo.vm.$emit('confirmar')
    await flushPromises()
    expect(eliminarNotificacion).toHaveBeenCalledWith(1)
    expect(wrapper.get('[role="status"]').text()).toContain('cancelada y eliminada')
  })

  it('duplica una enviada en el formulario de redacción', async () => {
    const wrapper = montar()
    await flushPromises()
    await abrirPestana(wrapper, 3)

    wrapper
      .getComponent(NotificacionCard)
      .vm.$emit('duplicar', { ...mockEnviadas[0], idEmpresas: 4 })
    await flushPromises()

    expect(wrapper.getComponent(NotificacionForm).props('valoresIniciales')).toEqual({
      tipo: 'sistema',
      titulo: 'Nueva versión de Gym Bros',
      mensaje: 'Consulta todas las novedades en el perfil.',
      idEmpresas: '4',
      programar: false,
      fechaEnvio: '',
    })
  })
})
