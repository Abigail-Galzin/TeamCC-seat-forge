import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import App from '../App.vue'

describe('App', () => {
  it('renders properly', () => {
    const wrapper = mount(App, {
      global: {
        stubs: {
          Toast: true,
          ConfirmDialog: true,
          Menubar: true,
          RouterView: true,
          Button: true,
        },
      },
    })
    expect(wrapper.text()).toContain('SeatForge')
  })
})
