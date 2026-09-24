import { describe, expect, it } from 'vitest'

import { formatearFecha, formatearMoneda, formatearTiempoRelativo } from '@/shared/utils/formato'

describe('formatearTiempoRelativo', () => {
  it.each([undefined, '', 'dato-invalido'])(
    'devuelve una alternativa segura para la fecha %s',
    (fecha) => {
      expect(formatearTiempoRelativo(fecha)).toBe('Fecha no disponible')
    },
  )
})

describe('formatearFecha', () => {
  it('formatea una fecha ISO sin mostrar el valor técnico', () => {
    expect(formatearFecha('2026-08-14')).toContain('2026')
    expect(formatearFecha('2026-08-14')).not.toContain('T00:00')
  })

  it('tolera fechas inválidas', () => {
    expect(formatearFecha('sin-fecha')).toBe('Fecha no disponible')
  })
})

describe('formatearMoneda', () => {
  it('muestra importes en soles y conserva los centavos', () => {
    const resultado = formatearMoneda(189.5)

    expect(resultado).toContain('189.50')
    expect(resultado).toMatch(/S\//)
  })
})
