<script setup lang="ts">
import { ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { getRegistrationHistoryByEmail, type Registration } from '../services/workshops'

const toast = useToast()
const email = ref('')
const history = ref<{ attendee: { name: string; email: string }; registrations: Registration[] } | null>(null)

async function loadHistory() {
  history.value = null

  if (!email.value) {
    toast.add({ severity: 'warn', summary: 'Missing email', detail: 'Please enter an email address.', life: 3000 })
    return
  }

  try {
    const result = await getRegistrationHistoryByEmail(email.value)
    if (!result) {
      toast.add({ severity: 'error', summary: 'Not found', detail: 'No attendee found with that email.', life: 4000 })
      return
    }

    history.value = result
    toast.add({ severity: 'success', summary: 'Registrations loaded', detail: `Found ${result.registrations.length} registration(s).`, life: 3000 })
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error'
    toast.add({ severity: 'error', summary: 'Load failed', detail: message, life: 4000 })
  }
}
</script>

<template>
  <div class="page">
    <h1>My registrations</h1>
    <div class="card">
      <label>
        <span>Attendee email</span>
        <InputText v-model="email" type="email" required />
      </label>
      <Button label="Load registrations" severity="primary" class="form-submit" @click="loadHistory" />
    </div>

    <div v-if="history" class="card list-card">
      <h2>Registrations for {{ history.attendee.name }}</h2>
      <ul>
        <li v-for="registration in history.registrations" :key="registration.id">
          Session {{ registration.sessionId }} — {{ registration.status }}
        </li>
      </ul>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 800px; margin: 0 auto; padding: 2rem 1.5rem; }
.card { display: grid; gap: 1rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; margin-bottom: 1rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
.list-card ul { padding-left: 1rem; margin: 0.5rem 0 0; }
</style>
