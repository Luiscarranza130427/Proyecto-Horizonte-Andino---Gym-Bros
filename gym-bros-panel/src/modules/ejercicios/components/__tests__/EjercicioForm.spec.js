import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import EjercicioForm from '@/modules/ejercicios/components/EjercicioForm.vue'

async function completar(wrapper, cambios = {}) {
  const valores = {
    '#ejercicio-nombre': 'Hip thrust',
    '#ejercicio-tipo': 'fuerza',
    '#ejercicio-nivel': 'intermedio',
    '#ejercicio-equipamiento': 'barra',
    '#ejercicio-grupo': '1',
    '#ejercicio-instrucciones': 'Empuja con control.',
    ...cambios,
  }
  for (const [selector, valor] of Object.entries(valores)) {
    await wrapper.get(selector).setValue(valor)
  }
  await adjuntarImagen(wrapper)
}

/** jsdom no implementa createObjectURL ni deja escribir en input.files. */
async function adjuntarImagen(wrapper) {
  globalThis.URL.createObjectURL ??= () => 'blob:vista-previa'
  globalThis.URL.revokeObjectURL ??= () => {}
  const input = wrapper.get('#ejercicio-imagen')
  Object.defineProperty(input.element, 'files', {
    configurable: true,
    value: [new File(['x'], 'ejercicio.png', { type: 'image/png' })],
  })
  await input.trigger('change')
}

describe('EjercicioForm', () => {
  it('no envía nada si faltan los campos obligatorios', async () => {
    const wrapper = mount(EjercicioForm, {
      props: { gruposMusculares: [{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }] },
    })

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
    expect(wrapper.text()).toContain('al menos 3 caracteres')
  })

  it('normaliza y emite un ejercicio válido', async () => {
    const wrapper = mount(EjercicioForm, {
      props: { gruposMusculares: [{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }] },
    })
    await completar(wrapper, { '#ejercicio-nombre': '  Hip thrust  ' })

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toHaveLength(1)
    expect(wrapper.emitted('submit')[0][0]).toEqual(
      expect.objectContaining({
        nombre: 'Hip thrust',
        tipo: 'fuerza',
        nivel: 'intermedio',
        equipamiento: 'barra',
        idGruposMusculares: 1,
        estado: 'active',
      }),
    )
  })

  it('exige imagen al crear pero no al editar', async () => {
    const grupos = [{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }]
    const alta = mount(EjercicioForm, { props: { gruposMusculares: grupos } })
    for (const [selector, valor] of Object.entries({
      '#ejercicio-nombre': 'Hip thrust',
      '#ejercicio-tipo': 'fuerza',
      '#ejercicio-nivel': 'intermedio',
      '#ejercicio-equipamiento': 'barra',
      '#ejercicio-grupo': '1',
      '#ejercicio-instrucciones': 'Empuja con control.',
    })) {
      await alta.get(selector).setValue(valor)
    }
    await alta.get('form').trigger('submit')
    expect(alta.emitted('submit')).toBeUndefined()
    expect(alta.text()).toContain('Selecciona una imagen')

    const edicion = mount(EjercicioForm, {
      props: {
        modo: 'edit',
        gruposMusculares: grupos,
        valoresIniciales: {
          nombre: 'Press',
          tipo: 'fuerza',
          nivel: 'intermedio',
          equipamiento: 'barra',
          idGruposMusculares: 1,
          instrucciones: 'Baja controlado.',
          estado: 'active',
        },
      },
    })
    await edicion.get('form').trigger('submit')
    expect(edicion.emitted('submit')).toHaveLength(1)
    expect(edicion.emitted('submit')[0][0].imagenEjercicio).toBeNull()
  })

  it('no muestra controles que no se guardan (series y repeticiones)', () => {
    const wrapper = mount(EjercicioForm)
    expect(wrapper.find('#ejercicio-series').exists()).toBe(false)
    expect(wrapper.find('#ejercicio-repeticiones').exists()).toBe(false)
  })

  it('exige los datos obligatorios del contrato de Laravel', async () => {
    const wrapper = mount(EjercicioForm)

    // `Number('') === 0`, así que un campo vacío pasaría por válido sin una
    // comprobación explícita. Ése es justo el caso que se prueba aquí.
    await completar(wrapper, { '#ejercicio-instrucciones': '' })
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()

    await completar(wrapper, { '#ejercicio-grupo': '0' })
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()

    await completar(wrapper, { '#ejercicio-tipo': '' })
    await wrapper.get('form').trigger('submit')
    expect(wrapper.emitted('submit')).toBeUndefined()
  })

  it('asocia los errores 422 del servidor con su campo', async () => {
    const wrapper = mount(EjercicioForm, {
      props: {
        gruposMusculares: [{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }],
        erroresServidor: {
          nombre: ['Ya existe un ejercicio con este nombre.'],
          instrucciones: ['Es obligatorio.'],
        },
      },
    })

    expect(wrapper.get('#ejercicio-nombre').attributes('aria-describedby')).toBe('error-nombre')
    expect(wrapper.text()).toContain('Ya existe un ejercicio con este nombre.')
    expect(wrapper.text()).toContain('Es obligatorio.')
  })

  it('carga los valores iniciales al editar', async () => {
    const wrapper = mount(EjercicioForm, {
      props: {
        modo: 'edit',
        valoresIniciales: {
          nombre: 'Sentadilla',
          tipo: 'fuerza',
          nivel: 'avanzado',
          equipamiento: 'barra',
          descripcion: 'Tren inferior.',
          instrucciones: 'Controla la postura.',
          imagenEjercicio: 'ejercicios/sentadilla.webp',
          idGruposMusculares: 1,
          estado: 'inactive',
        },
      },
    })

    expect(wrapper.get('#ejercicio-nombre').element.value).toBe('Sentadilla')
    expect(wrapper.get('#ejercicio-nivel').element.value).toBe('avanzado')
    expect(wrapper.get('#ejercicio-tipo').element.value).toBe('fuerza')
  })

  it('no reenvía mientras el envío anterior sigue en curso', async () => {
    const wrapper = mount(EjercicioForm, {
      props: {
        enviando: true,
        gruposMusculares: [{ id: 1, descripcion: 'Pectoral', tipo: 'pecho' }],
      },
    })
    await completar(wrapper)

    await wrapper.get('form').trigger('submit')

    expect(wrapper.emitted('submit')).toBeUndefined()
  })
})
