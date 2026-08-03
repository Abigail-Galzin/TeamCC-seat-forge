<script setup lang="ts">
import { onMounted, reactive, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getSessions } from '../services/sessions'
import { getWorkshopTopics } from '../services/workshops'
import { getErrorMessage, DEFAULT_PAGE_SIZE } from '../services/api'
import type { PaginatedResult } from '../types/pagination'
import type { SessionListItem, SessionSort } from '../types/session'

const router = useRouter()
const perPage = DEFAULT_PAGE_SIZE

const sessions = ref<PaginatedResult<SessionListItem>>({
  message: null,
  data: [],
  status: 'ok',
  pagination: { page: 1, pages: 1, count: 0, limit: perPage, next: null, prev: null },
})
const loading = ref(true)
const loadError = ref<string | null>(null)
const topics = ref<string[]>([])

const sortOptions: Array<{ label: string; value: SessionSort }> = [
  { label: 'Start time', value: 'starts_at' },
  { label: 'Available seats', value: 'available_seats' },
]

const filters = reactive({
  fromDate: null as Date | null,
  fromTime: '' as string, // "HH:mm" format
  toDate: null as Date | null,
  toTime: '' as string,   // "HH:mm" format
  topic: null as string | null,
  availableOnly: false,
  sort: 'starts_at' as SessionSort,
})

// Safely merge Date + Time string into a single Date object
function combineDateTime(date: Date | null, timeStr: string): Date | null {
  if (!date) return null
  const result = new Date(date)
  if (timeStr) {
    const [hours, minutes] = timeStr.split(':').map(Number)
    if (!isNaN(hours) && !isNaN(minutes)) {
      result.setHours(hours, minutes, 0, 0)
    }
  }
  return result
}

// Helpers to extract "HH:mm" string from a Date object
function getTimeString(date: Date | null): string {
  if (!date) return ''
  const h = String(date.getHours()).padStart(2, '0')
  const m = String(date.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

// Event handler for DatePicker date selection
function onFromDateSelect(val: Date | null) {
  filters.fromDate = val
  if (val && !filters.fromTime) {
    filters.fromTime = getTimeString(val)
  }
}

function onToDateSelect(val: Date | null) {
  filters.toDate = val
  if (val && !filters.toTime) {
    filters.toTime = getTimeString(val)
  }
}

async function loadPage(pageNumber = 1) {
  loading.value = true
  loadError.value = null

  const fromDateTime = combineDateTime(filters.fromDate, filters.fromTime)
  const toDateTime = combineDateTime(filters.toDate, filters.toTime)

  try {
    sessions.value = await getSessions({
      from: fromDateTime ? fromDateTime.toISOString() : undefined,
      to: toDateTime ? toDateTime.toISOString() : undefined,
      topic: filters.topic ?? undefined,
      available: filters.availableOnly || undefined,
      sort: filters.sort,
      page: pageNumber,
      perPage,
    })
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    loading.value = false
  }
}

function onPage(event: { first: number; rows: number }) {
  const nextPage = Math.floor(event.first / event.rows) + 1
  loadPage(nextPage)
}

function applyFilters() {
  loadPage(1)
}

function clearFilters() {
  filters.fromDate = null
  filters.fromTime = ''
  filters.toDate = null
  filters.toTime = ''
  filters.topic = null
  filters.availableOnly = false
  filters.sort = 'starts_at'
  loadPage(1)
}

onMounted(async () => {
  try {
    topics.value = await getWorkshopTopics()
  } catch {
    topics.value = []
  }
  await loadPage()
})
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Browse</p>
        <h1>Sessions</h1>
      </div>
    </div>

    <div class="filters-card">
      <!-- From Filter -->
      <div class="filter-field">
        <span>From</span>
        <div class="datetime-group">
          <DatePicker
            :model-value="filters.fromDate"
            @update:model-value="onFromDateSelect"
            showIcon
            placeholder="Date"
            dateFormat="yy-mm-dd"
          />
          <InputText
            v-model="filters.fromTime"
            type="time"
            class="time-picker"
            placeholder="00:00"
          />
        </div>
      </div>

      <!-- To Filter -->
      <div class="filter-field">
        <span>To</span>
        <div class="datetime-group">
          <DatePicker
            :model-value="filters.toDate"
            @update:model-value="onToDateSelect"
            showIcon
            placeholder="Date"
            dateFormat="yy-mm-dd"
          />
          <InputText
            v-model="filters.toTime"
            type="time"
            class="time-picker"
            placeholder="00:00"
          />
        </div>
      </div>

      <div class="filter-field">
        <span>Topic</span>
        <Select v-model="filters.topic" :options="topics" placeholder="All topics" showClear />
      </div>

      <div class="filter-field">
        <span>Sort by</span>
        <Select v-model="filters.sort" :options="sortOptions" optionLabel="label" optionValue="value" />
      </div>

      <div class="filter-field checkbox-field">
        <Checkbox v-model="filters.availableOnly" :binary="true" inputId="available-only" />
        <label for="available-only">Available seats only</label>
      </div>

      <div class="filter-actions">
        <Button label="Apply filters" severity="primary" @click="applyFilters" />
        <Button label="Clear" severity="secondary" variant="outlined" @click="clearFilters" />
      </div>
    </div>

    <Message v-if="loadError" severity="error" class="load-error">{{ loadError }}</Message>

    <div class="sessions-table-wrapper">
      <DataTable
        :value="sessions.data"
        :loading="loading"
        lazy
        paginator
        :rows="perPage"
        :first="(sessions.pagination.page - 1) * perPage"
        :totalRecords="sessions.pagination.count"
        responsiveLayout="scroll"
        emptyMessage="No sessions match these filters."
        @page="onPage"
      >
        <Column header="Workshop">
          <template #body="{ data }">{{ data.workshopTitle }}</template>
        </Column>
        <Column field="topic" header="Topic" />
        <Column header="Starts at">
          <template #body="{ data }">{{ new Date(data.startsAt).toLocaleString() }}</template>
        </Column>
        <Column header="Status">
          <template #body="{ data }">
            <Badge :value="data.status" :severity="data.status === 'scheduled' ? 'success' : 'secondary'" />
            <p v-if="data.status === 'cancelled' && data.cancellationReason" class="cancellation-reason">
              {{'Reason: '+ data.cancellationReason }}
            </p>
          </template>
        </Column>
        <Column header="Available seats">
          <template #body="{ data }">
            <Tag
              :value="`${data.availableSeats} / ${data.capacity}`"
              :severity="data.availableSeats > 0 ? 'success' : 'warn'"
            />
          </template>
        </Column>
        <Column header="Waitlist">
          <template #body="{ data }">{{ data.waitlistCount }}</template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 1000px; margin: 0 auto; padding: 2rem 1.5rem; }
.page-header { margin-bottom: 1rem; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin-bottom: 0.25rem; }

.filters-card {
  display: flex;
  flex-wrap: wrap;
  gap: 1rem;
  align-items: end;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1.25rem;
  margin-bottom: 1rem;
}
.filter-field { display: grid; gap: 0.4rem; }
.filter-field.checkbox-field { flex-direction: row; display: flex; align-items: center; gap: 0.5rem; }
.filter-actions { display: flex; gap: 0.5rem; margin-left: auto; }

.datetime-group {
  display: flex;
  gap: 0.35rem;
  align-items: center;
}
.load-error { margin-bottom: 1rem; }
.sessions-table-wrapper { overflow-x: auto; }
.cancellation-reason { margin: 0.35rem 0 0; color: #64748b; font-size: 0.85rem; max-width: 16rem; }
</style>
