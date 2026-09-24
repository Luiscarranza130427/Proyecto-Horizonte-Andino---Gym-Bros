import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import EmpresaDetails from '@/modules/empresas/components/EmpresaDetails.vue'

const EMPRESA = {
  id: 1,
  nombre: 'Titan Gym',
  gerente: 'Juanito Perezz',
  ruc: '20609876541',
  correo: 'contacto@titan.pe',
  telefono: '976123456',
  region: 'Junin',
  direccion: 'Av. Principal 101',
  sitioWeb: 'https://titan.pe',
  usuarios: 1250,
  fechaRegistro: '2026-01-10',
  colorPrimario: '#111111',
  colorSecundario: '#ba270d',
  estado: 'active',
  horario_inicio_lunes: '06:00',
  horario_fin_lunes: '22:00',
}

function montar(empresa) {
  return mount(EmpresaDetails, { props: { empresa } })
}

function valorDe(wrapper, termino) {
  const fila = wrapper.findAll('dt').find((dt) => dt.text() === termino)
  return fila.element.nextElementSibling.textContent.trim()
}

describe('EmpresaDetails', () => {
  it('muestra la región con tildes y enlaces de contacto', () => {
    const wrapper = montar(EMPRESA)

    expect(valorDe(wrapper, 'Región')).toBe('Junín')
    expect(wrapper.get('a[href="mailto:contacto@titan.pe"]').text()).toBe('contacto@titan.pe')
    expect(wrapper.get('a[href="tel:976123456"]').text()).toBe('976123456')
    const web = wrapper.get('a[target="_blank"]')
    expect(web.attributes('href')).toBe('https://titan.pe/')
    expect(web.attributes('rel')).toBe('noopener noreferrer')
    expect(valorDe(wrapper, 'Lunes')).toBe('06:00–22:00')
  })

  it('no enlaza un sitio web con un protocolo inseguro', () => {
    const wrapper = montar({ ...EMPRESA, sitioWeb: 'javascript:alert(1)' })

    expect(wrapper.find('a[target="_blank"]').exists()).toBe(false)
    expect(valorDe(wrapper, 'Sitio web')).toBe('javascript:alert(1)')
  })

  it('rotula los datos ausentes en lugar de dejar enlaces vacíos', () => {
    const wrapper = montar({
      ...EMPRESA,
      gerente: '',
      ruc: '',
      correo: '',
      telefono: '',
      region: '',
      direccion: '',
      sitioWeb: '',
      usuarios: null,
      horario_fin_lunes: '',
    })

    expect(wrapper.find('a[href^="mailto:"]').exists()).toBe(false)
    expect(wrapper.find('a[href^="tel:"]').exists()).toBe(false)
    expect(valorDe(wrapper, 'Correo')).toBe('No especificado')
    expect(valorDe(wrapper, 'Teléfono')).toBe('No especificado')
    expect(valorDe(wrapper, 'Gerente')).toBe('No especificado')
    expect(valorDe(wrapper, 'Región')).toBe('No especificada')
    expect(valorDe(wrapper, 'Sitio web')).toBe('No especificado')
    expect(valorDe(wrapper, 'Usuarios')).toBe('Sin datos')
    expect(wrapper.text()).toContain('Región no especificada')
    expect(valorDe(wrapper, 'Lunes')).not.toContain('06:00')
  })
})
