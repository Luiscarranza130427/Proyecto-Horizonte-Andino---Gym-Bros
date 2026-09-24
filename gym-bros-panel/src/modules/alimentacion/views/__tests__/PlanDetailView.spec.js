import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import PlanDetailView from '@/modules/alimentacion/views/PlanDetailView.vue'
import { eliminarComida, obtenerPlan } from '@/modules/alimentacion/services/alimentacion.service'

const route = reactive({ params: { id: '3' }, query: {} })
const replace = vi.fn(() => Promise.resolve())
const push = vi.fn(() => Promise.resolve())

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRoute: () => route, useRouter: () => ({ replace, push }) }
})

vi.mock('@/modules/alimentacion/services/alimentacion.service', () => ({
  obtenerPlan: vi.fn(),
  eliminarComida: vi.fn(),
}))

const porcion = (id, nombre, cantidad, calorias) => ({
  id,
  alimento: { id, nombre, tipo: 'cereal' },
  cantidad,
  unidad: 'gramos',
  macros: { calorias, proteinas: 10, carbohidratos: 20, grasas: 2, fibra: 3 },
})

const comida = (id, tipoComida, horaSugerida, orden) => ({
  id,
  tipoComida,
  horaSugerida,
  orden,
  alimentos: [porcion(id * 10, `Alimento ${id}`, 100, 200)],
  macros: { calorias: 200, proteinas: 10, carbohidratos: 20, grasas: 2, fibra: 3 },
})

const PLAN = {
  id: 3,
  usuario: { id: 2, nombre: 'Andrea Mendoza' },
  empresa: { id: 1, nombre: 'Power Gym' },
  objetivo: 'Ganar masa muscular',
  fechaInicio: '2026-07-27',
  fechaFin: '2026-09-27',
  activo: true,
  objetivos: { calorias: 1000, proteinas: 60, carbohidratos: 120, grasas: 30 },
  totalComidas: 3,
  macros: { calorias: 600, proteinas: 30, carbohidratos: 60, grasas: 6, fibra: 9 },
  comidas: [comida(1, 'desayuno', '07:00', 1), comida(2, 'almuerzo', '13:00', 2)],
}

function montar() {
  return mount(PlanDetailView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

const confirmar = async (wrapper) => {
  await wrapper.find('.comida__retirar').trigger('click')
  await flushPromises()
  await wrapper.find('.dialogo__acciones .btn-danger').trigger('click')
  await flushPromises()
}

describe('PlanDetailView', () => {
  beforeEach(() => {
    route.params = { id: '3' }
    route.query = {}
    replace.mockReset()
    replace.mockResolvedValue(undefined)
    push.mockReset()
    push.mockResolvedValue(undefined)
    obtenerPlan.mockReset()
    eliminarComida.mockReset()
  })

  it('presenta el horario con sus comidas y sus alimentos', async () => {
    obtenerPlan.mockResolvedValue(PLAN)
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Andrea Mendoza')
    expect(wrapper.text()).toContain('07:00')
    expect(wrapper.text()).toContain('13:00')
    expect(wrapper.text()).toContain('Alimento 1')
  })

  /*
   * El horario se ordena por HORA, por delante del tipo de comida y del campo
   * `orden`. Ordenar es cosa de esta pantalla: el servicio no lo garantiza.
   *
   * Los datos están elegidos para que los tres criterios DISCREPEN. Con un
   * desayuno a las siete y una cena a las nueve —lo normal— cualquiera de los
   * tres da el mismo resultado y la prueba pasaría aunque se ordenara mal. Aquí
   * el `snack` va de madrugada y el `desayuno` a media mañana: por tipo de
   * comida saldría antes el desayuno, por hora sale antes el snack.
   */
  it('ordena por hora aunque el tipo de comida y el orden digan otra cosa', async () => {
    obtenerPlan.mockResolvedValue({
      ...PLAN,
      comidas: [
        comida(1, 'desayuno', '09:00', 1),
        comida(2, 'snack', '06:00', 2),
        comida(3, 'cena', '07:30', 3),
      ],
    })
    const wrapper = montar()
    await flushPromises()

    const texto = wrapper.text()
    expect(texto.indexOf('06:00')).toBeLessThan(texto.indexOf('07:30'))
    expect(texto.indexOf('07:30')).toBeLessThan(texto.indexOf('09:00'))
  })

  it('enfrenta lo que suman las comidas con los objetivos del plan', async () => {
    obtenerPlan.mockResolvedValue(PLAN)
    const wrapper = montar()
    await flushPromises()

    // La diferencia entre lo fijado y lo servido es el dato con valor de la
    // pantalla: sin ella son dos cifras sueltas que nadie compara a ojo.
    const texto = wrapper.text().replace(/\s+/g, ' ')
    expect(texto).toContain('600')
    expect(texto).toContain('1,000')
    expect(texto).toMatch(/[−-]\s?400/)
  })

  /*
   * La distinción que separa un fallo de acción de uno de carga. `eliminarComida`
   * devuelve un 422 SIN `errors` cuando es la última comida del plan: no hay
   * campo al que apuntar y la ficha que se está mirando sigue siendo válida.
   */
  it('mantiene la ficha cuando retirar una comida falla', async () => {
    obtenerPlan.mockResolvedValue(PLAN)
    eliminarComida.mockRejectedValue({
      status: 422,
      message: 'Un plan necesita al menos una comida. Añade otra antes de retirar ésta.',
      errors: null,
    })

    const wrapper = montar()
    await flushPromises()
    await confirmar(wrapper)

    expect(wrapper.find('.alert-danger').text()).toContain('al menos una comida')
    // Vaciar la ficha castigaría al usuario por una acción que no procedía.
    expect(wrapper.text()).toContain('07:00')
    expect(wrapper.text()).toContain('Andrea Mendoza')
  })

  it('en cambio un fallo de CARGA sí sustituye el contenido', async () => {
    obtenerPlan.mockRejectedValue({ status: 500, message: 'La red no responde.' })
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).not.toContain('07:00')
    expect(wrapper.find('[role="alert"]').exists()).toBe(true)
  })

  it('distingue un plan inexistente de un error del servidor', async () => {
    obtenerPlan.mockRejectedValue({ status: 404, message: 'No existe.' })
    const wrapper = montar()
    await flushPromises()

    // Un 404 no se arregla reintentando: ofrecerlo sería una promesa falsa.
    expect(wrapper.text().toLowerCase()).toMatch(/no encontrad/)
  })

  it('retira la comida y refresca el plan cuando sí procede', async () => {
    obtenerPlan.mockResolvedValue(PLAN)
    eliminarComida.mockResolvedValue({ id: 1 })

    const wrapper = montar()
    await flushPromises()
    await confirmar(wrapper)

    expect(eliminarComida).toHaveBeenCalledWith('3', 1)
    // Se recarga: los totales del plan cambian al quitar una comida y dejarlos
    // como estaban mostraría unas calorías que ya no corresponden.
    expect(obtenerPlan).toHaveBeenCalledTimes(2)
    expect(wrapper.find('[role="status"]').text()).toContain('retirada')
  })

  /*
   * El watcher lleva `immediate: true`. Sin él, montar la vista ya «en» un plan
   * —que es lo único que pasa— no dispararía ninguna carga y la ficha se
   * quedaría eternamente en blanco.
   */
  it('carga al montar, no sólo al cambiar de plan', async () => {
    obtenerPlan.mockResolvedValue(PLAN)
    montar()
    await flushPromises()

    expect(obtenerPlan).toHaveBeenCalledWith('3')
  })
})
