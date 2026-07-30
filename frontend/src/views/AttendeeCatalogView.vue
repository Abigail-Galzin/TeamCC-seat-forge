<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getWorkshops } from '../services/workshops'
import type { PaginatedResult } from '../types/pagination'
import type { Workshop } from '../types/workshop'

const router = useRouter()
const perPage = 5
const workshops = ref<PaginatedResult<Workshop>>({ items: [], total: 0, page: 1, perPage, totalPages: 1 })
const loading = ref(true)

async function loadPage(pageNumber = 1) {
  loading.value = true
  workshops.value = await getWorkshops(pageNumber, perPage, true)
  loading.value = false
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

    <DataView
      :value="workshops.items"
      :loading="loading"
      layout="grid"
      lazy
      paginator
      :rows="perPage"
      :first="(workshops.page - 1) * perPage"
      :totalRecords="workshops.total"
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
                @click="router.push(`/workshops/${workshop.id}/sessions`)"
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
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin-bottom: 0.25rem; }
.grid { display: grid; gap: 1rem; grid-template-columns: repeat(auto-fit, minmax(260px, 1fr)); }
.tag { margin-bottom: 0.5rem; }
.view-sessions-btn { width: 100%; margin-top: 0.75rem; justify-content: center; }
</style>
