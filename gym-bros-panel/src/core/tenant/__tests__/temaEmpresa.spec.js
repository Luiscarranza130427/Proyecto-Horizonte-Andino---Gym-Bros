import { describe, expect, it } from 'vitest'

import { VARIABLES_TEMA, calcularTemaEmpresa, contraste, hexARgb } from '@/core/tenant/temaEmpresa'

const TEXTO = hexARgb('#e5e2e1')
const TEXTO_SECUNDARIO = hexARgb('#c6c6c6')

describe('calcularTemaEmpresa', () => {
  it('usa color_2 como acento en lugar del rojo de Gym Bros (Titan Gym)', () => {
    const tema = calcularTemaEmpresa({ colorFondo: '#111111', colorAcento: '#14ff5b' })

    expect(tema['--gb-red']).toBe('#14ff5b')
    expect(tema['--gb-red-rgb']).toBe('20, 255, 91')
    // Sobre un verde claro, el texto de los botones pasa a ser oscuro.
    expect(tema['--gb-on-red']).toBe('#000000')
    expect(contraste(hexARgb(tema['--gb-on-red']), hexARgb(tema['--gb-red']))).toBeGreaterThan(4.5)
  })

  it('tiñe las capas de fondo con color_1 sin perder la legibilidad del texto', () => {
    const tema = calcularTemaEmpresa({ colorFondo: '#167D50', colorAcento: '#FFFFFF' })

    expect(tema['--gb-bg']).not.toBe('#131313')
    for (const capa of ['--gb-bg', '--gb-surface', '--gb-surface-high', '--gb-surface-highest']) {
      expect(contraste(TEXTO, hexARgb(tema[capa]))).toBeGreaterThanOrEqual(7)
      expect(contraste(TEXTO_SECUNDARIO, hexARgb(tema[capa]))).toBeGreaterThanOrEqual(4.5)
    }
  })

  it('un fondo claro sólo tiñe lo que el texto claro tolera', () => {
    const tema = calcularTemaEmpresa({ colorFondo: '#ffffff' })

    expect(contraste(TEXTO, hexARgb(tema['--gb-surface-highest']))).toBeGreaterThanOrEqual(7)
    expect(tema['--gb-red']).toBeUndefined()
  })

  it('aclara un acento demasiado oscuro para que destaque sobre el fondo', () => {
    const tema = calcularTemaEmpresa({ colorFondo: '#111111', colorAcento: '#1c1b1b' })

    const fondo = hexARgb(tema['--gb-bg'])
    expect(contraste(hexARgb(tema['--gb-red']), fondo)).toBeGreaterThanOrEqual(3)
    expect(
      contraste(hexARgb(tema['--gb-red-text']), hexARgb(tema['--gb-surface'])),
    ).toBeGreaterThanOrEqual(4.5)
    expect(tema['--gb-focus']).toBe(tema['--gb-red-text'])
  })

  it('ignora colores ausentes o inválidos y deja el tema por defecto', () => {
    expect(calcularTemaEmpresa({})).toEqual({})
    expect(calcularTemaEmpresa({ colorFondo: 'rojo', colorAcento: '#12' })).toEqual({})
  })

  it('sólo escribe variables que el store sabe limpiar', () => {
    const tema = calcularTemaEmpresa({ colorFondo: '#202020', colorAcento: '#00AEEF' })

    for (const variable of Object.keys(tema)) expect(VARIABLES_TEMA).toContain(variable)
  })
})
