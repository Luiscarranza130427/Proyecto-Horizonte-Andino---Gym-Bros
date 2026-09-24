import { describe, expect, it } from 'vitest'

import { SECCIONES, SECCIONES_DE_USUARIO } from '@/app/navigation/navegacion'
import router from '@/app/router'

const TODAS = [...SECCIONES, ...SECCIONES_DE_USUARIO]

describe('rutas del panel', () => {
  it('cada sección del menú resuelve a una ruta real', () => {
    for (const seccion of TODAS) {
      const resuelta = router.resolve({ name: seccion.name })

      expect(resuelta.matched.length, seccion.name).toBeGreaterThan(0)
      expect(resuelta.name, seccion.name).toBe(seccion.name)
    }
  })

  it('ninguna sección del panel queda pública', () => {
    for (const seccion of TODAS) {
      expect(router.resolve({ name: seccion.name }).meta.requiresAuth, seccion.name).toBe(true)
    }
  })

  it('cada sección aporta el título que muestran la cabecera y la pestaña', () => {
    for (const seccion of TODAS) {
      expect(router.resolve({ name: seccion.name }).meta.title, seccion.name).toBe(seccion.title)
    }
  })

  it('el login es público y no exige sesión', () => {
    const login = router.resolve({ name: 'login' })

    expect(login.meta.requiresAuth).toBeUndefined()
    expect(login.meta.guestOnly).toBe(true)
  })

  it.each([
    ['empresas-listado', '/empresas', 'Empresas'],
    ['empresa-nueva', '/empresas/nueva', 'Nueva empresa'],
    ['empresa-detalle', '/empresas/15', 'Detalle empresa'],
    ['empresa-editar', '/empresas/15/editar', 'Editar empresa'],
  ])('resuelve la ruta %s y hereda autenticación', (name, path, title) => {
    const params = name.includes('detalle') || name.includes('editar') ? { id: 15 } : undefined
    const resuelta = router.resolve({ name, params })

    expect(resuelta.path).toBe(path)
    expect(resuelta.meta.title).toBe(title)
    expect(resuelta.meta.requiresAuth).toBe(true)
    expect(resuelta.matched.some((registro) => registro.name === 'empresas')).toBe(true)
  })

  it.each([
    ['usuarios-listado', '/usuarios', 'Usuarios'],
    ['usuario-nuevo', '/usuarios/nuevo', 'Nuevo usuario'],
    ['usuario-detalle', '/usuarios/15', 'Perfil de usuario'],
    ['usuario-editar', '/usuarios/15/editar', 'Editar usuario'],
  ])('resuelve la ruta de Usuarios %s y mantiene activo su padre', (name, path, title) => {
    const params = name.includes('detalle') || name.includes('editar') ? { id: 15 } : undefined
    const resuelta = router.resolve({ name, params })

    expect(resuelta.path).toBe(path)
    expect(resuelta.meta.title).toBe(title)
    expect(resuelta.meta.requiresAuth).toBe(true)
    expect(resuelta.matched.some((registro) => registro.name === 'usuarios')).toBe(true)
  })

  it.each([
    ['ejercicios-listado', '/ejercicios', 'Ejercicios'],
    ['ejercicio-nuevo', '/ejercicios/nuevo', 'Nuevo ejercicio'],
    ['ejercicio-detalle', '/ejercicios/15', 'Detalle ejercicio'],
    ['ejercicio-editar', '/ejercicios/15/editar', 'Editar ejercicio'],
  ])('resuelve la ruta de Ejercicios %s y mantiene activo su padre', (name, path, title) => {
    const params = name.includes('detalle') || name.includes('editar') ? { id: 15 } : undefined
    const resuelta = router.resolve({ name, params })

    expect(resuelta.path).toBe(path)
    expect(resuelta.meta.title).toBe(title)
    expect(resuelta.meta.requiresAuth).toBe(true)
    expect(resuelta.matched.some((registro) => registro.name === 'ejercicios')).toBe(true)
  })

  it.each([
    ['planes-listado', '/planes', 'Planes'],
    ['planes-administrar', '/planes/administrar', 'Administrar planes'],
    ['plan-nuevo', '/planes/nuevo', 'Nuevo plan'],
    ['plan-editar', '/planes/15/editar', 'Editar plan'],
  ])('resuelve la ruta de Planes %s y mantiene activo su padre', (name, path, title) => {
    const params = name === 'plan-editar' ? { id: 15 } : undefined
    const resuelta = router.resolve({ name, params })

    expect(resuelta.path).toBe(path)
    expect(resuelta.meta.title).toBe(title)
    expect(resuelta.meta.requiresAuth).toBe(true)
    expect(resuelta.matched.some((registro) => registro.name === 'planes')).toBe(true)
  })

  it('no registra como ruta simple ningún módulo con árbol propio', () => {
    const conArbolPropio = SECCIONES.filter((seccion) => seccion.arbolPropio)
    expect(conArbolPropio.length).toBeGreaterThan(0)

    for (const seccion of conArbolPropio) {
      const resuelta = router.resolve({ name: seccion.name })
      const registro = resuelta.matched.at(-1)

      expect(registro.redirect, `${seccion.name} debería redirigir a su listado`).toEqual({
        name: `${seccion.name}-listado`,
      })
      expect(registro.children.length, `${seccion.name} debería tener hijos`).toBeGreaterThan(0)
      expect(router.resolve({ name: `${seccion.name}-listado` }).path).toBe(`/${seccion.path}`)
    }
  })

  it('las secciones sin vista ni árbol propio caen en «En construcción»', () => {
    const enConstruccion = SECCIONES.filter((s) => !s.arbolPropio && !s.vista)
    expect(enConstruccion.length).toBeGreaterThan(0)

    for (const seccion of enConstruccion) {
      const resuelta = router.resolve({ name: seccion.name })
      expect(resuelta.path).toBe(`/${seccion.path}`)
      expect(resuelta.meta.requiresAuth).toBe(true)
      expect(resuelta.matched.at(-1).redirect).toBeUndefined()
    }
  })
})
