<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { getWorkshopById, updateWorkshop } from '../services/workshops'
import { getErrorMessage } from '../services/api'

const route = useRoute()
const router = useRouter()
const toast = useToast()
const workshopId = Number(route.params.workshopId)
const loading = ref(true)
const notFound = ref(false)
const loadError = ref<string | null>(null)
const submitting = ref(false)
const form = reactive({
  title: '',
  description: '',
  topic: '',
  active: true,
})

onMounted(async () => {
  try {
    const workshop = await getWorkshopById(workshopId)
    if (!workshop) {
      notFound.value = true
      return
    }

    form.title = workshop.title
    form.description = workshop.description
    form.topic = workshop.topic
    form.active = workshop.active
  } catch (error) {
    loadError.value = getErrorMessage(error)
  } finally {
    loading.value = false
  }
})

async function submit() {
  submitting.value = true
  try {
    await updateWorkshop(workshopId, { ...form })
    toast.add({ severity: 'success', summary: 'Workshop updated', detail: 'The workshop was saved successfully.', life: 3000 })
    router.push({ name: 'admin-workshops' })
  } catch (error) {
    toast.add({ severity: 'error', summary: 'Save failed', detail: getErrorMessage(error), life: 4000 })
  } finally {
    submitting.value = false
  }
}
</script>

<template>
  <div class="page">
    <div class="page-header">
      <div>
        <p class="eyebrow">Edit</p>
        <h1>Edit workshop</h1>
      </div>
      <Button
        label="Back to workshops"
        icon="pi pi-angle-left"
        severity="primary"
        variant="outlined"
        @click="router.push({ name: 'admin-workshops' })"
      />
    </div>

    <div v-if="loading" class="state">Loading workshop...</div>
    <Message v-else-if="loadError" severity="error">{{ loadError }}</Message>
    <div v-else-if="notFound" class="state">Workshop not found.</div>
    <form v-else class="card" @submit.prevent="submit">
      <label>
        <span>Title</span>
        <InputText v-model="form.title" required />
      </label>

      <label>
        <span>Description</span>
        <Textarea v-model="form.description" rows="4" required />
      </label>

      <label>
        <span>Topic</span>
        <InputText v-model="form.topic" required />
      </label>

      <div class="checkbox">
        <Checkbox v-model="form.active" :binary="true" inputId="workshop-active" />
        <label for="workshop-active">Active</label>
      </div>

      <Button
        type="submit"
        :label="submitting ? 'Saving...' : 'Save changes'"
        severity="primary"
        :disabled="submitting"
        class="form-submit"
      />
    </form>
  </div>
</template>

<style scoped>
.page {
  max-width: 700px;
  margin: 0 auto;
  padding: 2rem 1.5rem;
}
.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 1rem;
  margin-bottom: 1rem;
}
.eyebrow {
  text-transform: uppercase;
  letter-spacing: 0.2em;
  color: #64748b;
  font-size: 0.8rem;
  margin: 0 0 0.25rem;
}
h1 {
  margin: 0;
}
.card {
  display: grid;
  gap: 1rem;
  background: white;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1.25rem;
}
label {
  display: grid;
  gap: 0.4rem;
}
.checkbox {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}
.form-submit {
  justify-self: end;
}
.state {
  padding: 1rem;
  background: #f8fafc;
  border-radius: 12px;
}
</style>
