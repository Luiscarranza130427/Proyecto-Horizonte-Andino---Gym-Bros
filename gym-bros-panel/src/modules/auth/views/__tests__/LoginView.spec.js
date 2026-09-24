import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import { createMemoryHistory, createRouter } from 'vue-router'

import { HttpError } from '@/core/api/http-error'
import { solicitarRestablecimientoContrasena } from '@/core/auth/auth.service'
import LoginView from '@/modules/auth/views/LoginView.vue'

vi.mock('@/core/auth/auth.service', () => ({
  iniciarSesion: vi.fn(),
  cerrarSesion: vi.fn(),
  solicitarRestablecimientoContrasena: vi.fn(),
}))

const vacia = { template: '<div />' }

function crearRouter() {
  return createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/login', name: 'login', component: vacia },
      { path: '/dashboard', name: 'dashboard', component: vacia },
    ],
  })
}

async function montarLogin() {
  const router = crearRouter()
  await router.push('/login')
  await router.isReady()

  return mount(LoginView, {
    global: { plugins: [createPinia(), router] },
  })
}

describe('LoginView', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  it('muestra el formulario con etiquetas asociadas a sus campos', async () => {
    const wrapper = await montarLogin()

    const correo = wrapper.get('input#correo')
    const contrasena = wrapper.get('input#contrasena')

    expect(wrapper.get('label[for="correo"]').text()).toBe('Correo electrónico')
    expect(wrapper.get('label[for="contrasena"]').text()).toBe('Contraseña')
    expect(correo.attributes('autocomplete')).toBe('username')
    expect(contrasena.attributes('autocomplete')).toBe('current-password')
    expect(wrapper.get('button[type="submit"]').text()).toContain('Entrar')
  })

  it('no muestra ningún mensaje de error antes de enviar', async () => {
    const wrapper = await montarLogin()

    expect(wrapper.find('[role="alert"]').exists()).toBe(false)
  })

  it('avisa de los campos vacíos en vez de dejar que falle la autenticación', async () => {
    const wrapper = await montarLogin()

    await wrapper.get('form').trigger('submit')

    expect(wrapper.get('[role="alert"]').text()).toBe('Introduce tu correo y tu contraseña.')
    expect(wrapper.get('input#correo').attributes('aria-invalid')).toBe('true')
  })

  it('solicita el enlace de recuperación y muestra el mensaje seguro del backend', async () => {
    vi.mocked(solicitarRestablecimientoContrasena).mockResolvedValue({
      message: 'Si el correo está registrado, recibirás las instrucciones.',
    })
    const wrapper = await montarLogin()

    await wrapper.get('.login__recuperar').trigger('click')
    await wrapper.get('#correo-recuperacion').setValue(' atleta@gymbros.test ')
    await wrapper.get('.login__recuperacion form').trigger('submit')
    await flushPromises()

    expect(solicitarRestablecimientoContrasena).toHaveBeenCalledWith('atleta@gymbros.test')
    expect(wrapper.get('[role="status"]').text()).toContain('Si el correo está registrado')
    expect(wrapper.text()).toContain('Después deberás iniciar sesión nuevamente.')
  })

  it('respeta Retry-After cuando el servidor limita las solicitudes', async () => {
    vi.mocked(solicitarRestablecimientoContrasena).mockRejectedValue(
      new HttpError({
        status: 429,
        message: 'Espera antes de volver a intentarlo.',
        retryAfter: '30',
      }),
    )
    const wrapper = await montarLogin()

    await wrapper.get('.login__recuperar').trigger('click')
    await wrapper.get('#correo-recuperacion').setValue('atleta@gymbros.test')
    await wrapper.get('.login__recuperacion form').trigger('submit')
    await flushPromises()

    expect(wrapper.text()).toContain('Reintenta en 30 s')
    expect(
      wrapper.get('.login__recuperacion button[type="submit"]').attributes('disabled'),
    ).toBeDefined()
  })

  it('ofrece reintentar cuando el servidor no está disponible', async () => {
    vi.mocked(solicitarRestablecimientoContrasena).mockRejectedValue(
      new HttpError({ status: 503, message: 'Servicio temporalmente no disponible.' }),
    )
    const wrapper = await montarLogin()

    await wrapper.get('.login__recuperar').trigger('click')
    await wrapper.get('#correo-recuperacion').setValue('atleta@gymbros.test')
    await wrapper.get('.login__recuperacion form').trigger('submit')
    await flushPromises()

    expect(wrapper.get('.login__reintentar').attributes('disabled')).toBeUndefined()
  })
})
