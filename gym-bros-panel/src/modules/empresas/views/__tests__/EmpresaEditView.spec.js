import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import EmpresaEditView from '@/modules/empresas/views/EmpresaEditView.vue'
import {
  guardarBannersEmpresa,
  obtenerBannersEmpresa,
  obtenerEmpresa,
} from '@/modules/empresas/services/empresas.service'

const route = reactive({ params: { id: '7' } })

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ push: vi.fn(() => Promise.resolve()) }),
  }
})

vi.mock('@/core/tenant/tenant.store', () => ({
  useTenantStore: () => ({ tenantId: null, fijarTenant: vi.fn() }),
}))

vi.mock('@/modules/empresas/services/empresas.service', () => ({
  obtenerEmpresa: vi.fn(),
  obtenerBannersEmpresa: vi.fn(),
  guardarBannersEmpresa: vi.fn(),
  actualizarEmpresa: vi.fn(),
}))

const empresa = {
  id: 7,
  nombre: 'Gym Bros Cajamarca',
  estado: 'active',
  horario_inicio_lunes: '06:00',
  horario_fin_lunes: '22:00',
}

const banners = [
  { numero: 1, imagen: 'uno.webp', imagenUrl: 'http://api.test/storage/uno.webp', enlace: '' },
  { numero: 2, imagen: '', imagenUrl: '', enlace: '' },
  { numero: 3, imagen: '', imagenUrl: '', enlace: '' },
]

describe('EmpresaEditView', () => {
  beforeEach(() => {
    vi.clearAllMocks()
    obtenerEmpresa.mockResolvedValue(empresa)
    obtenerBannersEmpresa.mockResolvedValue(banners)
    guardarBannersEmpresa.mockResolvedValue(banners)
  })

  it('entrega al formulario los horarios reales y carga los banners', async () => {
    const wrapper = mount(EmpresaEditView, {
      global: {
        stubs: {
          PageHeader: true,
          RouterLink: true,
          EmpresaForm: { name: 'EmpresaForm', props: ['valoresIniciales'], template: '<form />' },
          EmpresaBanners: { name: 'EmpresaBanners', props: ['banners'], template: '<section />' },
        },
      },
    })
    await flushPromises()

    expect(obtenerEmpresa).toHaveBeenCalledWith('7')
    expect(obtenerBannersEmpresa).toHaveBeenCalledWith(7)
    expect(wrapper.getComponent({ name: 'EmpresaForm' }).props('valoresIniciales')).toEqual(empresa)
    expect(wrapper.getComponent({ name: 'EmpresaBanners' }).props('banners')).toEqual(banners)
  })

  it('guarda los tres banners mediante el endpoint específico', async () => {
    const wrapper = mount(EmpresaEditView, {
      global: { stubs: { PageHeader: true, RouterLink: true, EmpresaForm: true } },
    })
    await flushPromises()

    wrapper.getComponent({ name: 'EmpresaBanners' }).vm.$emit('guardar', banners)
    await flushPromises()

    expect(guardarBannersEmpresa).toHaveBeenCalledWith(7, banners)
    expect(wrapper.text()).toContain('Banners actualizados correctamente')
  })
})
