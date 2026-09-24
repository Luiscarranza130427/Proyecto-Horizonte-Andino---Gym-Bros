import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PerfilSeguridadForm from '../PerfilSeguridadForm.vue'

describe('PerfilSeguridadForm.vue', () => {
  const sesionesMock = [
    {
      id: '1',
      dispositivo: 'Chrome Windows',
      ubicacion: 'Lima',
      ip: '190.1.1.1',
      esActual: true,
      ultimoAcceso: 'Activo',
    },
    {
      id: '2',
      dispositivo: 'App iPhone',
      ubicacion: 'Lima',
      ip: '181.1.1.1',
      esActual: false,
      ultimoAcceso: 'Ayer',
    },
  ]

  it('valida que las contraseñas coincidan antes de emitir', async () => {
    const wrapper = mount(PerfilSeguridadForm, {
      props: {
        sesiones: sesionesMock,
        cambiandoClave: false,
        cerrandoSesiones: false,
      },
    })

    await wrapper.find('#seguridad-actual').setValue('admin123')
    await wrapper.find('#seguridad-nueva').setValue('nuevaClave2026')
    await wrapper.find('#seguridad-confirmacion').setValue('distintaClave')
    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.emitted('cambiar-clave')).toBeFalsy()
    expect(wrapper.text()).toContain('Las contraseñas no coinciden.')
  })

  it('emite cambiar-clave con datos válidos', async () => {
    const wrapper = mount(PerfilSeguridadForm, {
      props: {
        sesiones: sesionesMock,
        cambiandoClave: false,
        cerrandoSesiones: false,
      },
    })

    await wrapper.find('#seguridad-actual').setValue('admin123')
    await wrapper.find('#seguridad-nueva').setValue('nuevaClave2026')
    await wrapper.find('#seguridad-confirmacion').setValue('nuevaClave2026')
    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.emitted('cambiar-clave')).toBeTruthy()
    expect(wrapper.emitted('cambiar-clave')[0][0]).toEqual({
      actual: 'admin123',
      nueva: 'nuevaClave2026',
      confirmacion: 'nuevaClave2026',
    })
  })

  it('emite cerrar-otras-sesiones al presionar el botón correspondiente', async () => {
    const wrapper = mount(PerfilSeguridadForm, {
      props: {
        sesiones: sesionesMock,
      },
    })

    const btnCerrar = wrapper.find('.btn-cerrar-sesiones')
    expect(btnCerrar.exists()).toBe(true)
    await btnCerrar.trigger('click')
    expect(wrapper.emitted('cerrar-otras-sesiones')).toBeTruthy()
  })
  it.each([
    ['corta', 'Clave2026', 'al menos 12'],
    ['sin números', 'claveSinNumerosLarga', 'letras y números'],
    ['sin letras', '123456789012', 'letras y números'],
    ['igual a la actual', 'admin1234567', 'distinta de la actual'],
  ])('rechaza una clave %s como lo haría la API', async (_caso, clave, mensaje) => {
    const wrapper = mount(PerfilSeguridadForm, { props: { sesiones: sesionesMock } })
    await wrapper.find('#seguridad-actual').setValue('admin1234567')
    await wrapper.find('#seguridad-nueva').setValue(clave)
    await wrapper.find('#seguridad-confirmacion').setValue(clave)
    await wrapper.find('form').trigger('submit')

    expect(wrapper.emitted('cambiar-clave')).toBeUndefined()
    expect(wrapper.text()).toContain(mensaje)
  })
})
