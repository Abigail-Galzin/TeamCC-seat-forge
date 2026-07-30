import type { Workshop } from '../types/workshop'
import type { Session } from '../types/session'
import type { Attendee } from '../types/attendee'
import type { Registration } from '../types/registration'

const initialWorkshops: Workshop[] = [
  {
    id: 1,
    title: 'Rails APIs for Modern Teams',
    description: 'Learn how to build robust JSON APIs with Rails.',
    topic: 'Rails',
    active: true,
  },
  {
    id: 2,
    title: 'Vue 3 Patterns for Product Teams',
    description: 'Build maintainable Vue applications with composables.',
    topic: 'Vue',
    active: true,
  },
  {
    id: 3,
    title: 'Designing for Reliable Systems',
    description: 'Explore the tradeoffs in resilient architecture.',
    topic: 'Architecture',
    active: false,
  },
]

const initialSessions: Session[] = [
  {
    id: 101,
    workshopId: 1,
    startsAt: '2026-08-01T09:00:00.000Z',
    endsAt: '2026-08-01T11:00:00.000Z',
    capacity: 3,
    status: 'scheduled',
  },
  {
    id: 102,
    workshopId: 1,
    startsAt: '2026-08-02T15:00:00.000Z',
    endsAt: '2026-08-02T17:00:00.000Z',
    capacity: 2,
    status: 'scheduled',
  },
  {
    id: 103,
    workshopId: 2,
    startsAt: '2026-08-03T18:00:00.000Z',
    endsAt: '2026-08-03T20:00:00.000Z',
    capacity: 1,
    status: 'scheduled',
  },
]

const initialAttendees: Attendee[] = [
  { id: 1, name: 'Ana García', email: 'ana@example.com' },
  { id: 2, name: 'Luis Pérez', email: 'luis@example.com' },
]

const initialRegistrations: Registration[] = [
  { id: 5001, attendeeId: 1, sessionId: 101, status: 'confirmed' },
  { id: 5002, attendeeId: 2, sessionId: 101, status: 'held' },
  { id: 5003, attendeeId: 2, sessionId: 102, status: 'waitlisted' },
]

export const workshopStore: Workshop[] = [...initialWorkshops]
export const sessionStore: Session[] = [...initialSessions]
export const attendeeStore: Attendee[] = [...initialAttendees]
export const registrationStore: Registration[] = [...initialRegistrations]

let workshopIdCounter = Math.max(...initialWorkshops.map((workshop) => workshop.id)) + 1
let sessionIdCounter = Math.max(...initialSessions.map((session) => session.id)) + 1
let attendeeIdCounter = Math.max(...initialAttendees.map((attendee) => attendee.id)) + 1
let registrationIdCounter = Math.max(...initialRegistrations.map((registration) => registration.id)) + 1

export function nextWorkshopId(): number {
  return workshopIdCounter++
}

export function nextSessionId(): number {
  return sessionIdCounter++
}

export function nextAttendeeId(): number {
  return attendeeIdCounter++
}

export function nextRegistrationId(): number {
  return registrationIdCounter++
}

export function getActiveRegistrationsForSession(sessionId: number): Registration[] {
  return registrationStore.filter(
    (registration) => registration.sessionId === sessionId && ['held', 'confirmed'].includes(registration.status),
  )
}
