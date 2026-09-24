import { computed, ref } from 'vue'
import { defineStore } from 'pinia'

import * as authService from '@/core/auth/auth.service'
import { can as evaluarPermiso } from '@/core/permissions/can'
import { guardarSesion, leerSesion, limpiarSesion } from '@/core/storage/session.storage'
import { useTenantStore } from '@/core/tenant/tenant.store'

export const useAuthStore = defineStore('auth', () => {
  const sesionPrevia = leerSesion()

  const usuario = ref(sesionPrevia?.usuario ?? null)
  const token = ref(sesionPrevia?.token ?? null)
  const cargando = ref(false)

  const estaAutenticado = computed(() => Boolean(token.value))
  const rol = computed(() => usuario.value?.rol ?? usuario.value?.role ?? 'usuario')

  function can(permiso) {
    return evaluarPermiso(permiso, usuario.value)
  }

  async function iniciarSesion(credenciales) {
    cargando.value = true
    try {
      const sesion = await authService.iniciarSesion(credenciales)
      usuario.value = sesion.usuario
      token.value = sesion.token
      guardarSesion(sesion)
    } finally {
      cargando.value = false
    }
  }

  function olvidarSesion() {
    usuario.value = null
    token.value = null
    limpiarSesion()
    useTenantStore().limpiarTenant()
  }

  function actualizarUsuario(datos = {}) {
    if (!usuario.value) return
    usuario.value = { ...usuario.value, ...datos }
    guardarSesion({ usuario: usuario.value, token: token.value })
  }

  async function cerrarSesion() {
    try {
      await authService.cerrarSesion()
    } catch {
      // Si el backend falla, cerramos de todas formas la sesión local.
    } finally {
      olvidarSesion()
    }
  }

  return {
    usuario,
    token,
    cargando,
    rol,
    estaAutenticado,
    can,
    iniciarSesion,
    actualizarUsuario,
    cerrarSesion,
    olvidarSesion,
  }
})
