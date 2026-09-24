import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import UsuarioForm from '@/modules/usuarios/components/UsuarioForm.vue'

const EMPRESAS = [{ id: 1, nombre: 'Power Gym' }]

async function completarFormulario(wrapper) {
  await wrapper.get('#usuario-nombre').setValue('Carlos')
  await wrapper.get('#usuario-apellido').setValue('Ramírez')
  await wrapper.get('#usuario-apodo').setValue('Charly')
  await wrapper.get('#usuario-nacimiento').setValue('1995-04-12')
  await wrapper.get('#usuario-genero').setValue('Varon')
  await wrapper.get('#usuario-correo').setValue('carlos.nuevo@gymbros.test')
  await wrapper.get('#usuario-telefono').setValue('+51 987654321')
  await wrapper.get('#usuario-documento').setValue('76543210')
  await wrapper.get('#usuario-empresa').setValue('1')
  await wrapper.get('#usuario-rol').setValue('member')
}

describe('UsuarioForm', () => {
  it('muestra errores del servidor de documento y teléfono en edición', () => {
    const wrapper = mount(UsuarioForm, {
      props: {
        modo: 'edit',
        erroresServidor: {
          tipoDocumento: ['El tipo de documento no es válido.'],
          telefono: ['El teléfono es obligatorio.'],
        },
      },
    })
    expect(wrapper.text()).toContain('El tipo de documento no es válido.')
    expect(wrapper.text()).toContain('El teléfono es obligatorio.')
  })
  it('ofrece la sección de foto de perfil y permite manipularla', async () => {
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })

    expect(wrapper.find('input[type="file"]').exists()).toBe(true)
    expect(wrapper.text()).toContain('Foto de perfil')
    expect(wrapper.find('.foto__btn-quitar').exists()).toBe(false)

    const wrapperConFoto = mount(UsuarioForm, {
      props: {
        empresas: EMPRESAS,
        valoresIniciales: { fotoPerfil: 'https://example.com/avatar.jpg' },
      },
    })
    expect(wrapperConFoto.find('.foto__btn-quitar').exists()).toBe(true)
    expect(wrapperConFoto.find('img').attributes('src')).toBe('https://example.com/avatar.jpg')

    await wrapperConFoto.find('.foto__btn-quitar').trigger('click')
    expect(wrapperConFoto.find('.foto__btn-quitar').exists()).toBe(false)
    expect(wrapperConFoto.find('img').exists()).toBe(false)
  })

  it('muestra validaciones requeridas y no envía datos incompletos', async () => {
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.text()).toContain('Introduce un nombre')
    expect(wrapper.text()).toContain('Introduce un apellido')
    expect(wrapper.text()).toContain('Introduce un correo válido')
    expect(wrapper.text()).toContain('Selecciona una empresa')
    // La API exige estos campos al crear: sin ellos el alta terminaba en 422.
    expect(wrapper.get('#error-apodo').text()).toBe('Introduce un apodo.')
    expect(wrapper.get('#error-telefono').text()).toContain('de 6 a 12 dígitos')
    expect(wrapper.get('#error-documento').text()).toBe('Introduce el número de documento.')
    expect(wrapper.get('#error-nacimiento').text()).toBe('Introduce la fecha de nacimiento.')
    expect(wrapper.get('#error-genero').text()).toBe('Selecciona el género.')
    expect(wrapper.get('#usuario-telefono').attributes('aria-describedby')).toBe('error-telefono')
  })

  it('respeta los límites de la API en teléfono, documento y fecha', async () => {
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })
    await completarFormulario(wrapper)
    await wrapper.get('#usuario-telefono').setValue('+51 987 654 3210')
    await wrapper.get('#usuario-tipo-documento').setValue('passport')
    await wrapper.get('#usuario-documento').setValue('AB1234567890X')
    await wrapper.get('#usuario-nacimiento').setValue('1899-12-31')

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-telefono').text()).toContain('de 6 a 12 dígitos')
    expect(wrapper.get('#error-documento').text()).toContain('entre 5 y 12 caracteres')
    expect(wrapper.get('#error-nacimiento').text()).toContain('fecha de nacimiento válida')
    expect(wrapper.get('#usuario-documento').attributes('maxlength')).toBe('12')
  })

  it('sólo ofrece los roles que la sesión puede asignar', () => {
    const wrapper = mount(UsuarioForm, {
      props: {
        empresas: EMPRESAS,
        roles: [
          { valor: 'trainer', etiqueta: 'Entrenador' },
          { valor: 'member', etiqueta: 'Usuario' },
        ],
      },
    })
    const opciones = wrapper.findAll('#usuario-rol option').map((opcion) => opcion.text())
    expect(opciones).toEqual(['Entrenador', 'Usuario'])
    expect(wrapper.get('#usuario-genero').exists()).toBe(true)
  })

  it('normaliza y emite un usuario válido', async () => {
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })
    await completarFormulario(wrapper)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({
        nombre: 'Carlos',
        apellido: 'Ramírez',
        apodo: 'Charly',
        correo: 'carlos.nuevo@gymbros.test',
        telefono: '+51987654321',
        genero: 'Varon',
        fechaNacimiento: '1995-04-12',
        tipoDocumento: 'dni',
        numeroDocumento: '76543210',
        empresaId: 1,
        rol: 'member',
        estado: 'active',
      }),
    )
  })

  it('asocia errores 422 del servidor con sus campos', async () => {
    const wrapper = mount(UsuarioForm, {
      props: {
        empresas: EMPRESAS,
        erroresServidor: {
          correo: ['El correo ya se encuentra registrado.'],
          numeroDocumento: ['El documento ya está registrado.'],
        },
      },
    })

    expect(wrapper.get('#usuario-correo').attributes('aria-describedby')).toBe('error-correo')
    expect(wrapper.get('#usuario-documento').attributes('aria-describedby')).toBe('error-documento')
    expect(wrapper.text()).toContain('El correo ya se encuentra registrado.')
    expect(wrapper.text()).toContain('El documento ya está registrado.')
  })

  it('aplica a cada tipo de documento su propia regla, y sólo la suya', async () => {
    // Fija el contrato que el `!== 'DNI'` en mayúsculas dejaba ambiguo: al DNI
    // le toca la regla de 8 dígitos exactos y NO la genérica de 5–20 caracteres.
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })
    await completarFormulario(wrapper)

    // Un DNI de 9 dígitos entra en el rango genérico 5–20, pero es inválido.
    await wrapper.get('#usuario-documento').setValue('123456789')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.text()).toContain('exactamente 8 dígitos')

    // El pasaporte usa la regla genérica: acepta letras y otra longitud.
    await wrapper.get('#usuario-tipo-documento').setValue('passport')
    await wrapper.get('#usuario-documento').setValue('AB123456')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({ tipoDocumento: 'passport', numeroDocumento: 'AB123456' }),
    )
  })

  it('rechaza un DNI y una fecha futura inválidos', async () => {
    const wrapper = mount(UsuarioForm, { props: { empresas: EMPRESAS } })
    await completarFormulario(wrapper)
    await wrapper.get('#usuario-documento').setValue('123')
    await wrapper.get('#usuario-nacimiento').setValue('2999-01-01')

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.text()).toContain('exactamente 8 dígitos')
    expect(wrapper.text()).toContain('no puede ser futura')
  })

  it('en modo edición no muestra la sección de Organización y acceso ni exige empresa', async () => {
    const wrapper = mount(UsuarioForm, {
      props: {
        modo: 'edit',
        valoresIniciales: {
          nombre: 'Carlos',
          apellido: 'Ramírez',
          correo: 'carlos@test.com',
          tipoDocumento: 'dni',
          numeroDocumento: '76543210',
        },
      },
    })

    expect(wrapper.find('#usuario-empresa').exists()).toBe(false)
    expect(wrapper.find('#usuario-rol').exists()).toBe(false)
    expect(wrapper.text()).not.toContain('Organización y acceso')

    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toHaveLength(1)
    const payload = wrapper.emitted('submit')[0][0]
    expect(payload).toEqual(
      expect.objectContaining({
        nombre: 'Carlos',
        apellido: 'Ramírez',
        correo: 'carlos@test.com',
        numeroDocumento: '76543210',
      }),
    )
    // Lo que el usuario no tenía y sigue vacío no viaja: la API lo rechazaría
    // (`sometimes|required`) como antes hacía con `genero: null`.
    for (const campo of ['apodo', 'telefono', 'fechaNacimiento', 'genero']) {
      expect(payload).not.toHaveProperty(campo)
    }
  })

  it('en edición no deja vaciar un campo obligatorio que ya tenía valor', async () => {
    const wrapper = mount(UsuarioForm, {
      props: {
        modo: 'edit',
        valoresIniciales: {
          nombre: 'Carlos',
          apellido: 'Ramírez',
          correo: 'carlos@test.com',
          telefono: '987654321',
          genero: 'Varon',
        },
      },
    })
    expect(wrapper.get('label[for="usuario-telefono"]').text()).toBe('Teléfono *')
    expect(wrapper.get('label[for="usuario-apodo"]').text()).toBe('Apodo')

    await wrapper.get('#usuario-telefono').setValue('')
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-telefono').text()).toContain('de 6 a 12 dígitos')
  })
})
