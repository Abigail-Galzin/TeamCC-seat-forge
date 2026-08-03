<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { getSessionById } from '../services/sessions'
import { getWorkshopById } from '../services/workshops'
import { reserveSeatFromApi, confirmRegistrationFromApi } from '../services/registrations'
import { getErrorMessage } from '../services/api'
import ConfirmationDialog from '../components/ConfirmationDialog.vue'
import type { Session } from '../types/session'
import type { Workshop } from '../types/workshop'
import type { Registration } from '../types/registration'
import type { Attendee } from '../types/attendee'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const workshopId = Number(route.params.workshopId)
const workshop = ref<Workshop | undefined>()
const sessionId = Number(route.params.sessionId)
const session = ref<Session | undefined>()
const loading = ref(true)
const loadError = ref<string | null>(null)
const attendeeName = ref('')
const attendeeEmail = ref('')
const submitting = ref(false)
const confirming = ref(false)

// Modal state
const showConfirmationModal = ref(false)
const registrationData = ref<Registration | null>(null)
const attendeeData = ref<Attendee | null>(null)

onMounted(async () => {
  try {
    workshop.value = await getWorkshopById(workshopId)
    session.value = await getSessionById(sessionId)
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

  submitting.value = true
  try {
    const registration = await reserveSeatFromApi(workshopId, {
      attendeeName: attendeeName.value,
      attendeeEmail: attendeeEmail.value,
      sessionId: sessionId,
    })

    if (registration.status === 'held' && registration.attendee) {
      registrationData.value = registration
      attendeeData.value = registration.attendee
      showConfirmationModal.value = true
    } else {
      toast.add({
        severity: 'info',
        summary: 'Reservation confirmed',
        detail: `Reservation created with status: ${registration.status}`,
        life: 3000,
      })
      router.push({ name: 'workshop-sessions' })
    }
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Reservation failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    submitting.value = false
  }
}

async function handleConfirm() {
  if (!registrationData.value) return

  confirming.value = true
  try {
    await confirmRegistrationFromApi(
      workshopId,
      sessionId,
      registrationData.value.id
    )

    showConfirmationModal.value = false
    toast.add({
      severity: 'success',
      summary: 'Reservation confirmed',
      detail: `Seat confirmed for ${attendeeData.value?.name || 'attendee'}`,
      life: 3000,
    })
    registrationData.value = null
    attendeeData.value = null
    router.push({ name: 'workshop-sessions' })
  } catch (error) {
    toast.add({
      severity: 'error',
      summary: 'Confirmation failed',
      detail: getErrorMessage(error),
      life: 4000,
    })
  } finally {
    confirming.value = false
  }
}

function handleCancel() {
  showConfirmationModal.value = false
  toast.add({
    severity: 'info',
    summary: 'Reservation pending',
    detail: 'You can confirm your seat later from your profile',
    life: 3000,
  })
  registrationData.value = null
  attendeeData.value = null
}

function handleExpired() {
  showConfirmationModal.value = false
  toast.add({
    severity: 'warn',
    summary: 'Hold Expired',
    detail: 'Your seat hold has expired. Please try reserving again.',
    life: 5000,
  })
  registrationData.value = null
  attendeeData.value = null
}
</script>

<template>
  <div class="page">
    <div v-if="loading">Loading session details...</div>
    <Message v-else-if="loadError" severity="error">{{ loadError }}</Message>
    <div v-else>
      <div class="page-header">
        <div>
          <h1>{{ workshop?.title }}</h1>
          <div v-if="session">
            <p>Session Schedule: </p>
            <Tag :value="new Date(session.startsAt).toLocaleString()" severity="info" class="tag" /> -
            <Tag :value="new Date(session.endsAt).toLocaleString()" severity="info" class="tag" />
          </div>
        </div>
        <div class="header-actions">
          <Button
            label="Back"
            severity="primary"
            variant="outlined"
            @click="router.push({ name: 'workshop-sessions' })"
          />
        </div>
      </div>

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

        <Button type="submit" :label="submitting ? 'Reserving...' : 'Reserve seat'" severity="primary" :disabled="submitting" class="form-submit" />
      </form>
    </div>

    <!-- Confirmation Dialog Component -->
    <ConfirmationDialog
      v-model:visible="showConfirmationModal"
      :registration="registrationData"
      :attendee="attendeeData"
      :confirming="confirming"
      @confirm="handleConfirm"
      @cancel="handleCancel"
      @expired="handleExpired"
    />
  </div>
</template>

<style scoped>
.page { max-width: 800px; margin: 0 auto; padding: 2rem 1.5rem; }
.actions-row { display: flex; justify-content: flex-end; margin-bottom: 1rem; }
.card { display: grid; gap: 1rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
.session-data-card { padding: 2%; }
.page-header { display: flex; justify-content: space-between; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
</style>
