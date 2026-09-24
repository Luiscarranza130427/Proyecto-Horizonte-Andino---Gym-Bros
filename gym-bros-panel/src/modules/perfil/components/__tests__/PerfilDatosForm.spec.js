import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PerfilDatosForm from '../PerfilDatosForm.vue'

describe('PerfilDatosForm.vue', () => {
  const perfilMock = {
    nombre: 'Titan Gym',
    nombre_gerente: 'Carlos Mendoza',
    correo: 'contacto@gymbros.pe',
    telefono: '976 123 456',
    ruc: '20609876541',
    region: 'Junín',
    direccion: 'Av. Hoyos Rubio 123, Cajamarca',
    enlace_web: 'https://gymbros.pe',
  }

  it('rellena los campos con los datos de la sede suministrada', () => {
    const wrapper = mount(PerfilDatosForm, {
      props: {
        perfil: perfilMock,
        guardando: false,
      },
    })

    const inputNombre = wrapper.find('#empresa-nombre')
    const inputGerente = wrapper.find('#empresa-gerente')
    expect(inputNombre.element.value).toBe('Titan Gym')
    expect(inputGerente.element.value).toBe('Carlos Mendoza')
  })

  it('emite el evento guardar cuando el formulario es válido', async () => {
    const wrapper = mount(PerfilDatosForm, {
      props: {
        perfil: perfilMock,
        guardando: false,
      },
    })

    await wrapper.find('form').trigger('submit.prevent')
    expect(wrapper.emitted('guardar')).toBeTruthy()
    expect(wrapper.emitted('guardar')[0][0]).toEqual(
      expect.objectContaining({
        nombre: 'Titan Gym',
        // Sin separadores y con la región tal como la acepta la API (sin tilde).
        telefono: '976123456',
        region: 'Junin',
      }),
    )
  })

  it('rechaza un teléfono que no cabe en la columna y un correo inválido', async () => {
    const wrapper = mount(PerfilDatosForm, {
      props: { perfil: { ...perfilMock, telefono: '+51 976 123 456', correo: 'sin-arroba' } },
    })

    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.emitted('guardar')).toBeFalsy()
    expect(wrapper.get('#error-empresa-telefono').text()).toContain('de 6 a 9 dígitos')
    expect(wrapper.get('#error-empresa-correo').text()).toBe('Ingresa un correo válido.')
    expect(wrapper.get('#empresa-correo').attributes('aria-describedby')).toBe(
      'error-empresa-correo',
    )
    expect(wrapper.get('#empresa-ruc').attributes('maxlength')).toBe('12')
  })

  it('muestra error de validación si el nombre está vacío', async () => {
    const wrapper = mount(PerfilDatosForm, {
      props: {
        perfil: { ...perfilMock, nombre: '' },
      },
    })

    await wrapper.find('#empresa-nombre').setValue('')
    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.emitted('guardar')).toBeFalsy()
    expect(wrapper.text()).toContain('El nombre de la empresa es obligatorio.')
  })
})
