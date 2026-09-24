import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import UsuarioPlanAlimentacionView from '@/modules/usuarios/views/UsuarioPlanAlimentacionView.vue'
import { obtenerPlanAlimentacionUsuario } from '@/modules/usuarios/services/usuarios.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

const route = reactive({ params: { id: '5' } })

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal()),
  useRoute: () => route,
}))

vi.mock('@/modules/usuarios/services/usuarios.service', () => ({
  obtenerPlanAlimentacionUsuario: vi.fn(),
}))

// Forma de `GeneracionPlanAlimentacionResource` en la API.
const PLAN = {
  id: 3,
  nombre: 'Plan de volumen',
  objetivo: 'ganar_masa',
  fecha_inicio: '2026-09-01',
  fecha_fin: '2026-09-07',
  dias: [{ dia: 1 }, { dia: 2 }],
}

function montar() {
  return mount(UsuarioPlanAlimentacionView, { global: { stubs: { PageHeader: true } } })
}

beforeEach(() => {
  vi.clearAllMocks()
  route.params.id = '5'
})

describe('UsuarioPlanAlimentacionView', () => {
  it('resume el último plan generado del usuario', async () => {
    obtenerPlanAlimentacionUsuario.mockResolvedValue(PLAN)
    const wrapper = montar()
    await flushPromises()

    expect(obtenerPlanAlimentacionUsuario).toHaveBeenCalledWith('5')
    expect(wrapper.get('h2').text()).toBe('Plan de volumen')
    expect(wrapper.text()).toContain('Objetivo: ganar_masa')
    expect(wrapper.text()).toContain('2026-09-01 — 2026-09-07')
    expect(wrapper.text()).toContain('2 días planificados')
  })

  it('tolera un plan sin nombre, objetivo ni fechas', async () => {
    obtenerPlanAlimentacionUsuario.mockResolvedValue({ id: 4 })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('h2').text()).toBe('Plan de alimentación')
    expect(wrapper.text()).not.toContain('Objetivo:')
    expect(wrapper.text()).toContain('0 días planificados')
  })

  it('explica que no hay plan cuando la API responde 404', async () => {
    obtenerPlanAlimentacionUsuario.mockRejectedValue(
      new HttpError(404, 'El usuario no tiene un plan alimentario generado.'),
    )
    const wrapper = montar()
    await flushPromises()

    const estado = wrapper.get('[role="status"]')
    expect(estado.text()).toContain('No hay plan de alimentación')
    expect(estado.text()).toContain('no tiene un plan alimentario generado')
    expect(wrapper.find('button').exists()).toBe(false)
  })

  it('permite reintentar tras un error recuperable', async () => {
    obtenerPlanAlimentacionUsuario
      .mockRejectedValueOnce(new HttpError(500, 'Falla temporal.'))
      .mockResolvedValueOnce(PLAN)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Falla temporal.')
    await wrapper.get('button').trigger('click')
    await flushPromises()
    expect(wrapper.get('h2').text()).toBe('Plan de volumen')
  })

  it('descarta la respuesta de un usuario anterior', async () => {
    let resolverPrimero
    obtenerPlanAlimentacionUsuario
      .mockReturnValueOnce(new Promise((resolve) => (resolverPrimero = resolve)))
      .mockResolvedValueOnce({ ...PLAN, nombre: 'Plan actual' })
    const wrapper = montar()

    route.params.id = '6'
    await flushPromises()
    resolverPrimero({ ...PLAN, nombre: 'Plan obsoleto' })
    await flushPromises()

    expect(wrapper.get('h2').text()).toBe('Plan actual')
  })
})
