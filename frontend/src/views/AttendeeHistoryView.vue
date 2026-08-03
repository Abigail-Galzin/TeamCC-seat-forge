<script setup lang="ts">
import { ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { getRegistrationHistoryByEmail, confirmRegistrationFromApi, cancelRegistrationFromApi } from '../services/registrations'
import { getErrorMessage, DEFAULT_PAGE_SIZE } from '../services/api'
import { emptyPaginatedResult } from '../types/pagination'
import type { Attendee, AttendeeRegistration, AttendeeRegistrationsResult } from '../types/attendee'

const toast = useToast()
const email = ref('')
const perPage = DEFAULT_PAGE_SIZE
const attendee = ref<Attendee | null>(null)
const history = ref<AttendeeRegistrationsResult>({
  ...emptyPaginatedResult(perPage),
  statusCounts: { held: 0, confirmed: 0, waitlisted: 0, cancelled: 0, expired: 0 },
})
const loading = ref(false)
const actioningId = ref<number | null>(null)

function isHoldExpired(holdExpiresAt?: string) {
  return !!holdExpiresAt && new Date(holdExpiresAt) <= new Date()
}

function canConfirm(registration: AttendeeRegistration) {
  return registration.status === 'held' && !isHoldExpired(registration.holdExpiresAt)
}

function canCancel(registration: AttendeeRegistration) {
  return registration.status === 'held' || registration.status === 'confirmed' || registration.status === 'waitlisted'
}

async function loadPage(pageNumber = 1) {
  if (!email.value) {
    toast.add({ severity: 'warn', summary: 'Missing email', detail: 'Please enter an email address.', life: 3000 })
    return
  }

  loading.value = true
  try {
    const result = await getRegistrationHistoryByEmail(email.value, pageNumber, perPage)
    if (!result) {
      attendee.value = null
      toast.add({ severity: 'error', summary: 'Not found', detail: 'No attendee found with that email.', life: 4000 })
      return
    }

    const { attendee: found, ...page } = result
    attendee.value = found
    history.value = page
    if (pageNumber === 1) {
      toast.add({
        severity: 'success',
        summary: 'Registrations loaded',
        detail: `Found ${page.pagination.count} registration(s).`,
        life: 3000,
      })
    }
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Load failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    loading.value = false
  }
}

function onPage(event: { first: number; rows: number }) {
  const nextPage = Math.floor(event.first / event.rows) + 1
  loadPage(nextPage)
}

async function handleConfirm(registration: AttendeeRegistration) {
  const workshopId = registration.session?.workshop?.id
  const sessionId = registration.session?.id
  if (!workshopId || !sessionId) return

  actioningId.value = registration.id
  try {
    await confirmRegistrationFromApi(workshopId, sessionId, registration.id)
    toast.add({ severity: 'success', summary: 'Registration confirmed', detail: `Registration #${registration.id} confirmed.`, life: 3000 })
    await loadPage(history.value.pagination.page)
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Confirmation failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    actioningId.value = null
  }
}

async function handleCancel(registration: AttendeeRegistration) {
  const workshopId = registration.session?.workshop?.id
  const sessionId = registration.session?.id
  if (!workshopId || !sessionId) return

  actioningId.value = registration.id
  try {
    await cancelRegistrationFromApi(workshopId, sessionId, registration.id)
    toast.add({ severity: 'success', summary: 'Registration cancelled', detail: `Registration #${registration.id} cancelled.`, life: 3000 })
    await loadPage(history.value.pagination.page)
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Cancellation failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    actioningId.value = null
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
      <Button label="Load registrations" severity="primary" class="form-submit" @click="loadPage(1)" />
    </div>

    <div v-if="attendee" class="card list-card">
      <h2>Registrations for {{ attendee.name }}</h2>
      <DataTable
        :value="history.data"
        :loading="loading"
        lazy
        paginator
        :rows="perPage"
        :first="(history.pagination.page - 1) * perPage"
        :totalRecords="history.pagination.count"
        responsiveLayout="scroll"
        emptyMessage="No registrations yet."
        @page="onPage"
      >
        <Column header="Workshop">
          <template #body="{ data }">{{ data.session?.workshop?.title ?? 'Unknown workshop' }}</template>
        </Column>
        <Column header="Session">
          <template #body="{ data }">
            {{ data.session ? new Date(data.session.startsAt).toLocaleString() : 'Unknown session' }}
          </template>
        </Column>
        <Column header="Status">
          <template #body="{ data }">
            <Badge :value="data.status" />
          </template>
        </Column>
        <Column header="Actions">
          <template #body="{ data }">
            <div class="row-actions">
              <Button
                v-if="canConfirm(data)"
                label="Confirm"
                severity="success"
                size="small"
                :loading="actioningId === data.id"
                :disabled="actioningId !== null"
                @click="handleConfirm(data)"
              />
              <Button
                v-if="canCancel(data)"
                label="Cancel"
                severity="danger"
                size="small"
                variant="outlined"
                :loading="actioningId === data.id"
                :disabled="actioningId !== null"
                @click="handleCancel(data)"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 900px; margin: 0 auto; padding: 2rem 1.5rem; }
.card { display: grid; gap: 1rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; margin-bottom: 1rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
.list-card { overflow-x: auto; }
.row-actions { display: flex; gap: 0.5rem; }
</style>
