import { mount, flushPromises } from '@vue/test-utils'
import { describe, expect, it, vi } from 'vitest'
import { obtenerPlanesAsignables } from '@/modules/empresas/services/empresas.service'
vi.mock('@/modules/empresas/services/empresas.service', () => ({
  obtenerPlanesAsignables: vi.fn(),
}))

import EmpresaForm from '@/modules/empresas/components/EmpresaForm.vue'

const DIAS = ['lunes', 'martes', 'miercoles', 'jueves', 'viernes', 'sabado', 'domingo']
const HORARIOS_VALIDOS = Object.fromEntries(
  DIAS.flatMap((dia) => [
    [`horario_inicio_${dia}`, '06:00'],
    [`horario_fin_${dia}`, '22:00'],
  ]),
)

async function completarFormulario(wrapper) {
  await wrapper.get('#empresa-nombre').setValue('Nova Fitness')
  await wrapper.get('#empresa-gerente').setValue('Andrea Morales')
  await wrapper.get('#empresa-correo').setValue('contacto@novafitness.test')
  await wrapper.get('#empresa-telefono').setValue('987 654 321')
  await wrapper.get('#empresa-ruc').setValue('20987654321')
  await wrapper.get('#empresa-web').setValue('https://novafitness.example')
  for (const dia of DIAS) {
    await wrapper.get(`#horario-inicio-${dia}`).setValue('06:00')
    await wrapper.get(`#horario-fin-${dia}`).setValue('22:00')
  }
}

describe('EmpresaForm', () => {
  it('no preselecciona el plan y exige confirmación para asignarlo al editar', async () => {
    obtenerPlanesAsignables.mockResolvedValue([{ id: 4, nombre: 'Pro' }])
    const wrapper = mount(EmpresaForm, {
      props: { modo: 'edit', mostrarPlan: true, valoresIniciales: { id_planes: 4 } },
      global: {
        stubs: {
          ConfirmDialog: {
            props: ['abierto', 'descripcion'],
            emits: ['confirmar'],
            template:
              '<button v-if="abierto" type="button" data-confirmar @click="$emit(\'confirmar\')">{{ descripcion }}</button>',
          },
        },
      },
    })
    await flushPromises()
    expect(wrapper.get('#empresa-plan').element.value).toBe('')
    await completarFormulario(wrapper)
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')[0][0]).not.toHaveProperty('id_planes')
    await wrapper.get('#empresa-plan').setValue('4')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toHaveLength(1)
    await wrapper.get('[data-confirmar]').trigger('click')
    expect(wrapper.emitted('submit')[1][0].id_planes).toBe(4)
  })
  it('permite seleccionar el logo y no muestra un error inexistente', () => {
    const wrapper = mount(EmpresaForm, { props: { soloIdentidad: true } })
    const input = wrapper.get('#empresa-logo')
    expect(input.element.disabled).toBe(false)
    expect(input.classes()).not.toContain('is-invalid')
    expect(input.attributes('aria-invalid')).toBe('false')
    expect(wrapper.find('#error-logo').exists()).toBe(false)
  })

  it('guarda solo la identidad sin exigir datos administrativos ni horarios', async () => {
    const wrapper = mount(EmpresaForm, {
      props: {
        soloIdentidad: true,
        valoresIniciales: {
          logoUrl: '/logo.webp',
          colorPrimario: '#111111',
          colorSecundario: '#ba270d',
          banner_2: 'empresas/promocion.webp',
          link_boton_2: 'https://example.com/promocion',
        },
      },
    })
    expect(wrapper.find('#empresa-nombre').exists()).toBe(false)
    expect(wrapper.find('#titulo-estado').exists()).toBe(false)
    await wrapper.get('input[name="colorPrimarioHex"]').setValue('#223344')
    expect(wrapper.findAll('.banner-pareja')).toHaveLength(3)
    await wrapper.get('#empresa-link-2').setValue('https://example.com/nueva')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')[0][0]).toEqual({
      banner_1: null,
      link_boton_1: null,
      banner_2: 'empresas/promocion.webp',
      link_boton_2: 'https://example.com/nueva',
      banner_3: null,
      link_boton_3: null,
      logoUrl: '/logo.webp',
      colorPrimario: '#223344',
      colorSecundario: '#ba270d',
    })
  })

  it('muestra validaciones accesibles para campos obligatorios e inválidos', async () => {
    const wrapper = mount(EmpresaForm)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.text()).toContain('Introduce un nombre de al menos 3 caracteres')
    expect(wrapper.text()).toContain('Introduce el nombre del gerente')
    expect(wrapper.text()).toContain('Introduce un correo válido')
    expect(wrapper.get('#empresa-correo').attributes('aria-invalid')).toBe('true')
    expect(wrapper.get('#empresa-correo').attributes('aria-describedby')).toBe('error-correo')
    expect(wrapper.emitted('submit')).toBeUndefined()
  })

  it('emite un payload limpio cuando el formulario es válido', async () => {
    const wrapper = mount(EmpresaForm)
    await completarFormulario(wrapper)
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({
        nombre: 'Nova Fitness',
        correo: 'contacto@novafitness.test',
        estado: 'active',
        sitioWeb: 'https://novafitness.example',
        horario_inicio_lunes: '06:00',
        horario_fin_domingo: '22:00',
      }),
    )
  })

  it('carga los horarios reales y rechaza un cierre anterior a la apertura', async () => {
    const wrapper = mount(EmpresaForm, {
      props: {
        modo: 'edit',
        valoresIniciales: {
          nombre: 'Gym Bros Cajamarca',
          gerente: 'Carlos Mendoza',
          correo: 'contacto@gymbros.pe',
          telefono: '976123456',
          estado: 'active',
          ...HORARIOS_VALIDOS,
        },
      },
    })

    expect(wrapper.get('#horario-inicio-lunes').element.value).toBe('06:00')
    expect(wrapper.get('#horario-fin-domingo').element.value).toBe('22:00')

    await wrapper.get('#horario-inicio-domingo').setValue('18:00')
    await wrapper.get('#horario-fin-domingo').setValue('13:00')
    await wrapper.get('form').trigger('submit')

    expect(wrapper.text()).toContain('la hora de cierre debe ser posterior')
    expect(wrapper.emitted('submit')).toBeUndefined()
  })

  it('copia el horario del lunes al resto de la semana', async () => {
    const wrapper = mount(EmpresaForm)
    const botonCopiar = wrapper.get('button[type="button"].horarios-encabezado__accion')

    expect(botonCopiar.attributes('disabled')).toBeDefined()

    await wrapper.get('#horario-inicio-lunes').setValue('07:30')
    await wrapper.get('#horario-fin-lunes').setValue('21:15')
    expect(botonCopiar.attributes('disabled')).toBeUndefined()

    await botonCopiar.trigger('click')

    for (const dia of DIAS.slice(1)) {
      expect(wrapper.get(`#horario-inicio-${dia}`).element.value).toBe('07:30')
      expect(wrapper.get(`#horario-fin-${dia}`).element.value).toBe('21:15')
    }
    expect(wrapper.text()).toContain('Horario del lunes aplicado de martes a domingo.')
  })

  it('impide otro envío mientras la operación está en curso', async () => {
    const wrapper = mount(EmpresaForm, { props: { enviando: true } })
    await completarFormulario(wrapper)
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('button[type="submit"]').attributes('disabled')).toBeDefined()
  })

  it('presenta y asocia errores 422 recibidos por campo', () => {
    const wrapper = mount(EmpresaForm, {
      props: { erroresServidor: { correo: ['El correo ya se encuentra registrado.'] } },
    })

    expect(wrapper.text()).toContain('El correo ya se encuentra registrado.')
    expect(wrapper.get('#empresa-correo').attributes('aria-describedby')).toBe('error-correo')
  })

  it('rechaza teléfonos sin suficientes dígitos y colores inválidos', async () => {
    const wrapper = mount(EmpresaForm)
    await completarFormulario(wrapper)
    await wrapper.get('#empresa-telefono').setValue('-------')
    await wrapper.get('input[name="colorPrimarioHex"]').setValue('#zzzzzz')
    await wrapper.get('form').trigger('submit')

    expect(wrapper.text()).toContain('Introduce un teléfono de 6 a 9 dígitos.')
    expect(wrapper.text()).toContain('Introduce un color hexadecimal válido.')
    expect(wrapper.emitted('submit')).toBeUndefined()
  })

  it('ajusta el teléfono a la columna de la API (9 dígitos) y lo envía sin separadores', async () => {
    const wrapper = mount(EmpresaForm)
    await completarFormulario(wrapper)
    await wrapper.get('#empresa-telefono').setValue('+51 987 654 321')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.get('#error-telefono').text()).toContain('de 6 a 9 dígitos')
    expect(wrapper.emitted('submit')).toBeUndefined()

    await wrapper.get('#empresa-telefono').setValue('987 654-321')
    await wrapper.get('#empresa-region').setValue('Junin')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({ telefono: '987654321', region: 'Junin' }),
    )
    // La etiqueta conserva la tilde; el valor es el que acepta la API.
    expect(wrapper.get('#empresa-region option[value="Junin"]').text()).toBe('Junín')
  })

  it('no reenvía campos de solo lectura recibidos en los valores iniciales', async () => {
    const wrapper = mount(EmpresaForm, {
      props: {
        modo: 'edit',
        valoresIniciales: {
          nombre: 'Iron House',
          gerente: 'Diego Salazar',
          correo: 'contacto@ironhouse.test',
          telefono: '910000002',
          estado: 'active',
          usuarios: 999,
          fechaRegistro: '2020-01-01',
          ...HORARIOS_VALIDOS,
        },
      },
    })

    await wrapper.get('form').trigger('submit')
    const payload = wrapper.emitted('submit')[0][0]

    expect(payload).not.toHaveProperty('usuarios')
    expect(payload).not.toHaveProperty('fechaRegistro')
  })
})
