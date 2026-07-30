<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { getWorkshopById } from '../services/workshops'
import { getSessionsForWorkshop } from '../services/sessions'
import { getErrorMessage } from '../services/api'
import type { Session } from '../types/session'
import type { Workshop } from '../types/workshop'

const route = useRoute()
const router = useRouter()
const workshopId = Number(route.params.workshopId)
const workshop = ref<Workshop | undefined>()
const sessions = ref<Session[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)

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
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Admin</p>
        <h1>Sessions for {{ workshop?.title }}</h1>
      </div>
      <div class="header-actions">
        <Button
          label="Back"
          severity="primary"
          variant="outlined"
          @click="router.push({ name: 'admin-workshops' })"
        />
        <Button
          label="Add"
          severity="primary"
          @click="router.push({ name: 'admin-workshop-sessions-new', params: { workshopId } })"
        />
      </div>
    </div>

    <Message v-if="loadError" severity="error" class="load-error">{{ loadError }}</Message>

    <div class="sessions-table-wrapper">
      <DataTable
        :value="sessions"
        :loading="loading"
        responsiveLayout="scroll"
        emptyMessage="No sessions created for this workshop."
      >
        <Column header="Starts at">
          <template #body="{ data }">{{ new Date(data.startsAt).toLocaleString() }}</template>
        </Column>
        <Column field="capacity" header="Capacity" sortable />
        <Column header="Status">
          <template #body="{ data }">
            <Badge :value="data.status" :severity="data.status === 'scheduled' ? 'success' : 'secondary'" />
          </template>
        </Column>
        <Column header="Actions">
          <template #body="{ data }">
            <div class="row-actions">
              <Button
                label="View attendees"
                severity="primary"
                size="small"
                @click="router.push({ name: 'admin-session-attendees', params: { sessionId: data.id } })"
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
.page-header { display: flex; justify-content: space-between; align-items: center; gap: 1rem; margin-bottom: 1.5rem; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin-bottom: 0.25rem; }
.header-actions { display: flex; gap: 0.75rem; align-items: center; }
.load-error { margin-bottom: 1rem; }
.sessions-table-wrapper { overflow-x: auto; }
.row-actions { display: inline-flex; gap: 0.4rem; align-items: center; flex-wrap: nowrap; }
</style>
