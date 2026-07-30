<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { getSessionById, getSessionAttendeeStatuses } from '../services/sessions'
import { getWorkshopById } from '../services/workshops'
import { getErrorMessage } from '../services/api'
import type { Session } from '../types/session'
import type { Workshop } from '../types/workshop'

const route = useRoute()
const router = useRouter()
const sessionId = Number(route.params.sessionId)
const session = ref<Session | undefined>()
const workshop = ref<Workshop | undefined>()
const attendees = ref<Array<{ name: string; email: string; status: string }>>([])
const loading = ref(true)
const loadError = ref<string | null>(null)

onMounted(async () => {
  try {
    session.value = await getSessionById(sessionId)
    if (session.value) {
      workshop.value = await getWorkshopById(session.value.workshopId)
      attendees.value = await getSessionAttendeeStatuses(sessionId)
    }
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
    <div v-else-if="!session">Session not found.</div>
    <div v-else>
      <div class="actions-row">
        <Button
          label="Back"
          severity="primary"
          variant="outlined"
          class="action-button"
          @click="router.push({ name: 'admin-workshop-sessions', params: { workshopId: workshop?.id } })"
        />
      </div>
      <h1>Attendees for {{ workshop?.title }}</h1>
      <h2>Session {{ new Date(session?.startsAt || '').toLocaleString() }}</h2>

      <Card class="list-card">
        <template #title>Attendee list</template>
        <template #content>
          <DataTable :value="attendees" responsiveLayout="scroll" emptyMessage="No attendees yet.">
            <Column field="name" header="Name" />
            <Column field="email" header="Email" />
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
</template>

<style scoped>
.page { max-width: 1000px; margin: 0 auto; padding: 2rem 1.5rem; }
.actions-row { display: flex; justify-content: flex-end; margin-bottom: 1rem; }
.action-button { min-width: 168px; display: inline-flex; align-items: center; justify-content: center; }
.list-card { margin-top: 1rem; }
</style>
