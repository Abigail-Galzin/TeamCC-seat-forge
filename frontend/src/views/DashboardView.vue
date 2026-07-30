<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { getDashboardMetrics, type DashboardMetrics } from '../services/workshops'

const metrics = ref<DashboardMetrics | null>(null)

onMounted(async () => {
  metrics.value = await getDashboardMetrics()
})
</script>

<template>
  <div class="page">
    <h1>Operations dashboard</h1>
    <div v-if="metrics" class="grid">
      <Card><template #content><h2>{{ metrics.upcomingSessions }}</h2><p>Upcoming sessions</p></template></Card>
      <Card><template #content><h2>{{ metrics.heldRegistrations }}</h2><p>Held registrations</p></template></Card>
      <Card><template #content><h2>{{ metrics.confirmedRegistrations }}</h2><p>Confirmed registrations</p></template></Card>
      <Card><template #content><h2>{{ metrics.waitlistedRegistrations }}</h2><p>Waitlisted registrations</p></template></Card>
      <Card><template #content><h2>{{ metrics.expiredHolds }}</h2><p>Expired holds</p></template></Card>
      <Card><template #content><h2>{{ metrics.fullSessions }}</h2><p>Full sessions</p></template></Card>
    </div>

    <Card v-if="metrics?.topWaitlistedSessions?.length" class="list-card">
      <template #title>Top waitlisted sessions</template>
      <template #content>
        <ul>
          <li v-for="item in metrics.topWaitlistedSessions" :key="item.id">
            {{ item.title }} — {{ item.waitlistSize }} waitlisted
          </li>
        </ul>
      </template>
    </Card>
  </div>
</template>

<style scoped>
.page { max-width: 1000px; margin: 0 auto; padding: 2rem 1.5rem; }
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 1rem; margin-top: 1rem; }
.grid :deep(h2) { margin: 0; }
.grid :deep(p) { margin: 0.25rem 0 0; }
.list-card { margin-top: 1rem; }
ul { margin: 0.5rem 0 0; padding-left: 1rem; }
</style>
