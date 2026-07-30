<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { createWorkshop } from '../services/workshops'
import { getErrorMessage } from '../services/api'

const router = useRouter()
const toast = useToast()
const submitting = ref(false)
const form = reactive({
  title: '',
  description: '',
  topic: '',
  active: true,
})

async function submit() {
  submitting.value = true
  try {
    await createWorkshop({ ...form })
    toast.add({ severity: 'success', summary: 'Workshop created', detail: 'The workshop was created successfully.', life: 3000 })
    router.push({ name: 'admin-workshops' })
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
        <h1>New workshop</h1>
      </div>
    </div>

    <form class="card" @submit.prevent="submit">
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
        :label="submitting ? 'Creating...' : 'Save'"
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
</style>
