import { enableAutoUnmount, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it } from 'vitest'

import PlanForm from '@/modules/membresias/components/PlanForm.vue'

enableAutoUnmount(afterEach)

function montar(props = {}) {
  return mount(PlanForm, { props, attachTo: document.body })
}

async function completar(wrapper, cambios = {}) {
  const valores = {
    '#plan-nombre': 'Escala',
    '#plan-descripcion': 'Plan para empresas en expansión.',
    '#plan-precio-original': '599',
    '#plan-precio-inicial': '449',
    '#plan-duracion': '60',
    '#plan-limite': '400',
    '#plan-whatsapp': 'https://wa.me/51999999999',
    ...cambios,
  }

  for (const [selector, valor] of Object.entries(valores)) {
    await wrapper.get(selector).setValue(valor)
  }
  await wrapper.get('input[value="Gestión de usuarios"]').setValue(true)
  await wrapper.get('input[value="Atención prioritaria"]').setValue(true)
}

describe('PlanForm', () => {
  it('enfoca el primer campo cuando se intenta enviar vacío', async () => {
    const wrapper = montar()

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(document.activeElement).toBe(wrapper.get('#plan-nombre').element)
  })

  it('emite todos los campos con números reales y duración en días', async () => {
    const wrapper = montar()
    await completar(wrapper)
    await wrapper.get('input[name="activo"]').setValue(true)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual({
      nombre: 'Escala',
      descripcion: 'Plan para empresas en expansión.',
      precioOriginal: 599,
      precioInicial: 449,
      duracionDias: 60,
      limiteUsuarios: 400,
      activo: true,
      contenido: 'Gestión de usuarios\nAtención prioritaria',
      enlaceWhatsapp: 'https://wa.me/51999999999',
    })
  })

  it('rechaza precios vacíos, días decimales y URLs no web', async () => {
    const wrapper = montar()
    await completar(wrapper, {
      '#plan-precio-inicial': '',
      '#plan-duracion': '30.5',
      '#plan-whatsapp': 'javascript:alert(1)',
    })

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-precio-inicial').exists()).toBe(true)
    expect(wrapper.get('#error-duracion').exists()).toBe(true)
    expect(wrapper.get('#error-whatsapp').exists()).toBe(true)
  })

  it('asocia los errores 422 con los nombres del formulario', () => {
    const wrapper = montar({
      erroresServidor: {
        precioInicial: ['El precio inicial no es válido.'],
        enlaceWhatsapp: ['El enlace ya no está disponible.'],
        servicios: ['Selecciona al menos un servicio.'],
      },
    })

    expect(wrapper.get('#error-precio-inicial').text()).toContain('no es válido')
    expect(wrapper.get('#error-whatsapp').text()).toContain('ya no está disponible')
    expect(wrapper.get('#error-servicios').text()).toContain('al menos un servicio')
  })

  it('carga los valores existentes al editar', () => {
    const wrapper = montar({
      modo: 'edit',
      valoresIniciales: {
        nombre: 'Fuerza',
        descripcion: 'Plan en crecimiento.',
        precioOriginal: 449,
        precioInicial: 349,
        duracionDias: 30,
        limiteUsuarios: 300,
        activo: true,
        contenido: 'Reportes administrativos',
        enlaceWhatsapp: 'https://wa.me/51900000002',
      },
    })

    expect(wrapper.get('#plan-nombre').element.value).toBe('Fuerza')
    expect(wrapper.get('#plan-duracion').element.value).toBe('30')
    expect(wrapper.get('input[value="Reportes administrativos"]').element.checked).toBe(true)
    expect(wrapper.get('input[name="activo"]').element.checked).toBe(true)
    expect(wrapper.text()).toContain('Guardar cambios')
  })

  it('exige al menos un servicio del multiselect', async () => {
    const wrapper = montar()
    await completar(wrapper)
    await wrapper.get('input[value="Gestión de usuarios"]').setValue(false)
    await wrapper.get('input[value="Atención prioritaria"]').setValue(false)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-servicios').text()).toContain('al menos un servicio')
  })

  it('permite abrir el modal y agregar un servicio personalizado dinámicamente', async () => {
    const wrapper = montar()
    await completar(wrapper)

    await wrapper.get('.plan-form__btn-abrir-modal').trigger('click')
    expect(document.querySelector('.modal-servicio')).not.toBeNull()

    const inputModal = document.querySelector('#nombre-servicio-modal')
    inputModal.value = 'Acceso a Sauna'
    inputModal.dispatchEvent(new Event('input'))

    const formModal = document.querySelector('.modal-servicio__cuerpo')
    formModal.dispatchEvent(new Event('submit'))

    await wrapper.vm.$nextTick()

    expect(wrapper.get('input[value="Acceso a Sauna"]').element.checked).toBe(true)

    await wrapper.get('input[name="activo"]').setValue(true)
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')[0][0].contenido).toContain('Acceso a Sauna')
  })

  it('permite seleccionar todos y limpiar la selección de servicios', async () => {
    const wrapper = montar()

    const botones = wrapper.findAll('.btn-accion-servicio')
    const btnSeleccionarTodos = botones[0]
    const btnLimpiar = botones[1]

    await btnSeleccionarTodos.trigger('click')
    expect(wrapper.findAll('input[name="servicios"]:checked').length).toBeGreaterThanOrEqual(9)

    await btnLimpiar.trigger('click')
    expect(wrapper.findAll('input[name="servicios"]:checked').length).toBe(0)
  })

  it('no vuelve a emitir mientras se está guardando', async () => {
    const wrapper = montar({ enviando: true })
    await completar(wrapper)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
  })
})
