<script setup lang="ts">
import { reactive, ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { createSession } from '../services/sessions'
import { getWorkshopById } from '../services/workshops'
import { getErrorMessage } from '../services/api'
import type { Workshop } from '../types/workshop'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const workshopId = Number(route.params.workshopId)
const workshop = ref<Workshop | undefined>()
const submitting = ref(false)
const form = reactive({
  startsAt: null as Date | null,
  endsAt: null as Date | null,
  capacity: 10,
  status: 'scheduled' as 'scheduled' | 'cancelled' | 'completed',
})

const statusOptions = [
  { label: 'Scheduled', value: 'scheduled' },
  { label: 'Cancelled', value: 'cancelled' },
  { label: 'Completed', value: 'completed' },
]

onMounted(async () => {
  try {
    workshop.value = await getWorkshopById(workshopId)
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Load failed', detail: getErrorMessage(error), life: 4000 })
  }
})

async function submit() {
  if (!form.startsAt || !form.endsAt) {
    toast.add({ severity: 'warn', summary: 'Missing dates', detail: 'Please choose a start and end date.', life: 3000 })
    return
  }

  submitting.value = true
  try {
    await createSession({
      workshopId,
      startsAt: form.startsAt.toISOString(),
      endsAt: form.endsAt.toISOString(),
      capacity: form.capacity,
      status: form.status,
    })
    toast.add({ severity: 'success', summary: 'Session created', detail: 'The session was created successfully.', life: 3000 })
    router.push({ name: 'admin-workshop-sessions', params: { workshopId } })
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Creation failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Create</p>
        <h1>New session for {{ workshop?.title || 'workshop' }}</h1>
      </div>
      <Button
        label="Back"
        severity="primary"
        variant="outlined"
        type="button"
        @click="router.push({ name: 'admin-workshop-sessions', params: { workshopId } })"
      />
    </div>

    <form class="card" @submit.prevent="submit">
      <label>
        <span>Start</span>
        <DatePicker v-model="form.startsAt" showTime hourFormat="24" showIcon required />
      </label>

      <label>
        <span>End</span>
        <DatePicker v-model="form.endsAt" showTime hourFormat="24" showIcon required />
      </label>

      <label>
        <span>Capacity</span>
        <InputNumber v-model="form.capacity" :min="1" required />
      </label>

      <label>
        <span>Status</span>
        <Select v-model="form.status" :options="statusOptions" optionLabel="label" optionValue="value" />
      </label>

      <Button
        type="submit"
        :label="submitting ? 'Creating...' : 'Save'"
        severity="primary"
        :disabled="submitting"
        class="form-submit"
      />
    </form>
  </div>
</template>

<style scoped>
.page { max-width: 700px; margin: 0 auto; padding: 2rem 1.5rem; }
.page-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; gap: 1rem; }
.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin: 0 0 0.25rem; }
h1 { margin: 0; }
.card { display: grid; gap: 1rem; background: white; border: 1px solid #e2e8f0; border-radius: 16px; padding: 1.25rem; }
label { display: grid; gap: 0.4rem; }
.form-submit { justify-self: end; }
</style>
