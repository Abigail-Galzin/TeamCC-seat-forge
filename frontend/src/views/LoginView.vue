<script setup lang="ts">
import { ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage } from '../services/api'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const auth = useAuthStore()

const email = ref('')
const password = ref('')
const submitting = ref(false)

async function submit() {
  if (!email.value || !password.value) {
    toast.add({ severity: 'warn', summary: 'Missing details', detail: 'Please enter your email and password.', life: 3000 })
    return
  }

  submitting.value = true
  try {
    await auth.login(email.value, password.value)
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : '/'
    router.push(redirect)
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Sign in failed', detail: getErrorMessage(error, 'Invalid email or password'), life: 4000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <div class="card">
      <h1>Sign in</h1>
      <form @submit.prevent="submit">
        <label>
          <span>Email</span>
          <InputText v-model="email" type="email" required />
        </label>
        <label>
          <span>Password</span>
          <InputText v-model="password" type="password" required />
        </label>
        <Button type="submit" :label="submitting ? 'Signing in...' : 'Sign in'" severity="primary" :disabled="submitting" class="form-submit" />
      </form>
      <div class="auth-switch">
        <span>No account yet?</span>
        <Button label="Create an account" variant="text" severity="secondary" @click="router.push({ name: 'register' })" />
      </div>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 420px; margin: 0 auto; padding: 3rem 1.5rem; }
h1 { margin-top: 0; }
.card { display: grid; gap: 1.25rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.75rem; }
.my-app-dark .card { background: #0f172a; border-color: #1e293b; }
form { display: grid; gap: 1rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
.auth-switch { display: flex; align-items: center; justify-content: space-between; color: #64748b; font-size: 0.9rem; }
</style>