import { enableAutoUnmount, mount } from '@vue/test-utils'
import { afterEach, describe, expect, it } from 'vitest'

import AlimentoForm from '@/modules/alimentacion/components/AlimentoForm.vue'

enableAutoUnmount(afterEach)

/** El foco sólo es observable con el componente montado en el documento. */
function montar(props = {}) {
  return mount(AlimentoForm, { props, attachTo: document.body })
}

async function completar(wrapper, cambios = {}) {
  const valores = {
    '#alimento-nombre': 'Avena',
    '#alimento-tipo': 'cereal',
    '#alimento-calorias': '389',
    '#alimento-proteinas': '16.9',
    '#alimento-carbohidratos': '66.3',
    '#alimento-grasas': '6.9',
    '#alimento-fibra': '10.6',
    ...cambios,
  }
  for (const [selector, valor] of Object.entries(valores)) {
    await wrapper.get(selector).setValue(valor)
  }
}

describe('AlimentoForm', () => {
  it('no envía nada si faltan los campos obligatorios y enfoca el primer error', async () => {
    const wrapper = montar()

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.text()).toContain('al menos 3 caracteres')
    expect(document.activeElement).toBe(wrapper.get('#alimento-nombre').element)
  })

  it('lleva el foco al primer campo con error, no siempre al primero del formulario', async () => {
    // Con el nombre bien puesto, el primer problema es el tipo: si el foco
    // volviera siempre al nombre, el usuario no vería qué le falta.
    const wrapper = montar()
    await wrapper.get('#alimento-nombre').setValue('Avena')

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(document.activeElement).toBe(wrapper.get('#alimento-tipo').element)
  })

  it('normaliza y emite un alimento válido', async () => {
    const wrapper = montar()
    await completar(wrapper, { '#alimento-nombre': '  Avena integral  ' })

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual({
      nombre: 'Avena integral',
      tipo: 'cereal',
      calorias: 389,
      proteinas: 16.9,
      carbohidratos: 66.3,
      grasas: 6.9,
      fibra: 10.6,
    })
  })

  it('rechaza un macro vacío en lugar de guardarlo como cero', async () => {
    // `Number('') === 0`: sin comprobación explícita, borrar el campo se
    // guardaría como «0 g de fibra», que es un dato y no un hueco.
    const wrapper = montar()

    await completar(wrapper, { '#alimento-fibra': '' })
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.get('#error-fibra').text()).toContain('igual o mayor que 0')
  })

  it('rechaza macros negativos y admite el cero y los decimales', async () => {
    const wrapper = montar()

    await completar(wrapper, { '#alimento-proteinas': '-1' })
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()

    // Cero sí es válido: el arroz no aporta grasa, y 3,6 g de grasa por 100 g
    // es un valor corriente, así que tampoco valen sólo los enteros.
    await completar(wrapper, { '#alimento-proteinas': '0', '#alimento-grasas': '3.6' })
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({ proteinas: 0, grasas: 3.6 }),
    )
  })

  it('ofrece los controles adicionales al editar, no al crear', async () => {
    const wrapper = montar({ modo: 'edit' })

    const campos = wrapper.findAll('input, select').map((campo) => campo.attributes('name'))
    expect(campos).toContain('activo')
    expect(campos).toContain('unidadBase')
    expect(campos).toContain('densidadGml')
    expect(campos).toContain('restriccionesVerificadas')
    expect(montar().find('[name="activo"]').exists()).toBe(false)
  })

  it('asocia los errores 422 del servidor con su campo', async () => {
    const wrapper = montar({
      erroresServidor: {
        nombre: ['Ya existe un alimento con este nombre.'],
        calorias: ['La energía no puede superar 900 kcal por 100 g.'],
      },
    })

    expect(wrapper.get('#alimento-nombre').attributes('aria-describedby')).toBe('error-nombre')
    expect(wrapper.get('#error-nombre').text()).toContain('Ya existe un alimento con este nombre.')
    expect(wrapper.get('#error-calorias').text()).toContain(
      'La energía no puede superar 900 kcal por 100 g.',
    )
  })

  it('carga los valores iniciales al editar', async () => {
    const wrapper = montar({
      modo: 'edit',
      valoresIniciales: {
        id: 4,
        nombre: 'Avena',
        tipo: 'cereal',
        calorias: 389,
        proteinas: 16.9,
        carbohidratos: 66.3,
        grasas: 6.9,
        fibra: 10.6,
        unidadBase: 'gramos',
        usos: 6,
        estadoPreparacion: 'Cocido',
        gramosPorUnidad: 45,
        nutricionVerificada: true,
        tiposComida: ['desayuno', 'cena'],
      },
    })

    expect(wrapper.get('#alimento-nombre').element.value).toBe('Avena')
    expect(wrapper.get('#alimento-tipo').element.value).toBe('cereal')
    expect(wrapper.get('#alimento-calorias').element.value).toBe('389')
    expect(wrapper.get('#alimento-estadoPreparacion').element.value).toBe('Cocido')
    expect(wrapper.get('#alimento-gramosPorUnidad').element.value).toBe('45')
    expect(wrapper.get('#alimento-nutricion-verificada').element.value).toBe('true')
    expect(wrapper.get('#alimento-tipos-comida').element.value).toBe('desayuno')
    expect(
      wrapper
        .get('#alimento-tipos-comida')
        .findAll('option:checked')
        .map((opcion) => opcion.element.value),
    ).toEqual(['desayuno', 'cena'])
    expect(wrapper.text()).toContain('Guardar cambios')
  })

  it('al editar sólo envía la configuración avanzada que se cambió', async () => {
    // Forma real de un alimento del alta básica: sin configuración del generador
    // (el servicio rellena unidadBase con 'gramos' por defecto).
    const wrapper = montar({
      modo: 'edit',
      valoresIniciales: {
        nombre: 'Quinua',
        tipo: 'cereal',
        calorias: 120,
        proteinas: 4.4,
        carbohidratos: 21.3,
        grasas: 1.9,
        fibra: 2.8,
        unidadBase: 'gramos',
        estadoPreparacion: null,
        grupoMenu: null,
        porcionMin: null,
        tiposComida: [],
      },
    })

    await wrapper.get('#alimento-calorias').setValue('125')
    await wrapper.get('form').trigger('submit')

    const enviado = wrapper.emitted('submit')[0][0]
    expect(enviado.calorias).toBe(125)
    // Antes viajaban todos (vacíos incluidos) y la API respondía 422.
    for (const campo of [
      'unidadBase',
      'estadoPreparacion',
      'grupoMenu',
      'porcionMin',
      'tiposComida',
    ]) {
      expect(enviado).not.toHaveProperty(campo)
    }

    await wrapper.get('#alimento-estadoPreparacion').setValue('Cocido')
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')[1][0].estadoPreparacion).toBe('Cocido')
  })

  it('emite tipos de comida como valores únicos y sólo cuando cambiaron', async () => {
    const wrapper = montar({
      modo: 'edit',
      valoresIniciales: {
        nombre: 'Avena',
        tipo: 'cereal',
        calorias: 389,
        proteinas: 16.9,
        carbohidratos: 66.3,
        grasas: 6.9,
        fibra: 10.6,
        tiposComida: ['desayuno'],
      },
    })

    await wrapper.get('#alimento-tipos-comida').setValue(['desayuno', 'almuerzo', 'almuerzo'])
    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')[0][0].tiposComida).toEqual(['desayuno', 'almuerzo'])
  })

  it('no reenvía mientras el envío anterior sigue en curso', async () => {
    const wrapper = montar({ enviando: true })
    await completar(wrapper)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
  })
})
