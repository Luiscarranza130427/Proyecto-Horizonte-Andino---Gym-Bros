import { mount } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'

import NotificacionForm from '@/modules/notificaciones/components/NotificacionForm.vue'

vi.mock('@/modules/empresas/services/empresas.service', () => ({
  obtenerEmpresas: vi.fn().mockResolvedValue({
    items: [
      { id: 1, nombre: 'Iron Gym' },
      { id: 2, nombre: 'Powerhouse' },
    ],
  }),
}))

function montar(props = {}) {
  return mount(NotificacionForm, {
    props: { esAdministrador: true, ...props },
  })
}

describe('NotificacionForm', () => {
  it('exige título y mensaje antes de emitir', async () => {
    const wrapper = montar()

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-titulo').text()).toContain('título')
    expect(wrapper.get('#error-mensaje').text()).toContain('mensaje')
  })

  it('emite payload de notificación inmediata cuando los campos son válidos', async () => {
    const wrapper = montar()

    await wrapper.get('#notif-titulo').setValue('Aviso de mantenimiento')
    await wrapper.get('#notif-mensaje').setValue('El gimnasio abrirá a las 08:00 mañana.')

    await wrapper.get('form').trigger('submit')

    const emitido = wrapper.emitted('submit')
    expect(emitido).toBeDefined()
    expect(emitido[0][0]).toMatchObject({
      tipo: 'recordatorio',
      titulo: 'Aviso de mantenimiento',
      mensaje: 'El gimnasio abrirá a las 08:00 mañana.',
      programar: false,
      fechaEnvio: null,
      idEmpresas: null,
      alcance: 'todos',
    })
  })

  it('oculta los destinatarios individuales y limita a la empresa su propio alcance', async () => {
    const wrapper = montar({ esAdministrador: false })

    expect(wrapper.text()).not.toContain('Usuario individual')
    expect(wrapper.text()).not.toContain('Por empresa')
    expect(wrapper.text()).toContain('Todos los usuarios de mi empresa')
    expect(wrapper.find('#notif-empresa').exists()).toBe(false)
  })

  it('muestra el nombre remitente recibido en la vista previa', () => {
    const wrapper = montar({ nombreRemitente: 'Titan Gym' })

    expect(wrapper.find('.push-card__nombre-app').text()).toBe('Titan Gym')
  })

  it('exige empresa destinataria cuando el alcance es por empresa', async () => {
    const wrapper = montar()

    const radioEmpresa = wrapper.findAll('input[name="alcance"]')[1]
    await radioEmpresa.setValue(true)

    await wrapper.get('#notif-titulo').setValue('Aviso a sede')
    await wrapper.get('#notif-mensaje').setValue('Contenido para toda la empresa.')

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-empresa').text()).toContain('Selecciona una empresa')
  })

  it('exige fecha futura cuando se activa la programación', async () => {
    const wrapper = montar()

    await wrapper.get('#notif-titulo').setValue('Aviso programado')
    await wrapper.get('#notif-mensaje').setValue('Contenido que se enviará más adelante.')

    const checkboxProgramar = wrapper.get('input[name="programar"]')
    await checkboxProgramar.setValue(true)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-fecha').text()).toContain('fecha y hora')
  })
})
