import { apiClient } from './api'

export interface Workshop {
  id: number
  title: string
  description: string
  topic: string
  active: boolean
}

export interface CreateWorkshopPayload {
  title: string
  description: string
  topic: string
  active: boolean
}

export interface Session {
  id: number
  workshopId: number
  startsAt: string
  endsAt: string
  capacity: number
  status: 'scheduled' | 'cancelled' | 'completed'
}

export interface CreateSessionPayload {
  workshopId: number
  startsAt: string
  endsAt: string
  capacity: number
  status: 'scheduled' | 'cancelled' | 'completed'
}

export interface Attendee {
  id: number
  name: string
  email: string
}

export interface Registration {
  id: number
  attendeeId: number
  sessionId: number
  status: 'held' | 'confirmed' | 'waitlisted' | 'cancelled' | 'expired'
  holdExpiresAt?: string
  confirmedAt?: string
  cancelledAt?: string
}

export interface RegistrationPayload {
  attendeeName: string
  attendeeEmail: string
  sessionId: number
}

export interface DashboardMetrics {
  upcomingSessions: number
  heldRegistrations: number
  confirmedRegistrations: number
  waitlistedRegistrations: number
  expiredHolds: number
  fullSessions: number
  topWaitlistedSessions: Array<{ id: number; title: string; waitlistSize: number }>
}

const mockWorkshops: Workshop[] = [
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

const mockSessions: Session[] = [
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

const mockAttendees: Attendee[] = [
  { id: 1, name: 'Ana García', email: 'ana@example.com' },
  { id: 2, name: 'Luis Pérez', email: 'luis@example.com' },
]

const mockRegistrations: Registration[] = [
  { id: 5001, attendeeId: 1, sessionId: 101, status: 'confirmed' },
  { id: 5002, attendeeId: 2, sessionId: 101, status: 'held' },
  { id: 5003, attendeeId: 2, sessionId: 102, status: 'waitlisted' },
]

let workshopStore: Workshop[] = [...mockWorkshops]
let sessionStore: Session[] = [...mockSessions]
let attendeeStore: Attendee[] = [...mockAttendees]
let registrationStore: Registration[] = [...mockRegistrations]

let nextWorkshopId = Math.max(...mockWorkshops.map((workshop) => workshop.id)) + 1
let nextSessionId = Math.max(...mockSessions.map((session) => session.id)) + 1
let nextAttendeeId = Math.max(...mockAttendees.map((attendee) => attendee.id)) + 1
let nextRegistrationId = Math.max(...mockRegistrations.map((registration) => registration.id)) + 1

function getActiveRegistrationsForSession(sessionId: number): Registration[] {
  return registrationStore.filter(
    (registration) => registration.sessionId === sessionId && ['held', 'confirmed'].includes(registration.status),
  )
}

export interface PaginatedResult<T> {
  items: T[]
  total: number
  page: number
  perPage: number
  totalPages: number
}

export async function getWorkshops(
  page = 1,
  perPage = 5,
  activeOnly = true,
): Promise<PaginatedResult<Workshop>> {
  await Promise.resolve()
  const filtered = activeOnly
    ? workshopStore.filter(
        (workshop) => workshop.active && sessionStore.some((session) => session.workshopId === workshop.id),
      )
    : workshopStore
  const total = filtered.length
  const start = (page - 1) * perPage
  const items = filtered.slice(start, start + perPage)
  return {
    items,
    total,
    page,
    perPage,
    totalPages: Math.max(1, Math.ceil(total / perPage)),
  }
}

export async function createWorkshop(payload: CreateWorkshopPayload): Promise<Workshop> {
  const workshop: Workshop = {
    id: nextWorkshopId++,
    ...payload,
  }

  workshopStore = [workshop, ...workshopStore]
  return workshop
}

export async function getWorkshopById(id: number): Promise<Workshop | undefined> {
  await Promise.resolve()
  return workshopStore.find((workshop) => workshop.id === id)
}

export async function updateWorkshop(id: number, payload: CreateWorkshopPayload): Promise<Workshop> {
  await Promise.resolve()
  const workshop = workshopStore.find((item) => item.id === id)
  if (!workshop) {
    throw new Error('Workshop not found')
  }

  Object.assign(workshop, payload)
  return workshop
}

export async function getSessionsForWorkshop(workshopId: number, page = 1, perPage = 5): Promise<PaginatedResult<Session>> {
  await Promise.resolve()
  const filtered = sessionStore.filter((session) => session.workshopId === workshopId)
  const total = filtered.length
  const start = (page - 1) * perPage
  const items = filtered.slice(start, start + perPage)
  return {
    items,
    total,
    page,
    perPage,
    totalPages: Math.max(1, Math.ceil(total / perPage)),
  }
}

export async function createSession(payload: CreateSessionPayload): Promise<Session> {
  const session: Session = {
    id: nextSessionId++,
    ...payload,
  }

  sessionStore = [session, ...sessionStore]
  return session
}

export async function getSessionById(id: number): Promise<Session | undefined> {
  await Promise.resolve()
  return sessionStore.find((session) => session.id === id)
}

export async function getSessionAttendeeStatuses(sessionId: number): Promise<Array<{ name: string; email: string; status: Registration['status'] }>> {
  await Promise.resolve()
  return registrationStore
    .filter((registration) => registration.sessionId === sessionId)
    .map((registration) => {
      const attendee = attendeeStore.find((item) => item.id === registration.attendeeId)
      return {
        name: attendee?.name ?? 'Unknown attendee',
        email: attendee?.email ?? 'unknown@example.com',
        status: registration.status,
      }
    })
}

export async function getAttendees(): Promise<Attendee[]> {
  await Promise.resolve()
  return [...attendeeStore]
}

export async function getAttendeeByEmail(email: string): Promise<Attendee | undefined> {
  await Promise.resolve()
  return attendeeStore.find((attendee) => attendee.email.toLowerCase() === email.toLowerCase())
}

export async function createAttendee(name: string, email: string): Promise<Attendee> {
  const existing = attendeeStore.find((attendee) => attendee.email.toLowerCase() === email.toLowerCase())
  if (existing) {
    return existing
  }

  const attendee: Attendee = {
    id: nextAttendeeId++,
    name,
    email,
  }

  attendeeStore = [attendee, ...attendeeStore]
  return attendee
}

export async function createRegistration(payload: RegistrationPayload): Promise<Registration> {
  const attendee = await createAttendee(payload.attendeeName, payload.attendeeEmail)

  const existingActive = registrationStore.some(
    (registration) =>
      registration.attendeeId === attendee.id &&
      registration.sessionId === payload.sessionId &&
      ['held', 'confirmed', 'waitlisted'].includes(registration.status),
  )

  if (existingActive) {
    throw new Error('The attendee already has an active registration for this session.')
  }

  const session = await getSessionById(payload.sessionId)
  if (!session) {
    throw new Error('Session not found')
  }

  const activeRegistrations = getActiveRegistrationsForSession(session.id)
  const status: Registration['status'] = activeRegistrations.length >= session.capacity ? 'waitlisted' : 'held'

  const registration: Registration = {
    id: nextRegistrationId++,
    attendeeId: attendee.id,
    sessionId: session.id,
    status,
    holdExpiresAt: status === 'held' ? new Date(Date.now() + 10 * 60 * 1000).toISOString() : undefined,
  }

  registrationStore = [registration, ...registrationStore]
  return registration
}

export async function confirmRegistration(registrationId: number): Promise<Registration> {
  const registration = registrationStore.find((item) => item.id === registrationId)
  if (!registration) {
    throw new Error('Registration not found')
  }

  registration.status = 'confirmed'
  registration.confirmedAt = new Date().toISOString()
  registration.holdExpiresAt = undefined
  return registration
}

export async function cancelRegistration(registrationId: number): Promise<Registration> {
  const registration = registrationStore.find((item) => item.id === registrationId)
  if (!registration) {
    throw new Error('Registration not found')
  }

  registration.status = 'cancelled'
  registration.cancelledAt = new Date().toISOString()
  registration.holdExpiresAt = undefined

  const waitlisted = registrationStore
    .filter((item) => item.sessionId === registration.sessionId && item.status === 'waitlisted')
    .sort((a, b) => a.id - b.id)

  const session = await getSessionById(registration.sessionId)
  const activeRegistrations = getActiveRegistrationsForSession(registration.sessionId)
  const needsPromotion = session && activeRegistrations.length < session.capacity && waitlisted.length > 0

  if (needsPromotion && session) {
    const next = waitlisted[0]
    if (next) {
      next.status = 'held'
      next.holdExpiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString()
    }
  }

  return registration
}

export async function getRegistrationsForAttendee(attendeeId: number): Promise<Registration[]> {
  await Promise.resolve()
  return registrationStore.filter((registration) => registration.attendeeId === attendeeId)
}

export async function getRegistrationHistoryByEmail(email: string): Promise<{ attendee: Attendee; registrations: Registration[] } | undefined> {
  const attendee = await getAttendeeByEmail(email)
  if (!attendee) {
    return undefined
  }

  const registrations = await getRegistrationsForAttendee(attendee.id)
  return { attendee, registrations }
}

export async function getDashboardMetrics(): Promise<DashboardMetrics> {
  await Promise.resolve()
  const upcomingSessions = sessionStore.filter((session) => session.status === 'scheduled').length
  const heldRegistrations = registrationStore.filter((registration) => registration.status === 'held').length
  const confirmedRegistrations = registrationStore.filter((registration) => registration.status === 'confirmed').length
  const waitlistedRegistrations = registrationStore.filter((registration) => registration.status === 'waitlisted').length
  const expiredHolds = registrationStore.filter((registration) => registration.status === 'expired').length
  const fullSessions = sessionStore.filter((session) => getActiveRegistrationsForSession(session.id).length >= session.capacity).length

  const topWaitlistedSessions = sessionStore
    .map((session) => ({
      id: session.id,
      title: workshopStore.find((workshop) => workshop.id === session.workshopId)?.title ?? 'Workshop',
      waitlistSize: registrationStore.filter((registration) => registration.sessionId === session.id && registration.status === 'waitlisted').length,
    }))
    .filter((entry) => entry.waitlistSize > 0)
    .sort((a, b) => b.waitlistSize - a.waitlistSize)
    .slice(0, 3)

  return {
    upcomingSessions,
    heldRegistrations,
    confirmedRegistrations,
    waitlistedRegistrations,
    expiredHolds,
    fullSessions,
    topWaitlistedSessions,
  }
}

export async function getWorkshopsFromApi(): Promise<Workshop[]> {
  const response = await apiClient.get<Workshop[]>('/workshops')
  return response.data
}
