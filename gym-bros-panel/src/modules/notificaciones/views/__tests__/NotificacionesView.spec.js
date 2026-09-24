import { flushPromises, mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import NotificacionesView from '@/modules/notificaciones/views/NotificacionesView.vue'

const { mockProgramadas, mockEnviadas, mockRecibidas } = vi.hoisted(() => ({
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
}))

vi.mock('vue-router', () => ({
  useRoute: () => ({ query: {} }),
  useRouter: () => ({ replace: vi.fn(), push: vi.fn() }),
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
  obtenerNotificacionesRecibidas: vi.fn().mockResolvedValue(mockRecibidas),
  obtenerNotificacionesProgramadas: vi.fn().mockResolvedValue(mockProgramadas),
  obtenerNotificacionesEnviadas: vi.fn().mockResolvedValue({
    items: mockEnviadas,
    paginacion: { total: 1, paginaActual: 1, totalPaginas: 1 },
  }),
  crearNotificacion: vi.fn().mockResolvedValue({ id: 99, enviada: true }),
  enviarNotificacionAhora: vi.fn().mockResolvedValue({ id: 1, enviada: true }),
  eliminarNotificacion: vi.fn().mockResolvedValue({ ok: true }),
}))

function montar() {
  return mount(NotificacionesView, {
    global: {
      stubs: {
        PageHeader: {
          template: '<header><h1>{{ titulo }}</h1></header>',
          props: ['titulo'],
        },
        ConfirmDialog: true,
      },
    },
  })
}

describe('NotificacionesView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
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

    const tabs = wrapper.findAll('.notificaciones__tab')
    await tabs[2].trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Mantenimiento del área de cardio')
  })

  it('permite alternar a la pestaña de Enviadas y muestra el historial', async () => {
    const wrapper = montar()
    await flushPromises()

    const tabs = wrapper.findAll('.notificaciones__tab')
    await tabs[3].trigger('click')
    await flushPromises()

    expect(wrapper.text()).toContain('Nueva versión de Gym Bros')
  })
})
