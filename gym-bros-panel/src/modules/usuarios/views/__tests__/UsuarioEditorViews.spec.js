import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import UsuarioCreateView from '@/modules/usuarios/views/UsuarioCreateView.vue'
import UsuarioEditView from '@/modules/usuarios/views/UsuarioEditView.vue'
import UsuarioForm from '@/modules/usuarios/components/UsuarioForm.vue'
import {
  actualizarUsuario,
  crearUsuario,
  obtenerOpcionesEmpresas,
  obtenerRolesAsignables,
  obtenerUsuario,
} from '@/modules/usuarios/services/usuarios.service'
import { HttpError } from '@/core/api/http-error'

enableAutoUnmount(afterEach)

const route = reactive({ params: { id: '7' }, query: {} })
const push = vi.fn()

vi.mock('vue-router', async (importOriginal) => ({
  ...(await importOriginal()),
  useRoute: () => route,
  useRouter: () => ({ push }),
}))

vi.mock('@/modules/usuarios/services/usuarios.service', () => ({
  actualizarUsuario: vi.fn(),
  crearUsuario: vi.fn(),
  obtenerOpcionesEmpresas: vi.fn(),
  obtenerRolesAsignables: vi.fn(),
  obtenerUsuario: vi.fn(),
}))

const EMPRESAS = [
  { id: 1, nombre: 'Titan Gym', estado: 'active' },
  { id: 2, nombre: 'Cerrado', estado: 'inactive' },
]

const USUARIO = {
  id: 7,
  nombre: 'Carlos',
  apellido: 'Ramírez',
  correo: 'carlos@gymbros.test',
  empresa: { id: 1, nombre: 'Titan Gym' },
}

const OPCIONES = {
  global: {
    stubs: {
      PageHeader: { props: ['titulo'], template: '<h1>{{ titulo }}</h1>' },
      RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
    },
  },
}

beforeEach(() => {
  vi.clearAllMocks()
  route.params.id = '7'
  push.mockResolvedValue(undefined)
  obtenerOpcionesEmpresas.mockResolvedValue(structuredClone(EMPRESAS))
  obtenerRolesAsignables.mockReturnValue([
    { valor: 'trainer', etiqueta: 'Entrenador' },
    { valor: 'member', etiqueta: 'Usuario' },
  ])
  obtenerUsuario.mockResolvedValue(structuredClone(USUARIO))
})

describe('UsuarioCreateView', () => {
  it('ofrece sólo empresas activas y los roles que la sesión puede asignar', async () => {
    const wrapper = mount(UsuarioCreateView, OPCIONES)
    await flushPromises()

    const form = wrapper.getComponent(UsuarioForm)
    expect(form.props('empresas')).toEqual([EMPRESAS[0]])
    expect(form.props('roles').map(({ valor }) => valor)).toEqual(['trainer', 'member'])
  })

  it('crea el usuario y abre su ficha con el aviso de creado', async () => {
    crearUsuario.mockResolvedValue({ id: 12 })
    const wrapper = mount(UsuarioCreateView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('submit', { nombre: 'Ana' })
    await flushPromises()

    expect(crearUsuario).toHaveBeenCalledWith({ nombre: 'Ana' })
    expect(push).toHaveBeenCalledWith({
      name: 'usuario-detalle',
      params: { id: 12 },
      query: { notice: 'created' },
    })
  })

  it('pasa los 422 al formulario y muestra otros errores como alerta', async () => {
    crearUsuario.mockRejectedValueOnce(
      new HttpError(422, 'Revisa los datos.', { correo: ['El correo ya esta registrado.'] }),
    )
    const wrapper = mount(UsuarioCreateView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.getComponent(UsuarioForm).props('erroresServidor')).toEqual({
      correo: ['El correo ya esta registrado.'],
    })
    expect(wrapper.find('[role="alert"]').exists()).toBe(false)

    crearUsuario.mockRejectedValueOnce(new HttpError(500, 'La API no responde.'))
    wrapper.getComponent(UsuarioForm).vm.$emit('submit', {})
    await flushPromises()
    expect(wrapper.get('[role="alert"]').text()).toBe('La API no responde.')
    expect(push).not.toHaveBeenCalled()
  })

  it('permite reintentar si no cargan las empresas', async () => {
    obtenerOpcionesEmpresas.mockRejectedValueOnce(new Error('Sin conexión.'))
    const wrapper = mount(UsuarioCreateView, OPCIONES)
    await flushPromises()

    expect(wrapper.get('[role="alert"]').text()).toContain('Sin conexión.')
    await wrapper.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(wrapper.findComponent(UsuarioForm).exists()).toBe(true)
  })

  it.each([
    ['UsuarioCreateView', UsuarioCreateView],
    ['UsuarioEditView', UsuarioEditView],
  ])('%s: cancelar vuelve al listado y captura el rechazo de la navegación', async (_, Vista) => {
    // router.push rechaza si otra navegación la interrumpe: sin .catch() queda
    // un rechazo sin capturar.
    const capturar = vi.fn()
    push.mockReturnValueOnce({ catch: capturar })
    const wrapper = mount(Vista, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('cancel')

    expect(push).toHaveBeenCalledWith({ name: 'usuarios-listado' })
    expect(capturar).toHaveBeenCalledWith(expect.any(Function))
  })
})

describe('UsuarioEditView', () => {
  it('carga el usuario en modo edición y titula con su nombre', async () => {
    const wrapper = mount(UsuarioEditView, OPCIONES)
    await flushPromises()

    expect(obtenerUsuario).toHaveBeenCalledWith('7')
    expect(wrapper.get('h1').text()).toBe('Editar a Carlos Ramírez')
    const form = wrapper.getComponent(UsuarioForm)
    expect(form.props('modo')).toBe('edit')
    expect(form.props('usuarioInicial')).toEqual(USUARIO)
  })

  it('guarda y vuelve a la ficha con el aviso de actualizado', async () => {
    actualizarUsuario.mockResolvedValue({ id: 7 })
    const wrapper = mount(UsuarioEditView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('submit', { nombre: 'Carlos' })
    await flushPromises()

    expect(actualizarUsuario).toHaveBeenCalledWith('7', { nombre: 'Carlos' })
    expect(push).toHaveBeenCalledWith({
      name: 'usuario-detalle',
      params: { id: 7 },
      query: { notice: 'updated' },
    })
  })

  it('lista los errores 422 junto al mensaje general', async () => {
    actualizarUsuario.mockRejectedValue(
      new HttpError(422, 'Revisa los datos.', { telefono: ['Máximo 12 caracteres.'] }),
    )
    const wrapper = mount(UsuarioEditView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('submit', {})
    await flushPromises()

    const alerta = wrapper.get('.alert-danger')
    expect(alerta.text()).toContain('Revisa los datos.')
    expect(alerta.text()).toContain('Máximo 12 caracteres.')
  })

  it('muestra "no encontrado" si el usuario desaparece al guardar', async () => {
    actualizarUsuario.mockRejectedValue(new HttpError(404, 'El usuario ya no existe.'))
    const wrapper = mount(UsuarioEditView, OPCIONES)
    await flushPromises()

    wrapper.getComponent(UsuarioForm).vm.$emit('submit', {})
    await flushPromises()

    expect(wrapper.findComponent(UsuarioForm).exists()).toBe(false)
    expect(wrapper.text()).toContain('Usuario no encontrado')
    expect(wrapper.find('button.btn-primary').exists()).toBe(false)
  })

  it('distingue un 404 de un error recuperable al cargar', async () => {
    obtenerUsuario.mockRejectedValueOnce(new HttpError(404, 'No existe.'))
    const noExiste = mount(UsuarioEditView, OPCIONES)
    await flushPromises()
    expect(noExiste.get('[role="status"]').text()).toContain('Usuario no encontrado')

    obtenerUsuario.mockRejectedValueOnce(new HttpError(500, 'Falla temporal.'))
    const conError = mount(UsuarioEditView, OPCIONES)
    await flushPromises()
    expect(conError.get('[role="alert"]').text()).toContain('Falla temporal.')
    await conError.get('[role="alert"] button').trigger('click')
    await flushPromises()
    expect(conError.findComponent(UsuarioForm).exists()).toBe(true)
  })

  it('descarta una respuesta obsoleta al cambiar de usuario', async () => {
    let resolverPrimero
    obtenerUsuario.mockReturnValueOnce(new Promise((resolve) => (resolverPrimero = resolve)))
    obtenerUsuario.mockResolvedValueOnce({ ...USUARIO, id: 8, nombre: 'Lucía' })
    const wrapper = mount(UsuarioEditView, OPCIONES)

    route.params.id = '8'
    await flushPromises()
    resolverPrimero({ ...USUARIO, nombre: 'Obsoleto' })
    await flushPromises()

    expect(wrapper.get('h1').text()).toBe('Editar a Lucía Ramírez')
  })
})
