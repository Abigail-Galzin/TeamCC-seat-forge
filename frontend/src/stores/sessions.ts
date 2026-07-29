import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { SessionFormData, WorkshopSession } from '@/types/session'

const mockSessions: WorkshopSession[] = [
  {
    id: 1,
    workshopId: 1,
    startsAt: '2026-08-15T10:00:00',
    endsAt: '2026-08-15T12:00:00',
    capacity: 30,
    status: 'scheduled',
    heldCount: 3,
    confirmedCount: 18,
    waitlistSize: 2,
  },
  {
    id: 2,
    workshopId: 1,
    startsAt: '2026-08-22T10:00:00',
    endsAt: '2026-08-22T12:00:00',
    capacity: 30,
    status: 'scheduled',
    heldCount: 1,
    confirmedCount: 25,
    waitlistSize: 5,
  },
  {
    id: 3,
    workshopId: 2,
    startsAt: '2026-09-05T14:00:00',
    endsAt: '2026-09-05T17:00:00',
    capacity: 20,
    status: 'scheduled',
    heldCount: 2,
    confirmedCount: 12,
    waitlistSize: 0,
  },
  {
    id: 4,
    workshopId: 2,
    startsAt: '2026-09-12T14:00:00',
    endsAt: '2026-09-12T17:00:00',
    capacity: 20,
    status: 'in_progress',
    heldCount: 0,
    confirmedCount: 20,
    waitlistSize: 8,
  },
  {
    id: 5,
    workshopId: 4,
    startsAt: '2026-08-10T09:00:00',
    endsAt: '2026-08-10T11:30:00',
    capacity: 25,
    status: 'completed',
    heldCount: 0,
    confirmedCount: 22,
    waitlistSize: 0,
  },
]

function toIsoString(date: Date): string {
  const pad = (value: number) => String(value).padStart(2, '0')

  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

export const useSessionsStore = defineStore('sessions', () => {
  const sessions = ref<WorkshopSession[]>([...mockSessions])
  let nextId = sessions.value.length + 1

  function getByWorkshopId(workshopId: number): WorkshopSession[] {
    return sessions.value.filter((session) => session.workshopId === workshopId)
  }

  function getById(id: number): WorkshopSession | undefined {
    return sessions.value.find((session) => session.id === id)
  }

  function create(workshopId: number, data: SessionFormData): WorkshopSession | null {
    if (!data.startsAt || !data.endsAt) return null

    const session: WorkshopSession = {
      id: nextId++,
      workshopId,
      startsAt: toIsoString(data.startsAt),
      endsAt: toIsoString(data.endsAt),
      capacity: data.capacity,
      status: data.status,
      heldCount: 0,
      confirmedCount: 0,
      waitlistSize: 0,
    }

    sessions.value = [...sessions.value, session]
    return session
  }

  function update(id: number, data: SessionFormData): WorkshopSession | null {
    const existing = getById(id)
    if (!existing || !data.startsAt || !data.endsAt) return null

    const updated: WorkshopSession = {
      ...existing,
      startsAt: toIsoString(data.startsAt),
      endsAt: toIsoString(data.endsAt),
      capacity: data.capacity,
      status: data.status,
    }

    sessions.value = sessions.value.map((session) => (session.id === id ? updated : session))
    return updated
  }

  function remove(id: number): boolean {
    const exists = sessions.value.some((session) => session.id === id)
    if (!exists) return false

    sessions.value = sessions.value.filter((session) => session.id !== id)
    return true
  }

  return {
    sessions,
    getByWorkshopId,
    getById,
    create,
    update,
    remove,
  }
})
