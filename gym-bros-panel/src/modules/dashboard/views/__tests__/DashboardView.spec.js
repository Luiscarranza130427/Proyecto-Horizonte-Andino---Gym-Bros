import { flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import { useAuthStore } from '@/core/auth/auth.store'
import DashboardView from '@/modules/dashboard/views/DashboardView.vue'
import { obtenerBanners, obtenerDashboard } from '@/modules/dashboard/services/dashboard.service'
import { actualizarEmpresa, obtenerEmpresa } from '@/modules/empresas/services/empresas.service'

vi.mock('@/modules/dashboard/services/dashboard.service', () => ({
  obtenerBanners: vi.fn(),
  obtenerDashboard: vi.fn(),
}))
vi.mock('@/modules/empresas/services/empresas.service', () => ({
  actualizarEmpresa: vi.fn(),
  obtenerEmpresa: vi.fn(),
}))

const BANNERS = [
  {
    imagenUrl: '/banner.webp',
    contenido: 'Gestiona tu gimnasio desde un solo lugar',
    textoBoton: 'Ver usuarios',
    enlaceBoton: '/usuarios',
  },
  {
    imagenUrl: '/banner-2.webp',
    contenido: 'Segundo banner',
    textoBoton: 'Conocer más',
    enlaceBoton: '/planes',
  },
]

const DATOS = {
  metricas: [
    {
      id: 'empresas',
      etiqueta: 'Empresas',
      valor: 14,
      icono: 'bi-buildings-fill',
      tendencia: { valor: 2, prefijo: '+', detalle: 'este mes', tono: 'positivo' },
    },
    {
      id: 'usuarios',
      etiqueta: 'Usuarios',
      valor: 346,
      icono: 'bi-people-fill',
      tendencia: { valor: 8.4, sufijo: '%', detalle: 'este mes', tono: 'positivo' },
    },
    {
      id: 'entrenadores',
      etiqueta: 'Entrenadores',
      valor: 27,
      icono: 'bi-person-arms-up',
      tendencia: { valor: 1, detalle: 'este mes', tono: 'positivo' },
    },
    {
      id: 'rutinas',
      etiqueta: 'Rutinas activas',
      valor: 89,
      icono: 'bi-clipboard2-pulse-fill',
      tendencia: { valor: 0, detalle: 'sin cambios', tono: 'neutro' },
    },
  ],
  progreso: {
    titulo: 'Usuarios activos',
    descripcion: 'Últimos meses',
    unidad: 'usuarios activos',
    etiquetas: ['Jul', 'Ago'],
    valores: [317, 346],
    resumen: { etiqueta: 'Total', valor: 346, detalle: '+29' },
  },
  ejerciciosPopulares: [{ id: 1, nombre: 'Press de banca', categoria: 'Pecho', usos: 154 }],
  actividadReciente: [
    {
      id: 1,
      titulo: 'Nuevo usuario registrado',
      detalle: 'Carlos Ramírez',
      fecha: new Date().toISOString(),
      icono: 'bi-person-plus-fill',
    },
  ],
}

const RouterLinkStub = {
  props: ['to'],
  template: '<a href="#"><slot /></a>',
}

const EmpresaFormStub = {
  name: 'EmpresaForm',
  props: ['valoresIniciales', 'enviando', 'erroresServidor'],
  emits: ['submit', 'cancel'],
  template:
    '<form class="empresa-form-stub" @submit.prevent="$emit(\'submit\', valoresIniciales)" />',
}

function montarDashboard() {
  return mount(DashboardView, {
    global: {
      stubs: {
        RouterLink: RouterLinkStub,
        EmpresaForm: EmpresaFormStub,
      },
    },
  })
}

describe('DashboardView', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    const auth = useAuthStore()
    auth.usuario = {
      id: 1,
      nombre: 'Juanito Perezz',
      correo: 'juan@gmail.com',
      rol: 'Administrador',
    }
    auth.token = 'token-de-prueba'
    vi.resetAllMocks()
    obtenerBanners.mockResolvedValue(BANNERS)
    obtenerEmpresa.mockResolvedValue({ id: 1, nombre: 'Titan Gym' })
    actualizarEmpresa.mockResolvedValue({ id: 1, nombre: 'Titan Gym actualizado' })
  })

  it('mantiene el skeleton mientras el servicio está cargando', () => {
    obtenerDashboard.mockReturnValue(new Promise(() => {}))

    const wrapper = montarDashboard()

    expect(wrapper.text()).toContain('Cargando información del dashboard')
    expect(wrapper.findAll('.skeleton__metrica')).toHaveLength(4)
  })

  it('renderiza las cuatro métricas y las secciones operativas', async () => {
    obtenerDashboard.mockResolvedValue(DATOS)

    const wrapper = montarDashboard()
    await flushPromises()

    expect(wrapper.findAll('.metrica')).toHaveLength(4)
    expect(wrapper.text()).toContain('Gestiona tu gimnasio desde un solo lugar')
    expect(wrapper.text()).toContain('8.4 %')
  })

  it('muestra el error y recupera el contenido al reintentar', async () => {
    obtenerDashboard
      .mockRejectedValueOnce(new Error('Servicio no disponible.'))
      .mockResolvedValueOnce(DATOS)

    const wrapper = montarDashboard()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Servicio no disponible.')

    await wrapper.get('.dashboard__error button').trigger('click')
    await flushPromises()

    expect(obtenerDashboard).toHaveBeenCalledTimes(2)
    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
    expect(wrapper.text()).toContain('Indicadores principales')
  })

  it('mantiene visible el banner cuando falla el endpoint independiente del dashboard', async () => {
    obtenerDashboard.mockRejectedValue(new Error('El endpoint de métricas no existe.'))

    const wrapper = montarDashboard()
    await flushPromises()

    expect(wrapper.get('.banner').text()).toContain('Gestiona tu gimnasio desde un solo lugar')
    expect(wrapper.get('[role="alert"]').text()).toContain('El endpoint de métricas no existe.')
  })

  it('carga y actualiza debajo de los indicadores la empresa del resumen', async () => {
    obtenerDashboard.mockResolvedValue({ ...DATOS, empresaId: 1 })

    const wrapper = montarDashboard()
    await flushPromises()

    expect(obtenerEmpresa).toHaveBeenCalledWith(1)
    expect(wrapper.text()).toContain('Datos de la empresa')

    await wrapper.get('.empresa-form-stub').trigger('submit')
    await flushPromises()

    expect(actualizarEmpresa).toHaveBeenCalledWith(1, { id: 1, nombre: 'Titan Gym' })
    expect(wrapper.text()).toContain('Datos de la empresa actualizados correctamente')
  })
})
