import { enableAutoUnmount, flushPromises, mount } from '@vue/test-utils'
import { createPinia, setActivePinia } from 'pinia'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'

import UserMenu from '@/app/layouts/UserMenu.vue'
import { useAuthStore } from '@/core/auth/auth.store'
import { obtenerUsuario } from '@/modules/usuarios/services/usuarios.service'

enableAutoUnmount(afterEach)

vi.mock('vue-router', async (importOriginal) => {
  const original = await importOriginal()
  return { ...original, useRouter: () => ({ replace: vi.fn() }) }
})

vi.mock('@/modules/usuarios/services/usuarios.service', () => ({
  obtenerUsuario: vi.fn(),
}))

const RouterLinkStub = {
  props: ['to'],
  template: '<a href="#" role="menuitem" tabindex="-1"><slot /></a>',
}

function montar() {
  return mount(UserMenu, {
    attachTo: document.body,
    global: { stubs: { RouterLink: RouterLinkStub } },
  })
}

const disparador = () => document.querySelector('.menu__disparador')
const menu = () => document.querySelector('[role="menu"]')
const opciones = () => [...document.querySelectorAll('[role="menuitem"]')]

function teclaEn(elemento, key, opts = {}) {
  elemento.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, ...opts }))
}

describe('UserMenu', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
    const auth = useAuthStore()
    auth.usuario = {
      id: 1,
      nombre: 'Administrador Demo',
      correo: 'admin@gymbros.test',
      rol: 'admin',
    }
    auth.token = 'token-de-prueba'
    obtenerUsuario.mockResolvedValue({ fotoPerfil: '' })
  })

  it('da al disparador un nombre accesible propio', () => {
    montar()
    expect(disparador().getAttribute('aria-label')).toBe('Menú de usuario')
    expect(disparador().getAttribute('aria-expanded')).toBe('false')
  })

  it('muestra las iniciales en lugar de descargar una fotografía', () => {
    montar()
    expect(document.querySelector('.menu__avatar').textContent.trim()).toBe('AD')
    expect(document.querySelector('.menu__avatar').tagName).not.toBe('IMG')
  })

  it('descarta una foto antigua de sesión cuando el API confirma foto_perfil nulo', async () => {
    const auth = useAuthStore()
    auth.usuario.foto = 'usuarios/foto-antigua.webp'

    montar()
    await flushPromises()

    expect(obtenerUsuario).toHaveBeenCalledWith(1)
    expect(document.querySelector('.menu__avatar-img')).toBeNull()
    expect(document.querySelector('.menu__avatar').textContent.trim()).toBe('AD')
  })

  it('no muestra una foto antigua ni mientras espera la respuesta del API', () => {
    const auth = useAuthStore()
    auth.usuario.foto = 'usuarios/foto-antigua.webp'
    obtenerUsuario.mockReturnValue(new Promise(() => {}))

    montar()

    expect(document.querySelector('.menu__avatar-img')).toBeNull()
    expect(document.querySelector('.menu__avatar').textContent.trim()).toBe('AD')
  })

  it('deja la cabecera de identidad FUERA del contenedor con role="menu"', async () => {
    montar()
    await disparador().click()
    await flushPromises()

    expect(document.querySelector('.menu__cabecera')).not.toBeNull()
    expect(menu().querySelector('.menu__cabecera')).toBeNull()
  })

  describe('navegación con teclado', () => {
    it('ArrowDown sobre el disparador abre el menú y enfoca la primera opción', async () => {
      montar()
      disparador().focus()
      teclaEn(disparador(), 'ArrowDown')
      await flushPromises()

      expect(disparador().getAttribute('aria-expanded')).toBe('true')
      expect(document.activeElement).toBe(opciones()[0])
    })

    it('ArrowUp sobre el disparador abre el menú y enfoca la última', async () => {
      montar()
      disparador().focus()
      teclaEn(disparador(), 'ArrowUp')
      await flushPromises()

      const lista = opciones()
      expect(document.activeElement).toBe(lista[lista.length - 1])
    })

    it('recorre las opciones de forma circular', async () => {
      montar()
      disparador().focus()
      teclaEn(disparador(), 'ArrowDown')
      await flushPromises()

      const lista = opciones()
      expect(lista.length).toBeGreaterThan(1)

      for (let i = 0; i < lista.length; i += 1) teclaEn(menu(), 'ArrowDown')
      expect(document.activeElement).toBe(lista[0])

      teclaEn(menu(), 'ArrowUp')
      expect(document.activeElement).toBe(lista[lista.length - 1])
    })

    it('Home y End saltan a los extremos', async () => {
      montar()
      disparador().focus()
      teclaEn(disparador(), 'ArrowDown')
      await flushPromises()

      const lista = opciones()
      teclaEn(menu(), 'End')
      expect(document.activeElement).toBe(lista[lista.length - 1])

      teclaEn(menu(), 'Home')
      expect(document.activeElement).toBe(lista[0])
    })

    it('las opciones quedan fuera del orden de tabulación', async () => {
      montar()
      await disparador().click()
      await flushPromises()

      expect(opciones().every((o) => o.getAttribute('tabindex') === '-1')).toBe(true)
    })

    it('Tab cierra el menú y devuelve el flujo al documento', async () => {
      montar()
      disparador().focus()
      teclaEn(disparador(), 'ArrowDown')
      await flushPromises()
      expect(disparador().getAttribute('aria-expanded')).toBe('true')

      teclaEn(menu(), 'Tab')
      await flushPromises()
      expect(disparador().getAttribute('aria-expanded')).toBe('false')
    })
  })

  it('Escape cierra el menú y devuelve el foco al disparador', async () => {
    montar()
    await disparador().click()
    await flushPromises()
    expect(disparador().getAttribute('aria-expanded')).toBe('true')

    teclaEn(document.querySelector('.menu'), 'Escape')
    await flushPromises()

    expect(disparador().getAttribute('aria-expanded')).toBe('false')
    expect(document.activeElement).toBe(disparador())
  })
})
