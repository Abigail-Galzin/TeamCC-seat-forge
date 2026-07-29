<script setup lang="ts">
import { computed, ref } from 'vue'
import { storeToRefs } from 'pinia'
import { useToast } from 'primevue/usetoast'
import { useAttendeesStore } from '@/stores/attendees'
import { useWorkshopsStore } from '@/stores/workshops'
import {
  emptyAttendeeForm,
  isValidEmail,
  type Attendee,
  type AttendeeFormData,
} from '@/types/attendee'

const toast = useToast()
const attendeesStore = useAttendeesStore()
const workshopsStore = useWorkshopsStore()
const { attendees } = storeToRefs(attendeesStore)
const { workshops } = storeToRefs(workshopsStore)

const dialogVisible = ref(false)
const editingAttendee = ref<Attendee | null>(null)
const form = ref<AttendeeFormData>(emptyAttendeeForm())
const submitted = ref(false)

const workshopOptions = computed(() =>
  workshops.value.map((workshop) => ({
    label: workshop.title,
    value: workshop.id,
  })),
)

const dialogTitle = computed(() =>
  editingAttendee.value ? 'Editar asistente' : 'Nuevo asistente',
)

const isFormValid = computed(
  () =>
    form.value.name.trim().length > 0 &&
    isValidEmail(form.value.email) &&
    form.value.workshopId > 0,
)

const getWorkshopTitle = (workshopId: number) =>
  workshopsStore.getById(workshopId)?.title ?? '—'

const openCreateDialog = () => {
  editingAttendee.value = null
  form.value = emptyAttendeeForm()
  submitted.value = false
  dialogVisible.value = true
}

const openEditDialog = (attendee: Attendee) => {
  editingAttendee.value = attendee
  form.value = {
    name: attendee.name,
    email: attendee.email,
    workshopId: attendee.workshopId,
  }
  submitted.value = false
  dialogVisible.value = true
}

const closeDialog = () => {
  dialogVisible.value = false
  editingAttendee.value = null
  form.value = emptyAttendeeForm()
  submitted.value = false
}

const saveAttendee = () => {
  submitted.value = true
  if (!isFormValid.value) return

  const payload: AttendeeFormData = {
    name: form.value.name.trim(),
    email: form.value.email.trim(),
    workshopId: form.value.workshopId,
  }

  if (editingAttendee.value) {
    attendeesStore.update(editingAttendee.value.id, payload)
    toast.add({
      severity: 'success',
      summary: 'Asistente actualizado',
      detail: `"${payload.name}" se guardó correctamente.`,
      life: 3000,
    })
  } else {
    attendeesStore.create(payload)
    toast.add({
      severity: 'success',
      summary: 'Asistente creado',
      detail: `"${payload.name}" se agregó a la lista.`,
      life: 3000,
    })
  }

  closeDialog()
}
</script>

<template>
  <div class="attendees-container">
    <header class="page-header">
      <div>
        <h1>Asistentes</h1>
        <p class="subtitle">Administra los asistentes registrados en los workshops.</p>
      </div>
      <Button label="Nuevo asistente" icon="pi pi-plus" @click="openCreateDialog" />
    </header>

    <Card>
      <template #content>
        <DataTable
          :value="attendees"
          striped-rows
          paginator
          :rows="8"
          data-key="id"
          empty-message="No hay asistentes registrados."
        >
          <Column field="name" header="Nombre" sortable />
          <Column field="email" header="Email" sortable />
          <Column header="Workshop" sortable>
            <template #body="{ data }">
              {{ getWorkshopTitle(data.workshopId) }}
            </template>
          </Column>
          <Column header="Acciones" style="width: 6rem">
            <template #body="{ data }">
              <Button
                icon="pi pi-pencil"
                variant="text"
                severity="secondary"
                aria-label="Editar asistente"
                @click="openEditDialog(data)"
              />
            </template>
          </Column>
        </DataTable>
      </template>
    </Card>

    <Dialog
      v-model:visible="dialogVisible"
      :header="dialogTitle"
      modal
      :style="{ width: '28rem' }"
      @hide="closeDialog"
    >
      <div class="form-grid">
        <div class="field">
          <label for="attendee-workshop">Workshop</label>
          <Select
            id="attendee-workshop"
            v-model="form.workshopId"
            :options="workshopOptions"
            option-label="label"
            option-value="value"
            placeholder="Selecciona un workshop"
            class="w-full"
            :invalid="submitted && form.workshopId <= 0"
          />
          <small v-if="submitted && form.workshopId <= 0" class="error-text">
            Selecciona un workshop.
          </small>
        </div>

        <div class="field">
          <label for="attendee-name">Nombre</label>
          <InputText
            id="attendee-name"
            v-model="form.name"
            placeholder="Ej. Ana García"
            class="w-full"
            :invalid="submitted && !form.name.trim()"
          />
          <small v-if="submitted && !form.name.trim()" class="error-text">
            El nombre es obligatorio.
          </small>
        </div>

        <div class="field">
          <label for="attendee-email">Email</label>
          <InputText
            id="attendee-email"
            v-model="form.email"
            type="email"
            placeholder="Ej. ana@example.com"
            class="w-full"
            :invalid="submitted && !isValidEmail(form.email)"
          />
          <small v-if="submitted && !isValidEmail(form.email)" class="error-text">
            Ingresa un email válido.
          </small>
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" variant="outlined" severity="secondary" @click="closeDialog" />
        <Button label="Guardar" icon="pi pi-check" @click="saveAttendee" />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.attendees-container {
  max-width: 1100px;
  margin: 0 auto;
  padding: 2rem 1.5rem 3rem;
}

.page-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem;
  margin-bottom: 1.5rem;
}

.page-header h1 {
  margin: 0 0 0.5rem;
  font-size: 2rem;
  font-weight: 800;
}

.subtitle {
  margin: 0;
  color: #64748b;
}

.form-grid {
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.field label {
  font-weight: 600;
  font-size: 0.875rem;
}

.error-text {
  color: #ef4444;
}

@media (max-width: 640px) {
  .page-header {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
