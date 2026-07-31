<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { getWorkshopById } from '../services/workshops'
import { getSessionsForWorkshop, cancelSession } from '../services/sessions'
import { getErrorMessage } from '../services/api'
import type { Session } from '../types/session'
import type { Workshop } from '../types/workshop'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const workshopId = Number(route.params.workshopId)
const workshop = ref<Workshop | undefined>()
const sessions = ref<Session[]>([])
const loading = ref(true)
const loadError = ref<string | null>(null)

const cancelDialogVisible = ref(false)
const sessionToCancel = ref<Session | null>(null)
const cancellationReason = ref('')
const cancelling = ref(false)
const cancelDialogError = ref<string | null>(null)

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

function openCancelDialog(session: Session) {
  sessionToCancel.value = session
  cancellationReason.value = ''
  cancelDialogError.value = null
  cancelDialogVisible.value = true
}

function closeCancelDialog() {
  cancelDialogVisible.value = false
  sessionToCancel.value = null
}

async function confirmCancelSession() {
  if (!sessionToCancel.value) return

  cancelling.value = true
  cancelDialogError.value = null

  try {
    const result = await cancelSession(sessionToCancel.value.id, cancellationReason.value)
    const session = sessions.value.find((s) => s.id === result.sessionId)
    if (session) session.status = result.status

    const { held, confirmed, waitlisted } = result.cancelledRegistrations
    toast.add({
      severity: 'success',
      summary: 'Session cancelled',
      detail: `Cancelled ${held + confirmed + waitlisted} registration(s) (${held} held, ${confirmed} confirmed, ${waitlisted} waitlisted).`,
      life: 4000,
    })
    closeCancelDialog()
  } catch (error) {
    cancelDialogError.value = getErrorMessage(error)
  } finally {
    cancelling.value = false
  }
}
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
                @click="router.push({ name: 'admin-session-attendees', params: { workshopId, sessionId: data.id } })"
              />
              <Button
                v-if="data.status === 'scheduled'"
                label="Cancel"
                severity="danger"
                variant="outlined"
                size="small"
                @click="openCancelDialog(data)"
              />
            </div>
          </template>
        </Column>
      </DataTable>
    </div>

    <Dialog v-model:visible="cancelDialogVisible" modal header="Cancel session" :style="{ width: '28rem' }">
      <p class="cancel-dialog-intro">
        This cancels the session and every held, confirmed, or waitlisted registration for it.
        This cannot be undone.
      </p>
      <label for="cancellation-reason" class="cancel-dialog-label">Cancellation reason</label>
      <Textarea
        id="cancellation-reason"
        v-model="cancellationReason"
        rows="3"
        autoResize
        class="cancel-dialog-textarea"
        placeholder="Why is this session being cancelled?"
      />
      <Message v-if="cancelDialogError" severity="error" class="cancel-dialog-error">{{ cancelDialogError }}</Message>

      <template #footer>
        <Button label="Close" severity="secondary" variant="outlined" :disabled="cancelling" @click="closeCancelDialog" />
        <Button
          label="Confirm cancellation"
          severity="danger"
          :loading="cancelling"
          :disabled="!cancellationReason.trim()"
          @click="confirmCancelSession"
        />
      </template>
    </Dialog>
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
.cancel-dialog-intro { margin: 0 0 1rem; color: #64748b; }
.cancel-dialog-label { display: block; margin-bottom: 0.4rem; font-weight: 600; }
.cancel-dialog-textarea { width: 100%; }
.cancel-dialog-error { margin-top: 0.75rem; }
</style>
