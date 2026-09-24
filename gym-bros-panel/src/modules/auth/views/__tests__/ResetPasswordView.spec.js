import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises, mount } from '@vue/test-utils'
import { createMemoryHistory, createRouter } from 'vue-router'

import { HttpError } from '@/core/api/http-error'
import { restablecerContrasena } from '@/core/auth/auth.service'
import ResetPasswordView from '@/modules/auth/views/ResetPasswordView.vue'

vi.mock('@/core/auth/auth.service', () => ({ restablecerContrasena: vi.fn() }))

const vacia = { template: '<div />' }

async function montar(fragmento = '#correo=atleta%40gymbros.test&token=token-seguro') {
  window.history.replaceState(null, '', `/restablecer-contrasena${fragmento}`)
  const router = createRouter({
    history: createMemoryHistory(),
    routes: [
      { path: '/restablecer-contrasena', name: 'restablecer-contrasena', component: vacia },
      { path: '/login', name: 'login', component: vacia },
    ],
  })
  await router.push('/restablecer-contrasena')
  await router.isReady()
  return mount(ResetPasswordView, { global: { plugins: [router] } })
}

describe('ResetPasswordView', () => {
  beforeEach(() => vi.clearAllMocks())

  it('lee los secretos desde el fragmento y lo retira de la URL', async () => {
    const wrapper = await montar()

    expect(wrapper.get('#restablecer-correo').element.value).toBe('atleta@gymbros.test')
    expect(window.location.hash).toBe('')
  })

  it('valida mínimo, letras y números antes de enviar', async () => {
    const wrapper = await montar()
    await wrapper.get('#restablecer-password').setValue('abcdefghijkl')
    await wrapper.get('#restablecer-confirmacion').setValue('abcdefghijkl')
    await wrapper.get('form').trigger('submit')

    expect(restablecerContrasena).not.toHaveBeenCalled()
    expect(wrapper.text()).toContain('debe incluir letras y números')
  })

  it('envía correo, token y las dos contraseñas sin iniciar sesión', async () => {
    vi.mocked(restablecerContrasena).mockResolvedValue({ message: 'Contraseña actualizada.' })
    const wrapper = await montar()
    await wrapper.get('#restablecer-password').setValue('NuevaClave2026')
    await wrapper.get('#restablecer-confirmacion').setValue('NuevaClave2026')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(restablecerContrasena).toHaveBeenCalledWith({
      correo: 'atleta@gymbros.test',
      token: 'token-seguro',
      password: 'NuevaClave2026',
      password_confirmation: 'NuevaClave2026',
    })
    expect(wrapper.text()).toContain('Contraseña actualizada.')
    expect(wrapper.find('form').exists()).toBe(false)
  })

  it('muestra el error de token devuelto por Laravel', async () => {
    vi.mocked(restablecerContrasena).mockRejectedValue(
      new HttpError({
        status: 422,
        message: 'El enlace de recuperación ya no es válido.',
        errors: { token: ['El token venció.'] },
      }),
    )
    const wrapper = await montar()
    await wrapper.get('#restablecer-password').setValue('NuevaClave2026')
    await wrapper.get('#restablecer-confirmacion').setValue('NuevaClave2026')
    await wrapper.get('form').trigger('submit')
    await flushPromises()

    expect(wrapper.text()).toContain('El token venció.')
  })
})
