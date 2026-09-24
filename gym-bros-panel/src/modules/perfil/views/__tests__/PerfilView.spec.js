import { mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import PerfilView from '../PerfilView.vue'

vi.mock('@/modules/perfil/services/perfil.service', () => ({
  obtenerPerfil: vi.fn().mockResolvedValue({
    id: 1,
    nombre: 'Titan Gym',
    nombre_gerente: 'Carlos Mendoza',
    gerente: 'Carlos Mendoza',
    correo: 'contacto@gymbros.pe',
    telefono: '+51 976 123 456',
    ruc: '20609876541',
    region: 'Cajamarca',
    direccion: 'Av. Hoyos Rubio 123, Cajamarca',
    enlace_web: 'https://gymbros.pe',
    rol: 'empresa',
    rolEtiqueta: 'Sede Principal',
    plan: 'Titanio Enterprise',
    fotoPerfil: '',
    empresa: { id: 1, nombre: 'Titan Gym', ruc: '20609876541', plan: 'Titanio Enterprise' },
    estadisticas: {
      accesosTotales: 10,
      ultimoAcceso: 'Hoy',
      sesionesActivas: 2,
      miembrosActivos: 8,
      miembroDesde: '2025',
    },
    sesiones: [{ id: '1', dispositivo: 'Chrome Windows', esActual: true }],
    preferencias: { idioma: 'es', tema: 'oscuro', notifEmail: true, notifPush: true },
  }),
  actualizarPerfil: vi.fn().mockResolvedValue({
    id: 1,
    nombre: 'Titan Gym Modificado',
    nombre_gerente: 'Carlos Mendoza',
    correo: 'contacto@gymbros.pe',
  }),
  cambiarContrasena: vi.fn().mockResolvedValue({ exito: true, mensaje: 'Clave cambiada' }),
  actualizarPreferencias: vi.fn().mockResolvedValue({ idioma: 'es', notifEmail: false }),
  cerrarOtrasSesiones: vi.fn().mockResolvedValue({ exito: true, mensaje: 'Sesiones cerradas' }),
}))

describe('PerfilView.vue', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('renderiza la cabecera del perfil y las pestañas', async () => {
    const wrapper = mount(PerfilView, {
      global: {
        stubs: {
          PageHeader: { template: '<header><slot /><slot name="acciones" /></header>' },
          RouterLink: { template: '<a><slot /></a>' },
        },
      },
    })

    // Esperar resolución de promesas
    await new Promise((r) => setTimeout(r, 50))
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Titan Gym')
    expect(wrapper.text()).toContain('Carlos Mendoza')
    expect(wrapper.findAll('.perfil-tab').length).toBe(4)
  })

  it('permite cambiar entre pestañas activas', async () => {
    const wrapper = mount(PerfilView, {
      global: {
        stubs: {
          PageHeader: true,
          RouterLink: true,
        },
      },
    })

    await new Promise((r) => setTimeout(r, 50))
    await wrapper.vm.$nextTick()

    const tabs = wrapper.findAll('.perfil-tab')
    // Click en la pestaña de Identidad y Horarios (index 1)
    await tabs[1].trigger('click')
    expect(wrapper.findComponent({ name: 'PerfilEmpresaCard' }).exists()).toBe(true)

    // Click en la pestaña de Seguridad y Claves (index 2)
    await tabs[2].trigger('click')
    expect(wrapper.findComponent({ name: 'PerfilSeguridadForm' }).exists()).toBe(true)

    // Click en la pestaña de Preferencias (index 3)
    await tabs[3].trigger('click')
    expect(wrapper.findComponent({ name: 'PerfilPreferenciasForm' }).exists()).toBe(true)
  })
})
