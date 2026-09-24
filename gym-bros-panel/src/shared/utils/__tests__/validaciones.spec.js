import { describe, expect, it } from 'vitest'

import {
  esColorValido,
  esCorreoValido,
  esFechaPasada,
  esTelefonoValido,
  esUrlValida,
} from '@/shared/utils/validaciones'

describe('esCorreoValido', () => {
  it.each(['admin@gymbros.test', 'rosa.quispe@gym-bros.com.pe', 'a@b.co'])('acepta %s', (valor) => {
    expect(esCorreoValido(valor)).toBe(true)
  })

  it.each(['', 'sin-arroba', 'sin@dominio', 'con espacio@correo.com', 'dos@@arrobas.com'])(
    'rechaza %s',
    (valor) => {
      expect(esCorreoValido(valor)).toBe(false)
    },
  )

  it('tolera valores ausentes y espacios alrededor', () => {
    expect(esCorreoValido(undefined)).toBe(false)
    expect(esCorreoValido(null)).toBe(false)
    expect(esCorreoValido('  admin@gymbros.test  ')).toBe(true)
  })
})

describe('esTelefonoValido', () => {
  it.each(['+51 987 654 321', '987654321', '01-234-5678', '+5119876543'])('acepta %s', (valor) => {
    expect(esTelefonoValido(valor)).toBe(true)
  })

  it('rechaza por longitud, contando sólo dígitos', () => {
    expect(esTelefonoValido('123456')).toBe(false) // 6 dígitos
    expect(esTelefonoValido('1234567')).toBe(true) // 7, el mínimo
    expect(esTelefonoValido('123456789012345')).toBe(true) // 15, el máximo E.164
    expect(esTelefonoValido('1234567890123456')).toBe(false) // 16
  })

  it('rechaza caracteres que no son de un teléfono', () => {
    expect(esTelefonoValido('987-654-abc')).toBe(false)
    expect(esTelefonoValido('(01) 234 5678')).toBe(false)
    expect(esTelefonoValido('')).toBe(false)
  })
})

describe('esColorValido', () => {
  it('exige almohadilla y seis dígitos hexadecimales', () => {
    expect(esColorValido('#e50914')).toBe(true)
    expect(esColorValido('#E50914')).toBe(true)
    expect(esColorValido('e50914')).toBe(false)
    expect(esColorValido('#e509')).toBe(false)
    expect(esColorValido('#gggggg')).toBe(false)
  })
})

describe('esUrlValida', () => {
  it('acepta http y https absolutos', () => {
    expect(esUrlValida('https://powergym.example')).toBe(true)
    expect(esUrlValida('http://localhost:8000/ruta')).toBe(true)
  })

  it('rechaza esquemas peligrosos y URLs incompletas', () => {
    expect(esUrlValida('javascript:alert(1)')).toBe(false)
    expect(esUrlValida('data:text/html,<script>')).toBe(false)
    expect(esUrlValida('powergym.example')).toBe(false)
    expect(esUrlValida('')).toBe(false)
  })
})

describe('esFechaPasada', () => {
  const ahora = new Date('2026-08-26T12:00:00')

  it('acepta fechas anteriores y el propio día', () => {
    expect(esFechaPasada('1996-05-12', ahora)).toBe(true)
    expect(esFechaPasada('2026-08-26', ahora)).toBe(true)
  })

  it('rechaza fechas futuras e inválidas', () => {
    expect(esFechaPasada('2999-01-01', ahora)).toBe(false)
    expect(esFechaPasada('no-es-una-fecha', ahora)).toBe(false)
  })
})
