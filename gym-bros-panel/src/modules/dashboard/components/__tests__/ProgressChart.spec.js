import { mount } from '@vue/test-utils'
import { beforeEach, describe, expect, it, vi } from 'vitest'

const dobles = vi.hoisted(() => ({
  destruir: vi.fn(),
  Chart: vi.fn(),
}))

vi.mock('chart.js', () => {
  dobles.Chart.register = vi.fn()
  dobles.Chart.mockImplementation(function crearGrafico() {
    this.destroy = dobles.destruir
  })

  return {
    CategoryScale: {},
    Chart: dobles.Chart,
    LineController: {},
    LineElement: {},
    LinearScale: {},
    PointElement: {},
    Tooltip: {},
  }
})

import ProgressChart from '@/modules/dashboard/components/ProgressChart.vue'

const PROGRESO = {
  titulo: 'Usuarios activos',
  descripcion: 'Últimos meses',
  unidad: 'usuarios activos',
  etiquetas: ['Jul', 'Ago'],
  valores: [317, 346],
  resumen: { etiqueta: 'Total', valor: 346, detalle: '+29' },
}

describe('ProgressChart', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('muestra un estado vacío sin intentar crear Chart.js', () => {
    const wrapper = mount(ProgressChart, {
      props: { progreso: { ...PROGRESO, etiquetas: [], valores: [] } },
    })

    expect(wrapper.text()).toContain('Aún no hay progreso suficiente')
    expect(dobles.Chart).not.toHaveBeenCalled()
  })

  it('crea y destruye la instancia del gráfico', async () => {
    window.matchMedia = vi.fn().mockReturnValue({ matches: true })
    const wrapper = mount(ProgressChart, { props: { progreso: PROGRESO } })
    await vi.waitFor(() => expect(dobles.Chart).toHaveBeenCalledOnce())

    wrapper.unmount()

    expect(dobles.destruir).toHaveBeenCalledOnce()
  })

  it('destruye y vuelve a crear el gráfico al alternar entre datos y vacío', async () => {
    window.matchMedia = vi.fn().mockReturnValue({ matches: true })
    const wrapper = mount(ProgressChart, { props: { progreso: PROGRESO } })
    await vi.waitFor(() => expect(dobles.Chart).toHaveBeenCalledTimes(1))

    await wrapper.setProps({ progreso: { ...PROGRESO, etiquetas: [], valores: [] } })
    await vi.waitFor(() => expect(dobles.destruir).toHaveBeenCalledTimes(1))
    expect(wrapper.text()).toContain('Aún no hay progreso suficiente')

    await wrapper.setProps({ progreso: PROGRESO })
    await vi.waitFor(() => expect(dobles.Chart).toHaveBeenCalledTimes(2))

    wrapper.unmount()
    expect(dobles.destruir).toHaveBeenCalledTimes(2)
  })
})
