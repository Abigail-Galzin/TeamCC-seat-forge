import { ref } from 'vue'
import { defineStore } from 'pinia'
import type { Attendee, AttendeeFormData } from '@/types/attendee'

const mockAttendees: Attendee[] = [
  { id: 1, workshopId: 1, name: 'Ana García', email: 'ana.garcia@example.com' },
  { id: 2, workshopId: 1, name: 'Carlos Ruiz', email: 'carlos.ruiz@example.com' },
  { id: 3, workshopId: 1, name: 'María López', email: 'maria.lopez@example.com' },
  { id: 4, workshopId: 2, name: 'Pedro Sánchez', email: 'pedro.sanchez@example.com' },
  { id: 5, workshopId: 2, name: 'Laura Martín', email: 'laura.martin@example.com' },
  { id: 6, workshopId: 4, name: 'Diego Fernández', email: 'diego.fernandez@example.com' },
]

export const useAttendeesStore = defineStore('attendees', () => {
  const attendees = ref<Attendee[]>([...mockAttendees])
  let nextId = attendees.value.length + 1

  function getAll(): Attendee[] {
    return attendees.value
  }

  function getByWorkshopId(workshopId: number): Attendee[] {
    return attendees.value.filter((attendee) => attendee.workshopId === workshopId)
  }

  function create(data: AttendeeFormData): Attendee {
    const attendee: Attendee = {
      id: nextId++,
      workshopId: data.workshopId,
      name: data.name.trim(),
      email: data.email.trim().toLowerCase(),
    }
    attendees.value = [...attendees.value, attendee]
    return attendee
  }

  function update(id: number, data: AttendeeFormData): Attendee | null {
    const existing = attendees.value.find((attendee) => attendee.id === id)
    if (!existing) return null

    const updated: Attendee = {
      id,
      workshopId: data.workshopId,
      name: data.name.trim(),
      email: data.email.trim().toLowerCase(),
    }
    attendees.value = attendees.value.map((attendee) => (attendee.id === id ? updated : attendee))
    return updated
  }

  return { attendees, getAll, getByWorkshopId, create, update }
})
