import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'
import EmpresaStatusBadge from '@/modules/empresas/components/EmpresaStatusBadge.vue'

describe('Estado de suscripción', () => {
  it.each([
    ['Activo', 'activo'],
    ['Inactivo', 'rojo'],
    ['Por Vencer', 'amarillo'],
  ])('muestra %s sin derivarlo de la habilitación manual', (estado, color) => {
    const wrapper = mount(EmpresaStatusBadge, { props: { suscripcion: true, estado } })
    expect(wrapper.text()).toBe(estado)
    expect(wrapper.classes()).toContain(`estado--${color}`)
  })
  it('no inventa un estado cuando falta información', () => {
    expect(mount(EmpresaStatusBadge, { props: { suscripcion: true } }).text()).toBe(
      'Sin información',
    )
  })
})
