import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import { createPinia } from 'pinia'
import ToastService from 'primevue/toastservice'
import App from '../App.vue'

describe('App', () => {
  it('renders properly', () => {
    const wrapper = mount(App, {
      global: {
        plugins: [createPinia(), ToastService],
        stubs: {
          Toast: true,
          ConfirmDialog: true,
          Menubar: true,
          RouterView: true,
          Button: true,
          Tag: true,
        },
      },
    })
    expect(wrapper.text()).toContain('SeatForge')
  })
})