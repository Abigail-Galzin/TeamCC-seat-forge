<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getSessionById, getSessionAttendeesFromApi } from '../services/sessions'
import { getWorkshopById } from '../services/workshops'
import { getAttendeeRegistrationsFromApi } from '../services/attendees'
import { getErrorMessage, DEFAULT_PAGE_SIZE } from '../services/api'
import type { Session, SessionAttendee } from '../types/session'
import type { Workshop } from '../types/workshop'
import { emptyPaginatedResult } from '../types/pagination'
import type { AttendeeRegistrationsResult } from '../types/attendee'

const route = useRoute()
const router = useRouter()
const workshopId = Number(route.params.workshopId)
const sessionId = Number(route.params.sessionId)
const session = ref<Session | undefined>()
const workshop = ref<Workshop | undefined>()
const perPage = DEFAULT_PAGE_SIZE
const attendeesPage = ref(emptyPaginatedResult<SessionAttendee>(perPage))
const loading = ref(true)
const attendeesLoading = ref(false)
const loadError = ref<string | null>(null)

const attendeeSessionsPerPage = DEFAULT_PAGE_SIZE
const selectedAttendee = ref<{ id: number; name: string; email: string } | null>(null)
const attendeeSessionsLoading = ref(false)
const attendeeSessionsPage = ref<AttendeeRegistrationsResult>({
  ...emptyPaginatedResult(attendeeSessionsPerPage),
  statusCounts: { held: 0, confirmed: 0, waitlisted: 0, cancelled: 0, expired: 0 },
})

async function loadAttendeesPage(pageNumber = 1) {
  attendeesLoading.value = true
  try {
    attendeesPage.value = await getSessionAttendeesFromApi(workshopId, sessionId, pageNumber, perPage)
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    attendeesLoading.value = false
  }
}

function onAttendeesPage(event: { first: number; rows: number }) {
  const nextPage = Math.floor(event.first / event.rows) + 1
  loadAttendeesPage(nextPage)
}

async function loadAttendeeSessionsPage(pageNumber = 1) {
  if (!selectedAttendee.value) return

  attendeeSessionsLoading.value = true
  try {
    attendeeSessionsPage.value = await getAttendeeRegistrationsFromApi(
      selectedAttendee.value.id,
      pageNumber,
      attendeeSessionsPerPage,
    )
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    attendeeSessionsLoading.value = false
  }
}

function onAttendeeSessionsPage(event: { first: number; rows: number }) {
  const nextPage = Math.floor(event.first / event.rows) + 1
  loadAttendeeSessionsPage(nextPage)
}

function viewAttendeeSessions(attendee: SessionAttendee) {
  selectedAttendee.value = { id: attendee.attendeeId, name: attendee.name, email: attendee.email }
  loadAttendeeSessionsPage()
}

function closeAttendeeSessions() {
  selectedAttendee.value = null
}

onMounted(async () => {
  try {
    workshop.value = await getWorkshopById(workshopId)
    session.value = await getSessionById(sessionId)
    await loadAttendeesPage()
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div class="page">
    <div v-if="loading">Loading attendees...</div>
    <Message v-else-if="loadError" severity="error">{{ loadError }}</Message>
    <div v-else>
      <div class="actions-row">
        <Button
          label="Back"
          severity="primary"
          variant="outlined"
          class="action-button"
          @click="router.push({ name: 'admin-workshop-sessions', params: { workshopId } })"
        />
      </div>
      <h1>Attendees for {{ workshop?.title }}</h1>
      <h2 v-if="session">Session {{ new Date(session.startsAt).toLocaleString() }}</h2>

      <div class="layout" :class="{ 'with-panel': selectedAttendee }">
        <Card class="list-card">
          <template #title>Attendee list</template>
          <template #content>
            <DataTable
              :value="attendeesPage.data"
              :loading="attendeesLoading"
              lazy
              paginator
              :rows="perPage"
              :first="(attendeesPage.pagination.page - 1) * perPage"
              :totalRecords="attendeesPage.pagination.count"
              responsiveLayout="scroll"
              emptyMessage="No attendees yet."
              @page="onAttendeesPage"
            >
              <Column field="name" header="Name" />
              <Column field="email" header="Email" />
              <Column header="Status">
                <template #body="{ data }">
                  <Badge :value="data.status" />
                </template>
              </Column>
              <Column header="Actions">
                <template #body="{ data }">
                  <Button label="View sessions" severity="primary" size="small" @click="viewAttendeeSessions(data)" />
                </template>
              </Column>
            </DataTable>
          </template>
        </Card>

        <Card v-if="selectedAttendee" class="sessions-card">
          <template #title>
            <div class="sessions-card-header">
              <span>Sessions for {{ selectedAttendee.name }}</span>
              <Button icon="pi pi-times" severity="secondary" variant="text" size="small" @click="closeAttendeeSessions" />
            </div>
          </template>
          <template #content>
            <p class="attendee-email">{{ selectedAttendee.email }}</p>

            <DataTable
              :value="attendeeSessionsPage.data"
              :loading="attendeeSessionsLoading"
              lazy
              paginator
              :rows="attendeeSessionsPerPage"
              :first="(attendeeSessionsPage.pagination.page - 1) * attendeeSessionsPerPage"
              :totalRecords="attendeeSessionsPage.pagination.count"
              responsiveLayout="scroll"
              emptyMessage="No registered sessions yet."
              @page="onAttendeeSessionsPage"
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
            </DataTable>
          </template>
        </Card>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 1400px; margin: 0 auto; padding: 2rem 1.5rem; }
.actions-row { display: flex; justify-content: flex-end; margin-bottom: 1rem; }
.action-button { min-width: 168px; display: inline-flex; align-items: center; justify-content: center; }
.layout { display: grid; grid-template-columns: 1fr; gap: 1.5rem; margin-top: 1rem; }
.list-card, .sessions-card { margin-top: 0; overflow-x: auto; }
.sessions-card-header { display: flex; align-items: center; justify-content: space-between; gap: 0.5rem; }
.attendee-email { margin: -0.5rem 0 1rem; color: #64748b; }

@media (min-width: 900px) {
  .layout.with-panel { grid-template-columns: minmax(0, 1fr) 420px; align-items: start; }
}
</style>
