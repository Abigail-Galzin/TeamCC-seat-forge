<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { getDashboardWorkshops, getWorkshopDashboardMetrics } from '../services/dashboard'
import { getErrorMessage } from '../services/api'
import type { DashboardCurrentSession, DashboardWorkshopSummary, WorkshopDashboardMetrics } from '../types/dashboard'

const workshops = ref<DashboardWorkshopSummary[]>([])
const workshopsLoading = ref(true)
const workshopsError = ref<string | null>(null)

const selectedWorkshopId = ref<number | null>(null)
const metrics = ref<WorkshopDashboardMetrics | null>(null)
const metricsLoading = ref(false)
const metricsError = ref<string | null>(null)

const dateFormatter = new Intl.DateTimeFormat(undefined, {
  month: 'short',
  day: 'numeric',
  hour: 'numeric',
  minute: '2-digit',
})

function formatDate(iso: string | null): string {
  if (!iso) return 'Unknown date'
  return dateFormatter.format(new Date(iso))
}

function sessionBlurb(session: DashboardCurrentSession | null): string {
  if (!session) return 'No upcoming sessions'
  return session.inProgress ? `In progress · started ${formatDate(session.startsAt)}` : `Next: ${formatDate(session.startsAt)}`
}

const statCards = computed(() => {
  if (!metrics.value) return []
  return [
    { key: 'upcoming', accent: 1, icon: 'pi pi-calendar', label: 'Upcoming sessions', value: metrics.value.upcomingSessions },
    { key: 'held', accent: 2, icon: 'pi pi-lock', label: 'Held registrations', value: metrics.value.heldRegistrations },
    { key: 'confirmed', accent: 3, icon: 'pi pi-check-circle', label: 'Confirmed registrations', value: metrics.value.confirmedRegistrations },
    { key: 'waitlisted', accent: 4, icon: 'pi pi-users', label: 'Waitlisted registrations', value: metrics.value.waitlistedRegistrations },
    { key: 'expired', accent: 5, icon: 'pi pi-clock', label: 'Expired holds today', value: metrics.value.expiredHoldsToday },
    { key: 'full', accent: 6, icon: 'pi pi-ban', label: 'Full sessions', value: metrics.value.fullSessions },
  ]
})

async function loadWorkshops() {
  workshopsLoading.value = true
  workshopsError.value = null
  try {
    workshops.value = await getDashboardWorkshops()
  } catch (error) {
    workshopsError.value = getErrorMessage(error)
  } finally {
    workshopsLoading.value = false
  }
}

async function selectWorkshop(workshopId: number) {
  selectedWorkshopId.value = workshopId
  metrics.value = null
  metricsLoading.value = true
  metricsError.value = null
  try {
    metrics.value = await getWorkshopDashboardMetrics(workshopId)
  } catch (error) {
    metricsError.value = getErrorMessage(error)
  } finally {
    metricsLoading.value = false
  }
}

onMounted(loadWorkshops)
</script>

<template>
  <div class="page">
    <p class="eyebrow">Operations</p>
    <h1>Dashboard</h1>

    <section class="workshop-picker">
      <h2>Active workshops</h2>

      <div v-if="workshopsLoading" class="state">Loading workshops...</div>
      <Message v-else-if="workshopsError" severity="error">{{ workshopsError }}</Message>
      <p v-else-if="!workshops.length" class="state">No active workshops yet.</p>

      <div v-else class="workshop-grid">
        <Card
          v-for="workshop in workshops"
          :key="workshop.id"
          class="workshop-card"
          :class="{ selected: workshop.id === selectedWorkshopId }"
          @click="selectWorkshop(workshop.id)"
        >
          <template #title>
            <div class="workshop-title-row">
              <span>{{ workshop.title }}</span>
              <Tag :value="workshop.topic" severity="secondary" />
            </div>
          </template>
          <template #content>
            <div class="session-blurb" :class="{ live: workshop.currentSession?.inProgress }">
              <span class="dot" :class="{ live: workshop.currentSession?.inProgress }"></span>
              {{ sessionBlurb(workshop.currentSession) }}
            </div>
          </template>
        </Card>
      </div>
    </section>

    <section v-if="selectedWorkshopId" class="metrics-section">
      <h2>Metrics for {{ metrics?.workshopTitle ?? '…' }}</h2>

      <div v-if="metricsLoading" class="state">Loading metrics...</div>
      <Message v-else-if="metricsError" severity="error">{{ metricsError }}</Message>

      <template v-else-if="metrics">
        <div class="stat-grid">
          <Card v-for="card in statCards" :key="card.key" class="stat-card" :class="`accent-${card.accent}`">
            <template #content>
              <div class="stat-body">
                <span class="icon-chip"><i :class="card.icon"></i></span>
                <div>
                  <div class="stat-value">{{ card.value }}</div>
                  <div class="stat-label">{{ card.label }}</div>
                </div>
              </div>
            </template>
          </Card>
        </div>

        <Card class="waitlist-card accent-7">
          <template #title>
            <span class="icon-chip"><i class="pi pi-trophy"></i></span>
            Top 3 waitlisted sessions
          </template>
          <template #content>
            <ol v-if="metrics.topWaitlistedSessions.length" class="waitlist-list">
              <li v-for="item in metrics.topWaitlistedSessions" :key="item.sessionId">
                <span>Session on {{ formatDate(item.startsAt) }}</span>
                <Badge :value="`${item.waitlistSize} waitlisted`" severity="warn" />
              </li>
            </ol>
            <p v-else class="state">No sessions have a waitlist yet.</p>
          </template>
        </Card>
      </template>
    </section>
  </div>
</template>

<style scoped>
.page {
  max-width: 1100px;
  margin: 0 auto;
  padding: 2rem 1.5rem 3rem;

  --accent-1: #2a78d6;
  --accent-1-soft: rgba(42, 120, 214, 0.12);
  --accent-2: #eb6834;
  --accent-2-soft: rgba(235, 104, 52, 0.12);
  --accent-3: #1baf7a;
  --accent-3-soft: rgba(27, 175, 122, 0.12);
  --accent-4: #eda100;
  --accent-4-soft: rgba(237, 161, 0, 0.14);
  --accent-5: #e87ba4;
  --accent-5-soft: rgba(232, 123, 164, 0.16);
  --accent-6: #008300;
  --accent-6-soft: rgba(0, 131, 0, 0.12);
  --accent-7: #4a3aa7;
  --accent-7-soft: rgba(74, 58, 167, 0.12);
}

.my-app-dark .page {
  --accent-1: #3987e5;
  --accent-1-soft: rgba(57, 135, 229, 0.2);
  --accent-2: #d95926;
  --accent-2-soft: rgba(217, 89, 38, 0.2);
  --accent-3: #199e70;
  --accent-3-soft: rgba(25, 158, 112, 0.22);
  --accent-4: #c98500;
  --accent-4-soft: rgba(201, 133, 0, 0.24);
  --accent-5: #d55181;
  --accent-5-soft: rgba(213, 81, 129, 0.24);
  --accent-6: #008300;
  --accent-6-soft: rgba(0, 131, 0, 0.22);
  --accent-7: #9085e9;
  --accent-7-soft: rgba(144, 133, 233, 0.24);
}

.eyebrow { text-transform: uppercase; letter-spacing: 0.2em; color: #64748b; font-size: 0.8rem; margin-bottom: 0.25rem; }
h1 { margin: 0 0 1.5rem; }
h2 { font-size: 1.05rem; margin: 0 0 0.75rem; color: inherit; }
.state { padding: 1rem; background: #f8fafc; border-radius: 12px; }
.my-app-dark .state { background: #111827; }

.workshop-picker { margin-bottom: 2rem; }
.workshop-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 1rem; }

.workshop-card {
  cursor: pointer;
  border-radius: 14px;
  border: 2px solid transparent;
  transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}
.workshop-card:hover { transform: translateY(-2px); box-shadow: 0 8px 20px rgba(15, 23, 42, 0.08); }
.workshop-card.selected { border-color: #10b981; box-shadow: 0 8px 20px rgba(16, 185, 129, 0.18); }

.workshop-title-row { display: flex; justify-content: space-between; align-items: center; gap: 0.5rem; font-size: 1rem; }

.session-blurb { display: flex; align-items: center; gap: 0.5rem; color: #64748b; font-size: 0.9rem; }
.dot { width: 8px; height: 8px; border-radius: 50%; background: #94a3b8; flex-shrink: 0; }
.dot.live { background: #0ca30c; box-shadow: 0 0 0 3px rgba(12, 163, 12, 0.2); }

.metrics-section { margin-top: 1rem; }

.stat-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin-bottom: 1rem; }

.stat-card { border-radius: 14px; border-top: 3px solid transparent; }
.stat-card.accent-1 { border-top-color: var(--accent-1); }
.stat-card.accent-2 { border-top-color: var(--accent-2); }
.stat-card.accent-3 { border-top-color: var(--accent-3); }
.stat-card.accent-4 { border-top-color: var(--accent-4); }
.stat-card.accent-5 { border-top-color: var(--accent-5); }
.stat-card.accent-6 { border-top-color: var(--accent-6); }
.waitlist-card.accent-7 { border-top: 3px solid var(--accent-7); border-radius: 14px; }

.stat-body { display: flex; align-items: center; gap: 0.85rem; }
.icon-chip {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  flex-shrink: 0;
  font-size: 1.1rem;
}
.accent-1 .icon-chip { background: var(--accent-1-soft); color: var(--accent-1); }
.accent-2 .icon-chip { background: var(--accent-2-soft); color: var(--accent-2); }
.accent-3 .icon-chip { background: var(--accent-3-soft); color: var(--accent-3); }
.accent-4 .icon-chip { background: var(--accent-4-soft); color: var(--accent-4); }
.accent-5 .icon-chip { background: var(--accent-5-soft); color: var(--accent-5); }
.accent-6 .icon-chip { background: var(--accent-6-soft); color: var(--accent-6); }
.accent-7 .icon-chip { background: var(--accent-7-soft); color: var(--accent-7); margin-right: 0.5rem; width: 32px; height: 32px; font-size: 1rem; }

.stat-value { font-size: 1.8rem; font-weight: 700; line-height: 1.1; }
.stat-label { color: #64748b; font-size: 0.85rem; margin-top: 0.15rem; }

.waitlist-list { list-style: decimal; margin: 0.25rem 0 0; padding-left: 1.25rem; display: flex; flex-direction: column; gap: 0.6rem; }
.waitlist-list li { display: flex; justify-content: space-between; align-items: center; gap: 0.75rem; }
</style>
