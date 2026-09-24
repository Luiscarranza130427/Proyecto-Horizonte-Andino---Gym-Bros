import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import PerfilDatosForm from '../PerfilDatosForm.vue'

describe('PerfilDatosForm.vue', () => {
  const perfilMock = {
    nombre: 'Titan Gym',
    nombre_gerente: 'Carlos Mendoza',
    correo: 'contacto@gymbros.pe',
    telefono: '+51 976 123 456',
    ruc: '20609876541',
    region: 'Cajamarca',
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
    expect(wrapper.emitted('guardar')[0][0].nombre).toBe('Titan Gym')
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
