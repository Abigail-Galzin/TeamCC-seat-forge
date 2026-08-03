<script setup lang="ts">
import { ref } from 'vue'
import HoldTimer from './HoldTimer.vue'
import type { Registration } from '../types/registration'
import type { Attendee } from '../types/attendee'

const props = defineProps<{
  visible: boolean
  registration: Registration | null
  attendee: Attendee | null
  confirming: boolean
}>()

const emit = defineEmits<{
  'update:visible': [value: boolean]
  confirm: []
  cancel: []
  expired: []
}>()

const holdTimerRef = ref<InstanceType<typeof HoldTimer> | null>(null)

function handleConfirm() {
  emit('confirm')
}

function handleCancel() {
  if (holdTimerRef.value) {
    holdTimerRef.value.stopTimer()
  }
  emit('cancel')
}

function handleExpired() {
  emit('expired')
}

function getTimerWarning(expiresAt: string | undefined): boolean {
  if (!expiresAt) return false
  const expiry = new Date(expiresAt).getTime()
  const now = Date.now()
  const diffSeconds = Math.floor((expiry - now) / 1000)
  return diffSeconds < 30 && diffSeconds > 0
}
</script>

<template>
  <Dialog :visible="visible" header="Confirm Your Reservation" :modal="true" :closable="false" class="p-fluid"
    :style="{ width: '500px' }" @update:visible="$emit('update:visible', $event)">
    <div class="confirmation-content" v-if="registration && attendee">
      <div class="confirmation-icon">
        <i class="pi pi-check-circle" style="font-size: 3rem; color: #22c55e;"></i>
      </div>
      <h3>Seat held successfully!</h3>
      <p class="sub-message">Please review your details and confirm your reservation.</p>

      <div class="registration-details">
        <div class="detail-row">
          <span class="detail-label">Name:</span>
          <span class="detail-value">{{ attendee.name }}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Email:</span>
          <span class="detail-value">{{ attendee.email }}</span>
        </div>
        <div class="detail-row">
          <span class="detail-label">Status:</span>
          <Tag :value="registration.status" severity="success" />
        </div>
        <div class="detail-row" v-if="registration.holdExpiresAt">
          <span class="detail-label">Hold expires in:</span>
          <HoldTimer ref="holdTimerRef" :expires-at="registration.holdExpiresAt" @expired="handleExpired" />
        </div>
        <div class="detail-row" v-if="registration.id">
          <span class="detail-label">Registration ID:</span>
          <span class="detail-value">#{{ registration.id }}</span>
        </div>
      </div>

      <div class="confirmation-actions">
        <p class="confirmation-message"
          :class="{ 'warning-message': registration.holdExpiresAt && getTimerWarning(registration.holdExpiresAt) }">
          <i class="pi pi-info-circle" style="margin-right: 0.5rem;"></i>
          {{ registration.holdExpiresAt && getTimerWarning(registration.holdExpiresAt) ?
            '⚠️ Your hold is about to expire! Please confirm quickly.' :
            'Your seat will be held until you confirm or the hold expires.' }}
        </p>
      </div>
    </div>

    <template #footer>
      <div class="modal-footer">
        <Button label="Cancel" severity="secondary" @click="handleCancel" :disabled="confirming" />
        <Button label="Confirm Reservation" severity="success" @click="handleConfirm" :loading="confirming"
          :disabled="confirming" autofocus />
      </div>
    </template>
  </Dialog>
</template>

<style scoped>
.confirmation-content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  padding: 0.5rem 0;
}

.confirmation-icon {
  margin-bottom: 0.5rem;
}

.sub-message {
  color: #64748b;
  margin: -0.5rem 0 0 0;
  font-size: 0.95rem;
}

.registration-details {
  width: 100%;
  background: #f8fafc;
  border-radius: 8px;
  padding: 1rem;
  margin: 0.5rem 0;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid #e2e8f0;
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-label {
  font-weight: 600;
  color: #475569;
}

.detail-value {
  color: #0f172a;
}

.confirmation-actions {
  width: 100%;
  margin-top: 0.5rem;
}

.confirmation-message {
  text-align: center;
  color: #475569;
  margin: 0;
  font-size: 0.9rem;
  background: #f1f5f9;
  padding: 0.75rem;
  border-radius: 6px;
  transition: all 0.3s ease;
}

.confirmation-message.warning-message {
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.modal-footer {
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
  width: 100%;
  padding-top: 0.5rem;
}
</style>
