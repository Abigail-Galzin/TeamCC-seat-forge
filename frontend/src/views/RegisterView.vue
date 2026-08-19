<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage } from '../services/api'

const router = useRouter()
const toast = useToast()
const auth = useAuthStore()

const name = ref('')
const email = ref('')
const password = ref('')
const passwordConfirmation = ref('')
const submitting = ref(false)

async function submit() {
  if (!name.value || !email.value || !password.value) {
    toast.add({ severity: 'warn', summary: 'Missing details', detail: 'Please fill in every field.', life: 3000 })
    return
  }
  if (password.value !== passwordConfirmation.value) {
    toast.add({ severity: 'warn', summary: 'Passwords do not match', detail: 'Please re-enter your password.', life: 3000 })
    return
  }
  if (password.value.length < 8) {
    toast.add({ severity: 'warn', summary: 'Password too short', detail: 'Use at least 8 characters.', life: 3000 })
    return
  }

  submitting.value = true
  try {
    await auth.register(name.value, email.value, password.value)
    toast.add({ severity: 'success', summary: 'Account created', detail: 'Welcome to SeatForge!', life: 3000 })
    router.push({ name: 'dashboard' })
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Registration failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <div class="card">
      <h1>Create an account</h1>
      <form @submit.prevent="submit">
        <label>
          <span>Name</span>
          <InputText v-model="name" required />
        </label>
        <label>
          <span>Email</span>
          <InputText v-model="email" type="email" required />
        </label>
        <label>
          <span>Password</span>
          <InputText v-model="password" type="password" required />
        </label>
        <label>
          <span>Confirm password</span>
          <InputText v-model="passwordConfirmation" type="password" required />
        </label>
        <Button type="submit" :label="submitting ? 'Creating account...' : 'Create account'" severity="primary" :disabled="submitting" class="form-submit" />
      </form>
      <div class="auth-switch">
        <span>Already have an account?</span>
        <Button label="Sign in" variant="text" severity="secondary" @click="router.push({ name: 'login' })" />
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