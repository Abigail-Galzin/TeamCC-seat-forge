<script setup lang="ts">
import { ref, computed } from 'vue'
import { storeToRefs } from 'pinia'
import { useRouter } from 'vue-router'
import { useToast } from 'primevue/usetoast'
import { useWorkshopsStore } from '@/stores/workshops'
import { emptyWorkshopForm, type Workshop, type WorkshopFormData } from '@/types/workshop'

const toast = useToast()
const router = useRouter()
const workshopsStore = useWorkshopsStore()
const { workshops } = storeToRefs(workshopsStore)

const dialogVisible = ref(false)
const editingWorkshop = ref<Workshop | null>(null)
const form = ref<WorkshopFormData>(emptyWorkshopForm())
const submitted = ref(false)

const topicOptions = ['Frontend', 'Backend', 'Quality', 'UI/UX', 'DevOps', 'General']

const dialogTitle = computed(() =>
  editingWorkshop.value ? 'Editar Workshop' : 'Nuevo Workshop',
)

const openCreateDialog = () => {
  editingWorkshop.value = null
  form.value = emptyWorkshopForm()
  submitted.value = false
  dialogVisible.value = true
}

const openEditDialog = (workshop: Workshop) => {
  editingWorkshop.value = workshop
  form.value = {
    title: workshop.title,
    description: workshop.description,
    topic: workshop.topic,
    active: workshop.active,
  }
  submitted.value = false
  dialogVisible.value = true
}

const closeDialog = () => {
  dialogVisible.value = false
  editingWorkshop.value = null
  form.value = emptyWorkshopForm()
  submitted.value = false
}

const isFormValid = computed(
  () =>
    form.value.title.trim().length > 0 &&
    form.value.description.trim().length > 0 &&
    form.value.topic.trim().length > 0,
)

const saveWorkshop = () => {
  submitted.value = true
  if (!isFormValid.value) return

  const payload: WorkshopFormData = {
    title: form.value.title.trim(),
    description: form.value.description.trim(),
    topic: form.value.topic.trim(),
    active: form.value.active,
  }

  if (editingWorkshop.value) {
    workshopsStore.update(editingWorkshop.value.id, payload)
    toast.add({
      severity: 'success',
      summary: 'Workshop actualizado',
      detail: `"${payload.title}" se guardó correctamente.`,
      life: 3000,
    })
  } else {
    workshopsStore.create(payload)
    toast.add({
      severity: 'success',
      summary: 'Workshop creado',
      detail: `"${payload.title}" se agregó a la lista.`,
      life: 3000,
    })
  }

  closeDialog()
}

const openSessions = (workshop: Workshop) => {
  router.push({ name: 'workshop-sessions', params: { id: workshop.id } })
}
</script>

<template>
  <div class="workshops-container">
    <header class="page-header">
      <div>
        <h1>Workshops</h1>
        <p class="subtitle">Administra los workshops disponibles con datos de ejemplo.</p>
      </div>
      <Button label="Nuevo Workshop" icon="pi pi-plus" @click="openCreateDialog" />
    </header>

    <Card>
      <template #content>
        <DataTable
          :value="workshops"
          striped-rows
          paginator
          :rows="5"
          :rows-per-page-options="[5, 10, 20]"
          data-key="id"
          empty-message="No hay workshops registrados."
        >
          <Column field="title" header="Título" sortable />
          <Column field="topic" header="Tópico" sortable />
          <Column field="description" header="Descripción">
            <template #body="{ data }">
              <span class="description-cell">{{ data.description }}</span>
            </template>
          </Column>
          <Column field="active" header="Activo" sortable style="width: 8rem">
            <template #body="{ data }">
              <Tag
                :value="data.active ? 'Activo' : 'Inactivo'"
                :severity="data.active ? 'success' : 'secondary'"
              />
            </template>
          </Column>
          <Column header="Acciones" style="width: 11rem">
            <template #body="{ data }">
              <div class="action-buttons">
                <Button
                  icon="pi pi-calendar"
                  variant="text"
                  severity="primary"
                  aria-label="Ver sesiones"
                  v-tooltip.top="'Ver sesiones'"
                  @click="openSessions(data)"
                />
                <Button
                  icon="pi pi-pencil"
                  variant="text"
                  severity="secondary"
                  aria-label="Editar workshop"
                  @click="openEditDialog(data)"
                />
              </div>
            </template>
          </Column>
        </DataTable>
      </template>
    </Card>

    <Dialog
      v-model:visible="dialogVisible"
      :header="dialogTitle"
      modal
      :style="{ width: '32rem' }"
      @hide="closeDialog"
    >
      <div class="form-grid">
        <div class="field">
          <label for="title">Título</label>
          <InputText
            id="title"
            v-model="form.title"
            placeholder="Ej. Introducción a Vue 3"
            class="w-full"
            :invalid="submitted && !form.title.trim()"
          />
          <small v-if="submitted && !form.title.trim()" class="error-text">
            El título es obligatorio.
          </small>
        </div>

        <div class="field">
          <label for="topic">Tópico</label>
          <Select
            id="topic"
            v-model="form.topic"
            :options="topicOptions"
            placeholder="Selecciona un tópico"
            class="w-full"
            :invalid="submitted && !form.topic.trim()"
          />
          <small v-if="submitted && !form.topic.trim()" class="error-text">
            El tópico es obligatorio.
          </small>
        </div>

        <div class="field">
          <label for="description">Descripción</label>
          <Textarea
            id="description"
            v-model="form.description"
            rows="4"
            placeholder="Describe el contenido del workshop..."
            class="w-full"
            :invalid="submitted && !form.description.trim()"
          />
          <small v-if="submitted && !form.description.trim()" class="error-text">
            La descripción es obligatoria.
          </small>
        </div>

        <div class="field field-inline">
          <label for="active">Activo</label>
          <ToggleSwitch id="active" v-model="form.active" />
        </div>
      </div>

      <template #footer>
        <Button label="Cancelar" variant="outlined" severity="secondary" @click="closeDialog" />
        <Button label="Guardar" icon="pi pi-check" @click="saveWorkshop" />
      </template>
    </Dialog>
  </div>
</template>

<style scoped>
.workshops-container {
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

.field-inline {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
}

.error-text {
  color: #ef4444;
}

.description-cell {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

.action-buttons {
  display: flex;
  gap: 0.25rem;
}

@media (max-width: 640px) {
  .page-header {
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
