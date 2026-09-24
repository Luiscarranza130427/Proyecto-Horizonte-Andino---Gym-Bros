import { describe, expect, it } from 'vitest'

import { resolverUrlStorage } from '@/shared/utils/storage'

describe('storage utils - resolverUrlStorage', () => {
  it('devuelve cadena vacía si no recibe ruta', () => {
    expect(resolverUrlStorage(null)).toBe('')
    expect(resolverUrlStorage('')).toBe('')
    expect(resolverUrlStorage(undefined)).toBe('')
  })

  it('respeta URLs absolutas http/https y data URIs', () => {
    expect(resolverUrlStorage('https://example.com/logo.png')).toBe('https://example.com/logo.png')
    expect(resolverUrlStorage('http://192.168.1.57:8000/storage/logo.png')).toBe(
      'http://192.168.1.57:8000/storage/logo.png',
    )
    expect(resolverUrlStorage('data:image/png;base64,iVBORw0KGgo=')).toBe(
      'data:image/png;base64,iVBORw0KGgo=',
    )
  })

  it('resuelve rutas internas de Windows storage/app/public/...', () => {
    const res = resolverUrlStorage('gym-bros\\storage\\app\\public\\empresas\\titan_gym.webp')
    expect(res).toContain('/storage/empresas/titan_gym.webp')
  })

  it('resuelve rutas relativas estándar', () => {
    const res = resolverUrlStorage('empresas/titan_gym.webp')
    expect(res).toContain('/storage/empresas/titan_gym.webp')
  })

  it('no duplica el prefijo storage cuando la ruta viene de public/storage', () => {
    const res = resolverUrlStorage(
      '\\laragon\\www\\gym-bros\\public\\storage\\usuario\\prueba-gym.png',
    )
    expect(res).not.toContain('/storage/storage/')
    expect(res).toContain('/storage/usuario/prueba-gym.png')
  })
})
