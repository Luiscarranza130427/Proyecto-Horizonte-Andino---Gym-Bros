import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { describe, expect, it, vi } from 'vitest'

import EmpresaDetailView from '@/modules/empresas/views/EmpresaDetailView.vue'
import { obtenerEmpresa } from '@/modules/empresas/services/empresas.service'

const route = reactive({ params: { id: '999999' }, query: {} })

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({
      push: vi.fn(() => Promise.resolve()),
      replace: vi.fn(() => Promise.resolve()),
    }),
  }
})

vi.mock('@/modules/empresas/services/empresas.service', () => ({
  obtenerEmpresa: vi.fn(),
  desactivarEmpresa: vi.fn(),
}))

describe('EmpresaDetailView', () => {
  it('muestra un estado 404 recuperable', async () => {
    obtenerEmpresa.mockRejectedValue({ status: 404, message: 'La empresa solicitada no existe.' })
    const wrapper = mount(EmpresaDetailView, {
      global: {
        stubs: {
          RouterLink: { template: '<a href="#"><slot /></a>' },
          Teleport: true,
        },
      },
    })
    await flushPromises()

    expect(wrapper.text()).toContain('Empresa no encontrada')
    expect(wrapper.text()).toContain('Volver a empresas')
  })
})
