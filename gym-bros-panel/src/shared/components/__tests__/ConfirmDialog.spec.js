import { mount } from '@vue/test-utils'
import { describe, expect, it } from 'vitest'

import ConfirmDialog from '@/shared/components/ConfirmDialog.vue'

describe('ConfirmDialog', () => {
  it('no renderiza nada si abierto es false', () => {
    const wrapper = mount(ConfirmDialog, {
      props: {
        abierto: false,
        titulo: 'Eliminar elemento',
        mensaje: '¿Estás seguro?',
      },
    })

    expect(wrapper.find('.gb-confirm-dialog').exists()).toBe(false)
  })

  it('renderiza título, mensaje y emite confirmar', async () => {
    const wrapper = mount(ConfirmDialog, {
      props: {
        abierto: true,
        titulo: 'Eliminar elemento',
        mensaje: '¿Estás seguro?',
      },
      attachTo: document.body,
    })

    expect(document.body.querySelector('.gb-confirm-dialog__titulo').textContent).toBe(
      'Eliminar elemento',
    )
    expect(document.body.querySelector('.gb-confirm-dialog__mensaje').textContent).toBe(
      '¿Estás seguro?',
    )

    const botones = document.body.querySelectorAll('button')
    // El segundo botón es Confirmar
    botones[1].click()
    expect(wrapper.emitted('confirmar')).toHaveLength(1)
    wrapper.unmount()
  })

  it('emite cancelar al pulsar el botón de cancelar', async () => {
    const wrapper = mount(ConfirmDialog, {
      props: {
        abierto: true,
        titulo: 'Eliminar elemento',
        mensaje: '¿Estás seguro?',
      },
      attachTo: document.body,
    })

    const botones = document.body.querySelectorAll('button')
    botones[0].click()
    expect(wrapper.emitted('cancelar')).toHaveLength(1)
    wrapper.unmount()
  })
})
