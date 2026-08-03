<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue';

const props = defineProps<{
  expiresAt: string;
}>();

const emit = defineEmits<{
  expired: [];
}>();

const timeRemaining = ref<string>('');
let timerInterval: number | null = null;

function calculateTimeRemaining(expiresAt: string): string {
  const expiry = new Date(expiresAt).getTime();
  const now = Date.now();
  const diffSeconds = Math.floor((expiry - now) / 1000);

  if (diffSeconds <= 0) return 'Expired';

  const days = Math.floor(diffSeconds / 86400);
  const hours = Math.floor((diffSeconds % 86400) / 3600);
  const minutes = Math.floor((diffSeconds % 3600) / 60);
  const seconds = diffSeconds % 60;

  if (days > 0) {
    return `${days}d ${hours}h ${minutes}m ${seconds}s`;
  } else if (hours > 0) {
    return `${hours}h ${minutes}m ${seconds}s`;
  } else if (minutes > 0) {
    return `${minutes}m ${seconds}s`;
  } else {
    return `${seconds}s`;
  }
}

function getRemainingSeconds(expiresAt: string): number {
  const expiry = new Date(expiresAt).getTime();
  const now = Date.now();
  return Math.floor((expiry - now) / 1000);
}

function startTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }

  timeRemaining.value = calculateTimeRemaining(props.expiresAt);

  timerInterval = window.setInterval(() => {
    const remaining = calculateTimeRemaining(props.expiresAt);
    timeRemaining.value = remaining;

    if (remaining === 'Expired') {
      stopTimer();
      emit('expired');
    }
  }, 1000);
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval);
    timerInterval = null;
  }
}

// Watch for changes in expiresAt
watch(
  () => props.expiresAt,
  () => {
    startTimer();
  },
);

onMounted(() => {
  startTimer();
});

onBeforeUnmount(() => {
  stopTimer();
});

// Expose methods for parent component
defineExpose({
  stopTimer,
  startTimer,
  getRemainingSeconds,
});
</script>

<template>
  <span class="hold-timer" :class="{ 'timer-warning': timeRemaining && getRemainingSeconds(expiresAt) < 30 }">
    <i class="pi pi-clock" style="margin-right: 0.5rem"></i>
    {{ timeRemaining || 'Calculating...' }}
  </span>
</template>

<style scoped>
.hold-timer {
  color: #2563eb;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  transition: color 0.3s ease;
}

.hold-timer.timer-warning {
  color: #dc2626;
  animation: pulse 1s ease-in-out infinite;
}

@keyframes pulse {

  0%,
  100% {
    opacity: 1;
  }

  50% {
    opacity: 0.5;
  }
}
</style>
