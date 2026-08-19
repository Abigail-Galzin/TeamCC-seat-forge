import { createApp } from 'vue'
import { createPinia } from 'pinia'
import PrimeVue from 'primevue/config'
import ToastService from 'primevue/toastservice'
import ConfirmationService from 'primevue/confirmationservice'
import Aura from '@primeuix/themes/aura'
import 'primeicons/primeicons.css'

import App from './App.vue'
import router from './router'
import { setUnauthorizedHandler } from './services/api'
import { useAuthStore } from './stores/auth'

const pinia = createPinia()
const app = createApp(App)

app.use(pinia)
app.use(router)
app.use(PrimeVue, {
  theme: {
    preset: Aura,
    options: {
      darkModeSelector: '.my-app-dark',
    },
  },
})
app.use(ToastService)
app.use(ConfirmationService)

// Global 401 handling: draft a stored token, return to the login screen.
setUnauthorizedHandler(() => {
  const auth = useAuthStore()
  auth.clearSession()
  if (router.currentRoute.value.name !== 'login' && router.currentRoute.value.name !== 'register') {
    router.push({ name: 'login' })
  }
})

// Validate any persisted token against the backend before the first navigation.
const auth = useAuthStore()
await auth.restore()

app.mount('#app')