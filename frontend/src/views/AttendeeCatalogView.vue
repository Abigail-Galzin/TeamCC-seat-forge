<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getWorkshops } from '../services/workshops'
import { getErrorMessage, DEFAULT_PAGE_SIZE } from '../services/api'
import type { PaginatedResult } from '../types/pagination'
import type { Workshop } from '../types/workshop'

const router = useRouter()
const perPage = DEFAULT_PAGE_SIZE
const workshops = ref<PaginatedResult<Workshop>>({
  message: null,
  data: [],
  status: 'ok',
  pagination: { page: 1, pages: 1, count: 0, limit: perPage, next: null, prev: null },
})
const loading = ref(true)
const loadError = ref<string | null>(null)

async function loadPage(pageNumber = 1) {
  loading.value = true
  loadError.value = null
  try {
    workshops.value = await getWorkshops(pageNumber, perPage, true)
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

onMounted(() => loadPage())
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Browse</p>
        <h1>Available workshops</h1>
      </div>
    </div>

    <Message v-if="loadError" severity="error" class="load-error">{{ loadError }}</Message>

    <DataView
      :value="workshops.data"
      :loading="loading"
      layout="grid"
      lazy
      paginator
      :rows="perPage"
      :first="(workshops.pagination.page - 1) * perPage"
      :totalRecords="workshops.pagination.count"
      @page="onPage"
    >
      <template #grid="{ items }">
        <div class="grid">
          <Card v-for="workshop in items" :key="workshop.id">
            <template #title>{{ workshop.title }}</template>
            <template #content>
              <Tag :value="workshop.topic" severity="info" class="tag" />
              <p>{{ workshop.description }}</p>
            </template>
            <template #footer>
              <Button
                label="View sessions & register"
                severity="primary"
                class="view-sessions-btn"
                @click="router.push({ name: 'attendee-workshop-sessions', params: { workshopId: workshop.id } })"
              />
            </template>
          </Card>
        </div>
      </template>
      <template #empty>No workshops available yet.</template>
    </DataView>
  </div>
</template>

<style scoped>
.page { max-width: 1000px; margin: 0 auto; padding: 2rem 1.5rem; }
.page-header { margin-bottom: 1rem; }
.load-error { margin-bottom: 1rem; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; font-size: 0.8rem; margin-bottom: 0.25rem; }
.grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
:deep(.p-dataview),
:deep(.p-dataview-content) {
  background: transparent;
  border: none;
}
:deep(.p-paginator) {
  margin-top: 15px;
}
.tag { margin-bottom: 0.5rem; }
.view-sessions-btn { width: 100%; margin-top: 0.75rem; justify-content: center; }
</style>
