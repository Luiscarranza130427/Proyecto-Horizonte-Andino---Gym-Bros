import { flushPromises, mount } from '@vue/test-utils'
import { reactive } from 'vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'

import UsuarioDetailView from '@/modules/usuarios/views/UsuarioDetailView.vue'
import {
  obtenerHistorialUsuario,
  obtenerUsuario,
} from '@/modules/usuarios/services/usuarios.service'

const route = reactive({ params: { id: '1' }, query: {} })
const replace = vi.fn()

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return {
    ...original,
    useRoute: () => route,
    useRouter: () => ({ replace, push: vi.fn() }),
  }
})

vi.mock('@/modules/usuarios/services/usuarios.service', () => ({
  obtenerUsuario: vi.fn(),
  obtenerHistorialUsuario: vi.fn(),
  desactivarUsuario: vi.fn(),
}))

const USUARIO = {
  id: 1,
  nombre: 'Carlos',
  apellido: 'Ramírez',
  correo: 'carlos@gymbros.test',
  tipoDocumento: 'dni',
  numeroDocumento: '71000001',
  telefono: '+51 987654321',
  direccion: 'Av. Principal 101',
  fechaNacimiento: '1995-01-10',
  inicioSuscripcion: '2026-09-01',
  finSuscripcion: '2026-09-30',
  fechaRegistro: '2026-01-10',
  rol: 'member',
  estado: 'active',
  fotoPerfil: '',
  empresa: { id: 1, nombre: 'Power Gym' },
  suscripcion: { estado: 'active', nombrePlan: 'Mensual', diasRestantes: 14 },
  actividad: { rutinas: 3, asistenciasMes: 12, ultimaActividad: '2026-08-20T10:00:00Z' },
}

function montar() {
  return mount(UsuarioDetailView, {
    global: {
      stubs: {
        RouterLink: { props: ['to'], template: '<a href="#"><slot /></a>' },
        Teleport: true,
      },
    },
  })
}

describe('UsuarioDetailView', () => {
  beforeEach(() => {
    route.params.id = '1'
    route.query = {}
    replace.mockReset()
    obtenerUsuario.mockReset()
    obtenerHistorialUsuario.mockReset()
  })

  it('muestra un 404 recuperable', async () => {
    obtenerUsuario.mockRejectedValue({ status: 404, message: 'El usuario solicitado no existe.' })
    const wrapper = montar()
    await flushPromises()
    expect(wrapper.text()).toContain('Usuario no encontrado')
    expect(wrapper.text()).toContain('Volver a usuarios')
  })

  it('mantiene el perfil visible si falla únicamente el historial', async () => {
    obtenerUsuario.mockResolvedValue(USUARIO)
    obtenerHistorialUsuario.mockRejectedValue(new Error('Historial temporalmente no disponible.'))
    const wrapper = montar()
    await flushPromises()

    expect(wrapper.text()).toContain('Carlos Ramírez')
    expect(wrapper.text()).toContain('Power Gym')
    expect(wrapper.text()).toContain('No pudimos cargar el historial')
    expect(wrapper.text()).toContain('Historial temporalmente no disponible.')
  })
})
