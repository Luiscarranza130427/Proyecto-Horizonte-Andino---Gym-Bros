import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import EjerciciosView from '@/modules/ejercicios/views/EjerciciosView.vue'
import {
  actualizarEstadoEjercicioEmpresa,
  desactivarEjercicio,
  obtenerEjercicios,
} from '@/modules/ejercicios/services/ejercicios.service'

const route = reactive({ query: {} })
const replace = vi.fn()
const tenantActual = reactive({ tenantId: null })

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ replace, push: vi.fn() }),
  }
})

vi.mock('@/modules/ejercicios/services/ejercicios.service', () => ({
  actualizarEstadoEjercicioEmpresa: vi.fn(),
  obtenerEjercicios: vi.fn(),
  desactivarEjercicio: vi.fn(),
}))

vi.mock('@/core/tenant/tenant.store', () => ({
  useTenantStore: () => tenantActual,
}))

const RESPUESTA = {
  items: [
    {
      id: 1,
      nombre: 'Press de banca',
      categoria: 'pecho',
      nivel: 'intermedio',
      equipo: 'barra',
      descripcion: 'Empuje horizontal.',
      seriesSugeridas: 4,
      repeticionesSugeridas: 8,
      usos: 154,
      estado: 'active',
      fechaRegistro: '2026-01-15',
    },
  ],
  paginacion: { pagina: 1, ultimaPagina: 1, porPagina: 8, total: 1, desde: 1, hasta: 1 },
}

function montar() {
  return mount(EjerciciosView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('EjerciciosView', () => {
  beforeEach(() => {
    route.query = {}
    replace.mockReset()
    obtenerEjercicios.mockReset()
    desactivarEjercicio.mockReset()
    actualizarEstadoEjercicioEmpresa.mockReset()
    sessionStorage.clear()
    tenantActual.tenantId = null
  })

  it('muestra el listado con sus etiquetas en español', async () => {
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Press de banca')
    // El catálogo guarda 'barra'; la tarjeta muestra la etiqueta legible.
    expect(wrapper.text()).toContain('Barra')
    expect(wrapper.text()).toContain('Ver detalle')
  })

  it('muestra el equipamiento recibido aunque no pertenezca al catálogo local', async () => {
    obtenerEjercicios.mockResolvedValue({
      ...RESPUESTA,
      items: [{ ...RESPUESTA.items[0], equipo: 'barra y banco' }],
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('barra y banco')
  })

  it('permite activar una relación sin configuración previa', async () => {
    tenantActual.tenantId = 15
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('.ejercicio__empresa-accion').text()).toBe('Activar')
    expect(wrapper.get('.ejercicio__empresa-accion').attributes('disabled')).toBeUndefined()
  })

  it('actualiza sólo el estado por empresa del ejercicio seleccionado', async () => {
    tenantActual.tenantId = 15
    obtenerEjercicios.mockResolvedValue({
      ...RESPUESTA,
      items: [{ ...RESPUESTA.items[0], estadoEmpresa: 'active' }],
    })
    actualizarEstadoEjercicioEmpresa.mockResolvedValue({
      estadoEmpresa: 'inactive',
      message: 'Estado del ejercicio actualizado para la empresa.',
    })
    const wrapper = montar()
    await flushPromises()

    await wrapper.get('.ejercicio__empresa-accion').trigger('click')
    await flushPromises()

    expect(actualizarEstadoEjercicioEmpresa).toHaveBeenCalledWith(15, 1, false)
    expect(wrapper.text()).toContain('Estado del ejercicio actualizado para la empresa.')
  })

  it('recarga los ejercicios al cambiar de empresa seleccionada', async () => {
    tenantActual.tenantId = 15
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    tenantActual.tenantId = 16
    await flushPromises()

    expect(obtenerEjercicios).toHaveBeenLastCalledWith(expect.objectContaining({ empresaId: 16 }))
  })

  it('usa únicamente los filtros disponibles en el servicio', async () => {
    route.query = { category: 'piernas', level: 'avanzado', equipment: 'barra', status: 'active' }
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerEjercicios).toHaveBeenCalledWith(
      expect.objectContaining({
        nivel: 'avanzado',
        estado: 'active',
      }),
    )
  })

  it('descarta un valor inventado en la URL antes de llegar al servicio', async () => {
    // Sin `permitidos`, un `?level=` cualquiera viajaría al backend.
    route.query = { level: 'sobrehumano' }
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    montar()
    await flushPromises()

    expect(obtenerEjercicios).toHaveBeenCalledWith(expect.objectContaining({ nivel: '' }))
  })

  it('distingue el vacío filtrado y permite limpiar', async () => {
    route.query = { search: 'no-existe' }
    obtenerEjercicios.mockResolvedValue({
      items: [],
      paginacion: { ...RESPUESTA.paginacion, total: 0, desde: 0, hasta: 0 },
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toMatch(/No encontramos|sin resultados/i)
    await wrapper.get('.ejercicios__estado button').trigger('click')
    expect(replace).toHaveBeenCalledWith({ name: 'ejercicios-listado' })
  })

  it('muestra un error recuperable y reintenta', async () => {
    obtenerEjercicios
      .mockRejectedValueOnce(new Error('Servicio no disponible.'))
      .mockResolvedValueOnce(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Servicio no disponible.')

    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(obtenerEjercicios).toHaveBeenCalledTimes(2)
    expect(wrapper.text()).toContain('Press de banca')
  })

  it('conserva la búsqueda a medio escribir al cambiar un filtro', async () => {
    // La misma regresión que ya se corrigió en Empresas y Usuarios: al venir del
    // composable compartido, debe cumplirse aquí sin escribir una línea más.
    vi.useFakeTimers()
    route.query = { search: 'pre' }
    obtenerEjercicios.mockResolvedValue(RESPUESTA)
    replace.mockImplementation(({ query = {} }) => {
      route.query = query
    })

    const wrapper = montar()
    await flushPromises()

    await wrapper.get('#buscar-ejercicio').setValue('press')
    await wrapper.get('#filtro-nivel').setValue('avanzado')
    await flushPromises()

    expect(wrapper.get('#buscar-ejercicio').element.value).toBe('press')
    expect(replace).toHaveBeenCalledTimes(1)
    expect(replace).toHaveBeenCalledWith({
      name: 'ejercicios-listado',
      query: { search: 'press', level: 'avanzado' },
    })

    vi.advanceTimersByTime(1000)
    await flushPromises()
    expect(replace).toHaveBeenCalledTimes(1)

    vi.useRealTimers()
  })
})
