<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
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
  from: null as Date | null,
  to: null as Date | null,
  topic: null as string | null,
  availableOnly: false,
  sort: 'starts_at' as SessionSort,
})

async function loadPage(pageNumber = 1) {
  loading.value = true
  loadError.value = null
  try {
    sessions.value = await getSessions({
      from: filters.from ? filters.from.toISOString() : undefined,
      to: filters.to ? filters.to.toISOString() : undefined,
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
  filters.from = null
  filters.to = null
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
      <div class="filter-field">
        <span>From</span>
        <DatePicker v-model="filters.from" showTime hourFormat="24" showIcon placeholder="Any" />
      </div>

      <div class="filter-field">
        <span>To</span>
        <DatePicker v-model="filters.to" showTime hourFormat="24" showIcon placeholder="Any" />
      </div>

      <div class="filter-field">
        <span>Topic</span>
        <Select v-model="filters.topic" :options="topics" placeholder="All topics" showClear />
      </div>

      <div class="filter-field checkbox-field">
        <Checkbox v-model="filters.availableOnly" :binary="true" inputId="available-only" />
        <label for="available-only">Available seats only</label>
      </div>

      <div class="filter-field">
        <span>Sort by</span>
        <Select v-model="filters.sort" :options="sortOptions" optionLabel="label" optionValue="value" />
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

.load-error { margin-bottom: 1rem; }
.sessions-table-wrapper { overflow-x: auto; }
</style>
