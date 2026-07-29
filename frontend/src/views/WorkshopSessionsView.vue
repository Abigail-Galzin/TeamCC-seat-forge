<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useConfirm } from "primevue/useconfirm";
import { useToast } from "primevue/usetoast";
import { useSessionsStore } from "@/stores/sessions";
import { useWorkshopsStore } from "@/stores/workshops";
import WorkshopContextHeader from "@/components/WorkshopContextHeader.vue";
import {
  emptySessionForm,
  formatSessionSchedule,
  getAvailableSeats,
  getStatusLabel,
  getStatusSeverity,
  SESSION_STATUS_OPTIONS,
  type SessionFormData,
  type WorkshopSession,
} from "@/types/session";

const route = useRoute();
const router = useRouter();
const toast = useToast();
const confirm = useConfirm();
const sessionsStore = useSessionsStore();
const workshopsStore = useWorkshopsStore();

const workshopId = computed(() => Number(route.params.id));
const workshop = computed(() => workshopsStore.getById(workshopId.value));

const selectedSession = ref<WorkshopSession | null>(null);
const isCreateMode = ref(false);
const form = ref<SessionFormData>(emptySessionForm());
const submitted = ref(false);

const workshopSessions = computed(() =>
  sessionsStore.getByWorkshopId(workshopId.value),
);

const formTitle = computed(() => {
  if (isCreateMode.value) return "Nueva sesión";
  if (selectedSession.value) return "Editar sesión";
  return "Detalle de sesión";
});

const isFormValid = computed(() => {
  if (!form.value.startsAt || !form.value.endsAt) return false;
  if (form.value.capacity <= 0) return false;
  return form.value.endsAt.getTime() > form.value.startsAt.getTime();
});

watch(
  workshopId,
  () => {
    selectedSession.value = null;
    isCreateMode.value = false;
    form.value = emptySessionForm();
    submitted.value = false;
  },
  { immediate: true },
);

watch(
  workshop,
  (value) => {
    if (!value && workshopId.value) {
      router.replace({ name: "workshops" });
    }
  },
  { immediate: true },
);

const selectSession = (session: WorkshopSession) => {
  selectedSession.value = session;
  isCreateMode.value = false;
  submitted.value = false;
  form.value = {
    startsAt: new Date(session.startsAt),
    endsAt: new Date(session.endsAt),
    capacity: session.capacity,
    status: session.status,
  };
};

const openCreateForm = () => {
  selectedSession.value = null;
  isCreateMode.value = true;
  submitted.value = false;
  form.value = emptySessionForm();
};

const resetForm = () => {
  selectedSession.value = null;
  isCreateMode.value = false;
  submitted.value = false;
  form.value = emptySessionForm();
};

const saveSession = () => {
  submitted.value = true;
  if (!isFormValid.value) return;

  if (isCreateMode.value) {
    const created = sessionsStore.create(workshopId.value, form.value);
    if (!created) return;

    toast.add({
      severity: "success",
      summary: "Sesión creada",
      detail: "La sesión se agregó correctamente.",
      life: 3000,
    });
    selectSession(created);
    isCreateMode.value = false;
    return;
  }

  if (!selectedSession.value) return;

  const updated = sessionsStore.update(selectedSession.value.id, form.value);
  if (!updated) return;

  toast.add({
    severity: "success",
    summary: "Sesión actualizada",
    detail: "Los cambios se guardaron correctamente.",
    life: 3000,
  });
  selectSession(updated);
};

const deleteSession = () => {
  if (!selectedSession.value) return;

  confirm.require({
    message: "¿Deseas eliminar esta sesión? Esta acción no se puede deshacer.",
    header: "Eliminar sesión",
    icon: "pi pi-exclamation-triangle",
    acceptLabel: "Eliminar",
    rejectLabel: "Cancelar",
    acceptClass: "p-button-danger",
    accept: () => {
      const deleted = sessionsStore.remove(selectedSession.value!.id);
      if (!deleted) return;

      toast.add({
        severity: "info",
        summary: "Sesión eliminada",
        detail: "La sesión fue eliminada de la lista.",
        life: 3000,
      });
      resetForm();
    },
  });
};
</script>

<template>
  <div v-if="workshop" class="sessions-container">
    <WorkshopContextHeader :workshop="workshop">
      <template #actions>
        <Button
          label="Nueva sesión"
          icon="pi pi-plus"
          @click="openCreateForm"
        />
      </template>
    </WorkshopContextHeader>

    <div class="sessions-layout">
      <Card class="sessions-table-card">
        <template #title>Sesiones programadas</template>
        <template #content>
          <DataTable
            :value="workshopSessions"
            v-model:selection="selectedSession"
            striped-rows
            paginator
            :rows="5"
            data-key="id"
            selection-mode="single"
            empty-message="Este workshop no tiene sesiones."
            @row-select="selectSession($event.data)"
          >
            <Column header="Horario">
              <template #body="{ data }">
                {{ formatSessionSchedule(data.startsAt, data.endsAt) }}
              </template>
            </Column>
            <Column field="capacity" header="Capacidad" sortable />
            <Column header="Disponibles">
              <template #body="{ data }">
                {{ getAvailableSeats(data) }}
              </template>
            </Column>
            <Column field="heldCount" header="Held" sortable />
            <Column field="confirmedCount" header="Confirmados" sortable />
            <Column field="waitlistSize" header="Waitlist" sortable />
            <Column field="status" header="Estado" sortable>
              <template #body="{ data }">
                <Tag
                  :value="getStatusLabel(data.status)"
                  :severity="getStatusSeverity(data.status)"
                />
              </template>
            </Column>
          </DataTable>
        </template>
      </Card>

      <Card class="session-form-card">
        <template #title>{{ formTitle }}</template>
        <template #content>
          <div v-if="!selectedSession && !isCreateMode" class="empty-form">
            <i class="pi pi-calendar empty-icon"></i>
            <p>Selecciona una sesión de la tabla o crea una nueva.</p>
          </div>

          <div v-else class="form-grid">
            <div class="field">
              <label for="starts-at">Inicio (starts_at)</label>
              <DatePicker
                id="starts-at"
                v-model="form.startsAt"
                show-time
                hour-format="24"
                date-format="dd/mm/yy"
                placeholder="Fecha y hora de inicio"
                class="w-full"
                :invalid="submitted && !form.startsAt"
              />
            </div>

            <div class="field">
              <label for="ends-at">Fin (ends_at)</label>
              <DatePicker
                id="ends-at"
                v-model="form.endsAt"
                show-time
                hour-format="24"
                date-format="dd/mm/yy"
                placeholder="Fecha y hora de fin"
                class="w-full"
                :invalid="submitted && !form.endsAt"
              />
            </div>

            <div class="field">
              <label for="capacity">Capacidad</label>
              <InputNumber
                id="capacity"
                v-model="form.capacity"
                :min="1"
                show-buttons
                class="w-full"
                :invalid="submitted && form.capacity <= 0"
              />
            </div>

            <div class="field">
              <label for="status">Estado</label>
              <Select
                id="status"
                v-model="form.status"
                :options="SESSION_STATUS_OPTIONS"
                option-label="label"
                option-value="value"
                placeholder="Selecciona un estado"
                class="w-full"
              />
            </div>

            <small v-if="submitted && !isFormValid" class="error-text">
              Completa fechas válidas y una capacidad mayor a cero. La hora de
              fin debe ser posterior al inicio.
            </small>

            <div class="form-actions">
              <Button
                v-if="isCreateMode"
                label="Crear sesión"
                icon="pi pi-check"
                @click="saveSession"
              />
              <template v-else>
                <Button
                  label="Guardar cambios"
                  icon="pi pi-check"
                  @click="saveSession"
                />
                <Button
                  label="Eliminar"
                  icon="pi pi-trash"
                  severity="danger"
                  variant="outlined"
                  @click="deleteSession"
                />
              </template>
              <Button
                label="Limpiar"
                variant="outlined"
                severity="secondary"
                @click="resetForm"
              />
            </div>
          </div>
        </template>
      </Card>
    </div>
  </div>
</template>

<style scoped>
.sessions-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 2rem 1.5rem 3rem;
}

.sessions-layout {
  display: grid;
  grid-template-columns: minmax(0, 1.4fr) minmax(18rem, 0.8fr);
  gap: 1.5rem;
  align-items: start;
}

.form-grid {
  display: flex;
  flex-direction: column;
  gap: 1rem;
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

.form-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  margin-top: 0.5rem;
}

.empty-form {
  text-align: center;
  color: #64748b;
  padding: 2rem 1rem;
}

.empty-icon {
  font-size: 2rem;
  margin-bottom: 0.75rem;
  display: block;
}

.error-text {
  color: #ef4444;
}

@media (max-width: 960px) {
  .sessions-layout {
    grid-template-columns: 1fr;
  }
}
</style>
