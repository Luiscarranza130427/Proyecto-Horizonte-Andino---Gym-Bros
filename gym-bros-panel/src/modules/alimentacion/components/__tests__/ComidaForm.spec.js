import { flushPromises, mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import ComidaForm from '@/modules/alimentacion/components/ComidaForm.vue'

const CATALOGO = [
  { id: 1, nombre: 'Avena', tipo: 'cereal', unidadBase: 'gramos', calorias: 389 },
  { id: 2, nombre: 'Plátano', tipo: 'fruta', unidadBase: 'gramos', calorias: 89 },
  { id: 3, nombre: 'Agua', tipo: 'bebida', unidadBase: 'mililitros', calorias: 0 },
]

const montar = (props = {}) => mount(ComidaForm, { props: { catalogo: CATALOGO, ...props } })

/**
 * Una porción tal como la entrega el SERVICIO, que es lo que recibe
 * `valoresIniciales`: con el alimento anidado, no con un `alimentoId` plano.
 * El formulario la traduce al payload al enviar.
 */
const porcionServida = (id, nombre, cantidad, unidad = 'gramos') => ({
  id: id * 100,
  alimento: { id, nombre, tipo: 'cereal' },
  cantidad,
  unidad,
  macros: { calorias: 200, proteinas: 10, carbohidratos: 20, grasas: 2, fibra: 3 },
})

/** Elige un alimento del desplegable y lo añade a la comida. */
async function anadirAlimento(wrapper, id) {
  const select = wrapper.find('select[id$="-alimento"]')
  await select.setValue(String(id))
  const boton = wrapper.findAll('button').find((b) => /añadir/i.test(b.text()))
  await boton.trigger('click')
  await flushPromises()
}

describe('ComidaForm', () => {
  it('exige tipo, hora y al menos un alimento', async () => {
    const wrapper = montar()

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.find('#error-alimentos').exists()).toBe(true)
  })

  it('rechaza una hora que no tenga formato HH:MM', async () => {
    const wrapper = montar({
      valoresIniciales: {
        tipoComida: 'cena',
        horaSugerida: '8 de la tarde',
        alimentos: [porcionServida(1, 'Avena', 100)],
      },
    })
    await flushPromises()

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.find('#error-hora').exists()).toBe(true)
  })

  it('emite la comida con sus alimentos en el vocabulario del servicio', async () => {
    const wrapper = montar()
    await wrapper.find('#comida-tipo').setValue('desayuno')
    await wrapper.find('#comida-hora').setValue('07:30')
    await anadirAlimento(wrapper, 1)

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.emitted('submit')?.[0][0]).toMatchObject({
      tipoComida: 'desayuno',
      horaSugerida: '07:30',
      alimentos: [{ alimentoId: 1, cantidad: expect.any(Number), unidad: 'gramos' }],
    })
  })

  it('toma la unidad natural de cada alimento', async () => {
    const wrapper = montar()
    await wrapper.find('#comida-tipo').setValue('snack')
    await wrapper.find('#comida-hora').setValue('16:00')
    // El agua se mide en mililitros; ofrecer gramos por defecto obligaría a
    // corregirlo a mano en cada bebida.
    await anadirAlimento(wrapper, 3)

    await wrapper.find('form').trigger('submit')
    await flushPromises()

    expect(wrapper.emitted('submit')?.[0][0].alimentos[0].unidad).toBe('mililitros')
  })

  /*
   * LA TRAMPA de `useFormulario`: copia `modeloVacio` con propagación
   * SUPERFICIAL, así que el array `alimentos` del formulario y el del modelo
   * vacío son el MISMO objeto. Mutarlo con push deja el modelo contaminado y al
   * abrir el formulario por segunda vez aparecerían los alimentos de la vez
   * anterior. No rompe nada: sólo hace algo mal, en silencio.
   */
  it('no arrastra los alimentos de un montaje al siguiente', async () => {
    const primero = montar()
    await anadirAlimento(primero, 1)
    await anadirAlimento(primero, 2)
    expect(primero.findAll('.selector__lista li')).toHaveLength(2)
    primero.unmount()

    const segundo = montar()
    await flushPromises()

    // Ojo: el nombre del alimento aparece SIEMPRE en el <select> del catálogo,
    // así que buscarlo en el texto no distingue nada. Lo que importa es la
    // lista de elegidos y, sobre todo, lo que se acabaría enviando.
    expect(segundo.findAll('.selector__lista li')).toHaveLength(0)

    await segundo.find('#comida-tipo').setValue('cena')
    await segundo.find('#comida-hora').setValue('20:00')
    await anadirAlimento(segundo, 3)
    await segundo.find('form').trigger('submit')
    await flushPromises()

    expect(segundo.emitted('submit')?.[0][0].alimentos).toHaveLength(1)
    expect(segundo.emitted('submit')?.[0][0].alimentos[0].alimentoId).toBe(3)
  })

  it('carga los valores de una comida existente para editarla', async () => {
    const wrapper = montar({
      valoresIniciales: {
        tipoComida: 'almuerzo',
        horaSugerida: '13:00',
        alimentos: [porcionServida(2, 'Plátano', 150)],
      },
    })
    await flushPromises()

    expect(wrapper.find('#comida-tipo').element.value).toBe('almuerzo')
    expect(wrapper.find('#comida-hora').element.value).toBe('13:00')
    expect(wrapper.findAll('.selector__lista li')).toHaveLength(1)
    expect(wrapper.find('.selector__lista').text()).toContain('Plátano')
  })

  it('pinta bajo su campo el 422 que devuelve el servidor', async () => {
    const wrapper = montar({ erroresServidor: { horaSugerida: ['Esa hora ya está ocupada.'] } })
    await flushPromises()

    expect(wrapper.find('#error-hora').text()).toContain('Esa hora ya está ocupada.')
  })

  it('deja retirar un alimento de la comida', async () => {
    const wrapper = montar()
    await anadirAlimento(wrapper, 1)
    await anadirAlimento(wrapper, 2)

    const quitar = wrapper.findAll('.selector__lista button')
    await quitar[quitar.length - 1].trigger('click')
    await flushPromises()

    expect(wrapper.findAll('.selector__lista li')).toHaveLength(1)
  })
})
