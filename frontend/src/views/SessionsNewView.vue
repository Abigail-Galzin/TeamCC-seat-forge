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
  startDate: null as Date | null,
  startTime: '' as string, // "HH:mm"
  endDate: null as Date | null,
  endTime: '' as string,   // "HH:mm"
  capacity: 10,
  status: 'scheduled' as 'scheduled' | 'cancelled' | 'completed',
})

const statusOptions = [
  { label: 'Scheduled', value: 'scheduled' },
  { label: 'Cancelled', value: 'cancelled' },
  { label: 'Completed', value: 'completed' },
]

// Safely combine Date object + HH:mm string into a single Date instance
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

// Extract "HH:mm" string from a Date object
function getTimeString(date: Date | null): string {
  if (!date) return ''
  const h = String(date.getHours()).padStart(2, '0')
  const m = String(date.getMinutes()).padStart(2, '0')
  return `${h}:${m}`
}

function onStartDateSelect(val: Date | null) {
  form.startDate = val
  if (val && !form.startTime) {
    form.startTime = getTimeString(val)
  }
}

function onEndDateSelect(val: Date | null) {
  form.endDate = val
  if (val && !form.endTime) {
    form.endTime = getTimeString(val)
  }
}

onMounted(async () => {
  try {
    workshop.value = await getWorkshopById(workshopId)
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Load failed', detail: getErrorMessage(error), life: 4000 })
  }
})

async function submit() {
  const startsAt = combineDateTime(form.startDate, form.startTime)
  const endsAt = combineDateTime(form.endDate, form.endTime)

  if (!startsAt || !endsAt) {
    toast.add({ severity: 'warn', summary: 'Missing dates', detail: 'Please choose both start and end date/time.', life: 3000 })
    return
  }

  submitting.value = true
  try {
    await createSession({
      workshopId,
      startsAt: startsAt.toISOString(),
      endsAt: endsAt.toISOString(),
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
        <div class="datetime-group">
          <DatePicker
            :model-value="form.startDate"
            @update:model-value="onStartDateSelect"
            showIcon
            dateFormat="yy-mm-dd"
            placeholder="Select date"
            required
          />
          <InputText
            v-model="form.startTime"
            type="time"
            class="time-picker"
            required
          />
        </div>
      </label>

      <label>
        <span>End</span>
        <div class="datetime-group">
          <DatePicker
            :model-value="form.endDate"
            @update:model-value="onEndDateSelect"
            showIcon
            dateFormat="yy-mm-dd"
            placeholder="Select date"
            required
          />
          <InputText
            v-model="form.endTime"
            type="time"
            class="time-picker"
            required
          />
        </div>
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

/* Custom layout for Date + Time hybrid input */
.datetime-group {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

</style>
