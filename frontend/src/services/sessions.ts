import {
  sessionStore,
  registrationStore,
  attendeeStore,
  workshopStore,
  nextSessionId,
  paginateMock,
  getActiveRegistrationsForSession,
} from './mock-store'
import { apiClient, DEFAULT_PAGE_SIZE } from './api'
import type {
  Session,
  CreateSessionPayload,
  SessionListFilters,
  SessionListItem,
  SessionAttendee,
  SessionRegistrationApiRecord,
} from '../types/session'
import type { PaginatedResult, PaginationInfo } from '../types/pagination'
import type { Registration } from '../types/registration'

// Documented maximum page size for GET /api/v1/sessions, matches the backend contract.
export const MAX_SESSIONS_PER_PAGE = 50

export async function getSessionsForWorkshop(
  workshopId: number,
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
): Promise<PaginatedResult<Session>> {
  await Promise.resolve()
  const filtered = sessionStore.filter((session) => session.workshopId === workshopId)
  return paginateMock(filtered, page, perPage)
}

export async function getSessions(filters: SessionListFilters = {}): Promise<PaginatedResult<SessionListItem>> {
  await Promise.resolve()

  const page = filters.page ?? 1
  const perPage = Math.min(filters.perPage ?? DEFAULT_PAGE_SIZE, MAX_SESSIONS_PER_PAGE)

  let items: SessionListItem[] = sessionStore.map((session) => {
    const workshop = workshopStore.find((item) => item.id === session.workshopId)
    const active = getActiveRegistrationsForSession(session.id)
    const waitlistCount = registrationStore.filter(
      (registration) => registration.sessionId === session.id && registration.status === 'waitlisted',
    ).length

    return {
      ...session,
      workshopTitle: workshop?.title ?? 'Unknown workshop',
      topic: workshop?.topic ?? '',
      availableSeats: Math.max(0, session.capacity - active.length),
      heldCount: active.filter((registration) => registration.status === 'held').length,
      confirmedCount: active.filter((registration) => registration.status === 'confirmed').length,
      waitlistCount,
    }
  })

  if (filters.from) {
    const from = new Date(filters.from).getTime()
    items = items.filter((session) => new Date(session.startsAt).getTime() >= from)
  }

  if (filters.to) {
    const to = new Date(filters.to).getTime()
    items = items.filter((session) => new Date(session.startsAt).getTime() <= to)
  }

  if (filters.topic) {
    const topic = filters.topic.toLowerCase()
    items = items.filter((session) => session.topic.toLowerCase() === topic)
  }

  if (filters.available) {
    items = items.filter((session) => session.availableSeats > 0)
  }

  const sort = filters.sort ?? 'starts_at'
  items = [...items].sort((a, b) =>
    sort === 'available_seats'
      ? a.availableSeats - b.availableSeats
      : new Date(a.startsAt).getTime() - new Date(b.startsAt).getTime(),
  )

  return paginateMock(items, page, perPage)
}

export async function createSession(payload: CreateSessionPayload): Promise<Session> {
  const session: Session = {
    id: nextSessionId(),
    ...payload,
  }

  sessionStore.unshift(session)
  return session
}

export async function getSessionById(id: number): Promise<Session | undefined> {
  await Promise.resolve()
  return sessionStore.find((session) => session.id === id)
}

export async function getSessionAttendeeStatuses(
  sessionId: number,
): Promise<Array<{ name: string; email: string; status: Registration['status'] }>> {
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

/**
 * Loads the attendees registered for a session from the real Rails backend
 * (GET /api/v1/workshops/:workshop_id/sessions/:session_id/registrations), paginated.
 * per_page is capped server-side at the app-wide Pagy default (PAGY_DEFAULT_ITEMS).
 */
export async function getSessionAttendeesFromApi(
  workshopId: number,
  sessionId: number,
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
): Promise<PaginatedResult<SessionAttendee>> {
  const response = await apiClient.get<{
    message: string | null
    data: SessionRegistrationApiRecord[]
    status: string
    pagination: PaginationInfo
  }>(`/workshops/${workshopId}/sessions/${sessionId}/registrations`, {
    params: { page, per_page: perPage },
  })

  return {
    ...response.data,
    data: response.data.data.map((record) => ({
      attendeeId: record.attendee.id,
      name: record.attendee.name,
      email: record.attendee.email,
      status: record.status,
    })),
  }
}
