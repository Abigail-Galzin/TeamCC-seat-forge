<script setup lang="ts">
import { useRouter } from 'vue-router'
import type { Workshop } from '@/types/workshop'

defineProps<{
  workshop: Workshop
}>()

const router = useRouter()

const goBack = () => {
  router.push({ name: 'workshops' })
}
</script>

<template>
  <header class="workshop-context-header">
    <div class="header-main">
      <Button
        label="Volver a Workshops"
        icon="pi pi-arrow-left"
        variant="text"
        severity="secondary"
        class="back-button"
        @click="goBack"
      />
      <h1>{{ workshop.title }}</h1>
      <p class="subtitle">{{ workshop.topic }} · {{ workshop.description }}</p>
    </div>

    <div v-if="$slots.actions" class="header-actions">
      <slot name="actions" />
    </div>
  </header>
</template>

<style scoped>
.workshop-context-header {
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  justify-content: space-between;
  gap: 1rem 1.5rem;
  margin-bottom: 1.5rem;
}

.header-main {
  flex: 1;
  min-width: 16rem;
}

.back-button {
  padding-left: 0;
  margin-bottom: 0.5rem;
}

.header-main h1 {
  margin: 0 0 0.5rem;
  font-size: 2rem;
  font-weight: 800;
}

.subtitle {
  margin: 0;
  color: #64748b;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

@media (max-width: 768px) {
  .workshop-context-header {
    flex-direction: column;
    align-items: stretch;
  }

  .header-actions {
    width: 100%;
  }
}
</style>
