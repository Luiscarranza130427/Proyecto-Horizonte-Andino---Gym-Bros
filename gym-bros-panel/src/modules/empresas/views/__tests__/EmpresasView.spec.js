import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import EmpresasView from '@/modules/empresas/views/EmpresasView.vue'
import { obtenerEmpresas, eliminarEmpresa } from '@/modules/empresas/services/empresas.service'

const route = reactive({ query: {} })
const replace = vi.fn()

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ replace, push: vi.fn() }),
  }
})

vi.mock('@/modules/empresas/services/empresas.service', () => ({
  obtenerEmpresas: vi.fn(),
  desactivarEmpresa: vi.fn(),
  eliminarEmpresa: vi.fn(),
}))

const RESPUESTA = {
  items: [
    {
      id: 1,
      nombre: 'Power Gym',
      gerente: 'Mariana Torres',
      ruc: '20100000001',
      correo: 'contacto@powergym.test',
      telefono: '+51 910000001',
      region: 'Lima',
      direccion: 'Av. Arequipa 1840',
      sitioWeb: 'https://powergym.example',
      estado: 'active',
      usuarios: 86,
      fechaRegistro: '2024-01-15',
      logoUrl: '',
    },
  ],
  paginacion: {
    pagina: 1,
    ultimaPagina: 1,
    porPagina: 8,
    total: 1,
    desde: 1,
    hasta: 1,
  },
}

const RouterLinkStub = {
  props: ['to'],
  template: '<a href="#"><slot /></a>',
}

function montar() {
  return mount(EmpresasView, {
    global: { stubs: { RouterLink: RouterLinkStub, Teleport: true } },
  })
}

describe('EmpresasView', () => {
  beforeEach(() => {
    route.query = {}
    replace.mockReset()
    obtenerEmpresas.mockReset()
    eliminarEmpresa.mockReset()
  })

  it('muestra filas skeleton mientras el servicio está cargando', () => {
    obtenerEmpresas.mockReturnValue(new Promise(() => {}))
    const wrapper = montar()

    expect(wrapper.findAll('.tabla__skeleton')).toHaveLength(6)
  })

  it('renderiza el listado normalizado', async () => {
    obtenerEmpresas.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Power Gym')
    expect(wrapper.text()).toContain('Mostrando 1–1 de 1 empresas')
  })

  it('cancelar no elimina y los botones no envían formularios', async () => {
    obtenerEmpresas.mockResolvedValue(RESPUESTA)
    const wrapper = montar()
    await flushPromises()
    const abrir = wrapper.get('[aria-label="Eliminar Power Gym"]')
    expect(abrir.attributes('type')).toBe('button')
    await abrir.trigger('click')
    expect(wrapper.get('[role="alertdialog"]').text()).toContain('todos sus usuarios')
    const botones = wrapper.findAll('[role="alertdialog"] button')
    expect(botones[1].attributes('type')).toBe('button')
    await botones[0].trigger('click')
    expect(eliminarEmpresa).not.toHaveBeenCalled()
    expect(wrapper.find('[role="alertdialog"]').exists()).toBe(false)
  })

  it('espera la eliminación, bloquea duplicados y recarga el listado con el mensaje del servidor', async () => {
    obtenerEmpresas.mockResolvedValue(RESPUESTA)
    let resolver
    eliminarEmpresa.mockReturnValue(
      new Promise((resolve) => {
        resolver = resolve
      }),
    )
    const wrapper = montar()
    await flushPromises()
    await wrapper.get('[aria-label="Eliminar Power Gym"]').trigger('click')
    await wrapper.get('[role="alertdialog"] .btn-danger').trigger('click')
    expect(eliminarEmpresa).toHaveBeenCalledExactlyOnceWith(1)
    expect(wrapper.get('[role="alertdialog"] .btn-danger').element.disabled).toBe(true)
    expect(wrapper.text()).toContain('Eliminando…')
    obtenerEmpresas.mockResolvedValue({
      items: [],
      paginacion: { ...RESPUESTA.paginacion, total: 0 },
    })
    resolver({ message: 'Empresa y usuarios eliminados por el servidor.' })
    await flushPromises()
    expect(wrapper.find('[role="alertdialog"]').exists()).toBe(false)
    expect(obtenerEmpresas).toHaveBeenCalledTimes(2)
    expect(wrapper.text()).toContain('Empresa y usuarios eliminados por el servidor.')
    expect(wrapper.text()).toContain('Aún no hay empresas registradas')
  })

  it.each([422, 404, 409, 500])(
    'muestra el error HTTP %s y permite reintentar sin anunciar éxito',
    async (status) => {
      obtenerEmpresas.mockResolvedValue(RESPUESTA)
      eliminarEmpresa.mockRejectedValue({
        response: {
          status,
          data: {
            message: `Error ${status}`,
            errors: { confirmar_eliminacion: ['Detalle de validación'] },
          },
        },
      })
      const wrapper = montar()
      await flushPromises()
      await wrapper.get('[aria-label="Eliminar Power Gym"]').trigger('click')
      await wrapper.get('[role="alertdialog"] .btn-danger').trigger('click')
      await flushPromises()
      expect(wrapper.get('[role="alertdialog"]').text()).toContain(`Error ${status}`)
      expect(wrapper.get('[role="alertdialog"]').text()).toContain('Detalle de validación')
      expect(wrapper.get('[role="alertdialog"] .btn-danger').element.disabled).toBe(false)
      expect(wrapper.find('.empresas__exito').exists()).toBe(false)
      expect(obtenerEmpresas).toHaveBeenCalledTimes(1)
    },
  )

  it('distingue el vacío por filtros y permite limpiarlos', async () => {
    route.query = { search: 'empresa-imposible-12345' }
    obtenerEmpresas.mockResolvedValue({
      items: [],
      paginacion: { ...RESPUESTA.paginacion, total: 0, desde: 0, hasta: 0 },
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('No encontramos resultados')
    await wrapper.get('.empresas__estado button').trigger('click')
    expect(replace).toHaveBeenCalledWith({ name: 'empresas-listado' })
  })

  it('muestra el estado vacío general sin sugerir limpiar filtros', async () => {
    obtenerEmpresas.mockResolvedValue({
      items: [],
      paginacion: { ...RESPUESTA.paginacion, total: 0, desde: 0, hasta: 0 },
    })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Aún no hay empresas registradas')
    expect(wrapper.text()).toContain('Registra tu primera empresa')
    expect(wrapper.text()).not.toContain('Limpiar filtros')
  })

  it('conserva la búsqueda a medio escribir al cambiar el estado', async () => {
    // La URL va por detrás de la caja: refleja un rebote anterior ('pow'),
    // mientras el usuario ya ha escrito 'power'.
    vi.useFakeTimers()
    route.query = { search: 'pow' }
    obtenerEmpresas.mockResolvedValue(RESPUESTA)
    // Se imita al router de verdad: una navegación cambia la ruta y eso vuelve
    // a disparar la carga. Sin esto el fallo no se reproduce.
    replace.mockImplementation(({ query = {} }) => {
      route.query = query
    })

    const wrapper = montar()
    await flushPromises()

    await wrapper.get('#buscar-empresa').setValue('power')
    await wrapper.findAll('input[name="estado-empresa"]')[1].trigger('change')
    await flushPromises()

    // La caja conserva lo tecleado en lugar de revertir al 'pow' de la URL...
    expect(wrapper.get('#buscar-empresa').element.value).toBe('power')
    // ...y se navega una sola vez, llevando búsqueda y estado juntos.
    expect(replace).toHaveBeenCalledTimes(1)
    expect(replace).toHaveBeenCalledWith({
      name: 'empresas-listado',
      query: { search: 'power', estado_suscripcion: 'Activo' },
    })

    // El rebote pendiente quedó cancelado: no hay una segunda navegación tardía.
    vi.advanceTimersByTime(1000)
    await flushPromises()
    expect(replace).toHaveBeenCalledTimes(1)

    vi.useRealTimers()
  })

  it('muestra error y reintenta la carga', async () => {
    obtenerEmpresas
      .mockRejectedValueOnce(new Error('Servicio no disponible.'))
      .mockResolvedValueOnce(RESPUESTA)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Servicio no disponible.')
    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()

    expect(obtenerEmpresas).toHaveBeenCalledTimes(2)
    expect(wrapper.text()).toContain('Power Gym')
  })
})
