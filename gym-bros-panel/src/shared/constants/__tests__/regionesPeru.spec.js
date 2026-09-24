import { describe, expect, it } from 'vitest'

import { REGIONES_PERU, etiquetaRegion, valorRegion } from '@/shared/constants/regionesPeru'

describe('regionesPeru', () => {
  it('usa como valor el texto sin tildes que acepta la API', () => {
    for (const { valor } of REGIONES_PERU) {
      expect(valor.normalize('NFD')).toBe(valor)
    }
    expect(REGIONES_PERU).toHaveLength(25)
  })

  it('traduce una región guardada con tildes o en otra caja al valor de la API', () => {
    expect(valorRegion('Junín')).toBe('Junin')
    expect(valorRegion(' SAN MARTÍN ')).toBe('San Martin')
    expect(valorRegion('')).toBe('')
    expect(valorRegion(null)).toBe('')
    // Lo que no es una región conocida se conserva para que la API lo explique.
    expect(valorRegion('Atlántida')).toBe('Atlántida')
  })

  it('muestra la etiqueta con tildes', () => {
    expect(etiquetaRegion('Huanuco')).toBe('Huánuco')
    expect(etiquetaRegion('Áncash')).toBe('Áncash')
    expect(etiquetaRegion('Atlántida')).toBe('Atlántida')
    expect(etiquetaRegion(undefined)).toBe('')
  })
})
