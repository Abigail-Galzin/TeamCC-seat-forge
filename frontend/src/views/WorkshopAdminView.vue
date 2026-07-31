<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
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

const first = computed(() => (workshops.value.pagination.page - 1) * perPage)

async function loadPage(pageNumber = 1) {
  loading.value = true
  loadError.value = null
  try {
    workshops.value = await getWorkshops(pageNumber, perPage, false)
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
        <p class="eyebrow">Admin</p>
        <h1>Manage workshops</h1>
      </div>
      <Button label="Add" severity="primary" @click="router.push({ name: 'admin-workshop-new' })" />
    </div>

    <Message v-if="loadError" severity="error" class="load-error">{{ loadError }}</Message>

    <div class="workshops-table-wrapper">
      <DataTable
        :value="workshops.data"
        :loading="loading"
        :paginator="true"
        :rows="perPage"
        :first="first"
        :totalRecords="workshops.pagination.count"
        :pageLinkSize="3"
        responsiveLayout="scroll"
        emptyMessage="No workshops found"
        @page="onPage"
      >
        <Column field="title" header="Title" sortable />
        <Column field="topic" header="Topic" sortable />
        <Column field="description" header="Description" />
        <Column header="Status">
          <template #body="{ data }">
            <Badge :value="data.active ? 'Active' : 'Inactive'" :severity="data.active ? 'success' : 'danger'" />
          </template>
        </Column>
        <Column header="Actions">
          <template #body="{ data }">
            <div class="row-actions">
              <Button
                icon="pi pi-pencil"
                severity="primary"
                variant="outlined"
                size="small"
                class="icon-button"
                aria-label="Edit"
                @click="router.push({ name: 'admin-workshop-edit', params: { workshopId: data.id } })"
              />
              <Button
                label="Sessions"
                severity="primary"
                size="small"
                @click="router.push({ name: 'admin-workshop-sessions', params: { workshopId: data.id } })"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>
  </div>
</template>

<style scoped>
.page { max-width: 1000px; margin: 0 auto; padding: 2rem 1.5rem; }
.page-header { display: flex; justify-content: space-between; align-items: center; gap: 1rem; margin-bottom: 1rem; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin-bottom: 0.25rem; }
.load-error { margin-bottom: 1rem; }
.workshops-table-wrapper { overflow-x: auto; }
.row-actions { display: inline-flex; gap: 0.4rem; align-items: center; flex-wrap: nowrap; }
.icon-button { flex-shrink: 0; }
</style>
