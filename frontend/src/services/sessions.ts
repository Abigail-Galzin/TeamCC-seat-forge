import axios from 'axios'
import { apiClient, DEFAULT_PAGE_SIZE } from './api'
import type {
  Session,
  CreateSessionPayload,
  SessionListFilters,
  SessionListItem,
  SessionAttendee,
  SessionApiRecord,
  SessionListApiRecord,
  SessionRegistrationApiRecord,
  SessionCancellationApiRecord,
  SessionCancellationResult,
} from '../types/session'
import type { PaginatedResult, PaginationInfo } from '../types/pagination'

// GET /api/v1/sessions caps per_page at Pagy::DEFAULT[:items] (PAGY_DEFAULT_ITEMS) server-side.
export const MAX_SESSIONS_PER_PAGE = DEFAULT_PAGE_SIZE

function toSession(record: SessionApiRecord): Session {
  return {
    id: record.id,
    workshopId: record.workshop_id,
    startsAt: record.starts_at,
    endsAt: record.ends_at,
    capacity: record.capacity,
    status: record.status,
  }
}

function toSessionListItem(record: SessionListApiRecord): SessionListItem {
  return {
    ...toSession(record),
    workshopTitle: record.workshop_title,
    topic: record.topic,
    availableSeats: record.available_seats,
    heldCount: record.held_seats,
    confirmedCount: record.confirmed_seats,
    waitlistCount: record.waitlist_size,
  }
}

export async function getSessionsForWorkshop(
  workshopId: number,
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
): Promise<PaginatedResult<Session>> {
  const response = await apiClient.get<{
    message: string | null
    data: SessionApiRecord[]
    status: string
    pagination: PaginationInfo
  }>('/sessions', { params: { workshop_id: workshopId, page, per_page: perPage } })

  return { ...response.data, data: response.data.data.map(toSession) }
}

export async function getSessions(filters: SessionListFilters = {}): Promise<PaginatedResult<SessionListItem>> {
  const page = filters.page ?? 1
  const perPage = Math.min(filters.perPage ?? DEFAULT_PAGE_SIZE, MAX_SESSIONS_PER_PAGE)

  const response = await apiClient.get<{
    message: string | null
    data: SessionListApiRecord[]
    status: string
    pagination: PaginationInfo
  }>('/sessions', {
    params: {
      starts_after: filters.from,
      ends_before: filters.to,
      topic: filters.topic,
      available: filters.available || undefined,
      sort: filters.sort,
      page,
      per_page: perPage,
    },
  })

  return { ...response.data, data: response.data.data.map(toSessionListItem) }
}

export async function createSession(payload: CreateSessionPayload): Promise<Session> {
  const response = await apiClient.post<{ data: SessionApiRecord }>(`/workshops/${payload.workshopId}/sessions`, {
    session: {
      starts_at: payload.startsAt,
      ends_at: payload.endsAt,
      capacity: payload.capacity,
      status: payload.status,
    },
  })

  return toSession(response.data.data)
}

/**
 * Loads a single session from the real backend (GET /api/v1/sessions/:id).
 * Returns undefined on a 404 so views can show a "not found" state.
 */
export async function getSessionById(id: number): Promise<Session | undefined> {
  try {
    const response = await apiClient.get<{ data: SessionApiRecord }>(`/sessions/${id}`)
    return toSession(response.data.data)
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      return undefined
    }
    throw error
  }
}

/**
 * Cancels a session (POST /api/v1/sessions/:id/cancel), cascading the cancellation to every
 * held/confirmed/waitlisted registration for it. The backend requires a non-blank
 * cancellation_reason and returns how many registrations of each status were cancelled.
 */
export async function cancelSession(id: number, cancellationReason: string): Promise<SessionCancellationResult> {
  const response = await apiClient.post<{ data: SessionCancellationApiRecord }>(`/sessions/${id}/cancel`, {
    cancellation_reason: cancellationReason,
  })
  const data = response.data.data

  return {
    sessionId: data.session_id,
    status: data.status,
    cancellationReason: data.cancellation_reason,
    cancelledRegistrations: data.cancelled_registrations,
  }
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
      attendeeId: record.attendee?.id ?? 0,
      name: record.attendee?.name ?? 'Unknown attendee',
      email: record.attendee?.email ?? 'unknown@example.com',
      status: record.status,
    })),
  }
}
