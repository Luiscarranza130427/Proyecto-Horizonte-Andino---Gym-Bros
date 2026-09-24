import { describe, expect, it } from 'vitest'
import {
  actualizarPerfil,
  actualizarPreferencias,
  cambiarContrasena,
  cerrarOtrasSesiones,
  obtenerPerfil,
} from '../perfil.service'

describe('perfil.service', () => {
  it('obtiene los datos del perfil activo', async () => {
    const perfil = await obtenerPerfil()
    expect(perfil).toBeDefined()
    expect(perfil.correo).toBe('admin@gymbros.com')
    expect(perfil.nombre).toBeDefined()
    expect(perfil.estadisticas).toBeDefined()
  })

  it('actualiza los datos personales del perfil', async () => {
    const actualizado = await actualizarPerfil({
      nombre: 'Luis Admin',
      apellido: 'Carranza Editado',
      telefono: '+51 999 888 777',
    })
    expect(actualizado.nombre).toBe('Luis Admin')
    expect(actualizado.apellido).toBe('Carranza Editado')
    expect(actualizado.telefono).toBe('+51 999 888 777')
  })

  it('valida campos obligatorios al actualizar perfil', async () => {
    await expect(actualizarPerfil({ nombre: '', apellido: '' })).rejects.toThrow()
  })

  it('valida cambio de contraseña correctamente', async () => {
    const res = await cambiarContrasena({
      actual: 'admin123',
      nueva: 'nuevaClaveSegura2026',
      confirmacion: 'nuevaClaveSegura2026',
    })
    expect(res.exito).toBe(true)
  })

  it('rechaza contraseñas no coincidentes', async () => {
    await expect(
      cambiarContrasena({
        actual: 'admin123',
        nueva: 'clave1',
        confirmacion: 'clave2',
      }),
    ).rejects.toThrow()
  })

  it('actualiza preferencias de notificaciones', async () => {
    const pref = await actualizarPreferencias({
      notifEmail: false,
      notifPush: true,
    })
    expect(pref.notifEmail).toBe(false)
    expect(pref.notifPush).toBe(true)
  })

  it('cierra otras sesiones activas', async () => {
    const res = await cerrarOtrasSesiones()
    expect(res.exito).toBe(true)
    const perfil = await obtenerPerfil()
    expect(perfil.sesiones.length).toBe(1)
    expect(perfil.sesiones[0].esActual).toBe(true)
  })
})
