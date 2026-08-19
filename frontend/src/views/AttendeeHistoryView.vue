<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useToast } from 'primevue/usetoast'
import { getAttendeeRegistrationsFromApi } from '../services/attendees'
import { useAuthStore } from '../stores/auth'
import { getErrorMessage, DEFAULT_PAGE_SIZE } from '../services/api'
import { emptyPaginatedResult } from '../types/pagination'
import type { AttendeeRegistrationsResult } from '../types/attendee'

const toast = useToast()
const auth = useAuthStore()
const perPage = DEFAULT_PAGE_SIZE
const attendeeName = ref<string | null>(null)
const history = ref<AttendeeRegistrationsResult>({
  ...emptyPaginatedResult(perPage),
  statusCounts: { held: 0, confirmed: 0, waitlisted: 0, cancelled: 0, expired: 0 },
})
const loading = ref(false)

const attendeeId = auth.user?.attendeeId ?? null

onMounted(async () => {
  if (attendeeId == null) return
  await loadPage(1)
})

async function loadPage(pageNumber = 1) {
  if (attendeeId == null) {
    toast.add({ severity: 'warn', summary: 'No attendee profile', detail: 'This account has no linked attendee.', life: 3000 })
    return
  }

  loading.value = true
  try {
    const page = await getAttendeeRegistrationsFromApi(attendeeId, pageNumber, perPage)
    attendeeName.value = auth.user?.name ?? null
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
</script>

<template>
  <div class="page">
    <h1>My registrations</h1>
    <Message v-if="attendeeId == null" severity="warn">
      This account has no linked attendee profile, so it has no registrations to show.
    </Message>

    <div v-if="attendeeName" class="card list-card">
      <h2>Registrations for {{ attendeeName }}</h2>
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
</style>