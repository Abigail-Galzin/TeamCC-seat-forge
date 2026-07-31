<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { getSessionsForWorkshop } from '../services/sessions'
import { getWorkshopById } from '../services/workshops'
import { reserveSeatFromApi } from '../services/registrations'
import { getErrorMessage } from '../services/api'
import type { Session } from '../types/session'
import type { Workshop } from '../types/workshop'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const workshopId = Number(route.params.workshopId)
const workshop = ref<Workshop | undefined>()
const sessions = ref<Session[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)
const attendeeName = ref('')
const attendeeEmail = ref('')
const selectedSessionId = ref<number | null>(null)
const submitting = ref(false)

const sessionOptions = computed(() =>
  sessions.value
    .filter((session) => session.status === 'scheduled')
    .map((session) => ({
      label: `${new Date(session.startsAt).toLocaleString()} · Capacity ${session.capacity}`,
      value: session.id,
    })),
)

onMounted(async () => {
  try {
    workshop.value = await getWorkshopById(workshopId)
    const pageResult = await getSessionsForWorkshop(workshopId)
    sessions.value = pageResult.data
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    loading.value = false
  }
})

async function reserveSeat() {
  if (!attendeeName.value || !attendeeEmail.value) {
    toast.add({ severity: 'warn', summary: 'Missing details', detail: 'Please enter your name and email.', life: 3000 })
    return
  }

  if (!selectedSessionId.value) {
    toast.add({ severity: 'warn', summary: 'Missing session', detail: 'Please choose a session.', life: 3000 })
    return
  }

  submitting.value = true
  try {
    const registration = await reserveSeatFromApi(workshopId, {
      attendeeName: attendeeName.value,
      attendeeEmail: attendeeEmail.value,
      sessionId: selectedSessionId.value,
    })

    toast.add({
      severity: 'success',
      summary: 'Reservation confirmed',
      detail: `Reservation created with status: ${registration.status}`,
      life: 3000,
    })
    router.push({ name: 'attendee-catalog' })
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Reservation failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <div v-if="loading">Loading session details...</div>
    <Message v-else-if="loadError" severity="error">{{ loadError }}</Message>
    <div v-else>
      <h1>{{ workshop?.title }}</h1>
      <p>{{ workshop?.description }}</p>

      <form class="card" @submit.prevent="reserveSeat">
        <h2>Reserve a seat</h2>
        <label>
          <span>Name</span>
          <InputText v-model="attendeeName" required />
        </label>
        <label>
          <span>Email</span>
          <InputText v-model="attendeeEmail" type="email" required />
        </label>

        <label>
          <span>Session</span>
          <Select
            v-model="selectedSessionId"
            :options="sessionOptions"
            optionLabel="label"
            optionValue="value"
            placeholder="Select a session"
          />
        </label>

        <Button type="submit" :label="submitting ? 'Reserving...' : 'Reserve seat'" severity="primary" :disabled="submitting" class="form-submit" />
      </form>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 800px; margin: 0 auto; padding: 2rem 1.5rem; }
.actions-row { display: flex; justify-content: flex-end; margin-bottom: 1rem; }
.card { display: grid; gap: 1rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
</style>
