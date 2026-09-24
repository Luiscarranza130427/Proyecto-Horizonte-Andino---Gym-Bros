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
  actualizarLogoEmpresa: vi.fn().mockResolvedValue({
    logo: 'empresas/nuevo.webp',
    logoUrl: 'http://api.test/storage/empresas/nuevo.webp',
  }),
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

  it('guardar datos de la sede no cambia el nombre de quien inició sesión', async () => {
    const { useAuthStore } = await import('@/core/auth/auth.store')
    const { useTenantStore } = await import('@/core/tenant/tenant.store')
    const auth = useAuthStore()
    auth.usuario = {
      id: 1,
      nombre: 'Juanito Perezz',
      foto: 'http://api.test/storage/usuario/j.jpg',
    }
    const wrapper = mount(PerfilView, { global: { stubs: { PageHeader: true, RouterLink: true } } })
    await new Promise((r) => setTimeout(r, 50))

    wrapper
      .findComponent({ name: 'PerfilDatosForm' })
      .vm.$emit('guardar', { nombre: 'Titan Gym Modificado' })
    await new Promise((r) => setTimeout(r, 20))

    // Antes el menú de usuario pasaba a mostrar el nombre de la empresa.
    expect(auth.usuario.nombre).toBe('Juanito Perezz')
    expect(useTenantStore().tenant.nombre).toBe('Titan Gym Modificado')
  })

  it('el logo se sube por su endpoint y no reemplaza la foto personal', async () => {
    const perfilService = await import('@/modules/perfil/services/perfil.service')
    const { useAuthStore } = await import('@/core/auth/auth.store')
    const auth = useAuthStore()
    auth.usuario = {
      id: 1,
      nombre: 'Juanito Perezz',
      foto: 'http://api.test/storage/usuario/j.jpg',
    }
    const wrapper = mount(PerfilView, { global: { stubs: { PageHeader: true, RouterLink: true } } })
    await new Promise((r) => setTimeout(r, 50))

    const imagen = 'data:image/webp;base64,AAAA'
    wrapper.findComponent({ name: 'PerfilHeader' }).vm.$emit('cambiar-foto', { url: imagen })
    await new Promise((r) => setTimeout(r, 20))

    expect(perfilService.actualizarLogoEmpresa).toHaveBeenCalledWith(1, imagen)
    // Antes viajaba dentro de PUT /empresas/{id} y la API lo rechazaba siempre.
    expect(perfilService.actualizarPerfil).not.toHaveBeenCalledWith(
      expect.objectContaining({ logo: imagen }),
    )
    expect(auth.usuario.foto).toBe('http://api.test/storage/usuario/j.jpg')
  })
})
