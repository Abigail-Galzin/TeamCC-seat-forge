import axios from 'axios'
import { apiClient, DEFAULT_PAGE_SIZE } from './api'
import type { Attendee, AttendeeRegistrationApiRecord, AttendeeRegistrationsResult } from '../types/attendee'
import type { ApiErrorBody } from '../types/api-error'
import type { PaginationInfo } from '../types/pagination'
import type { RegistrationStatusCounts } from '../types/registration'

/**
 * Finds an attendee by exact, case-insensitive email match (GET /api/v1/attendees?email=...).
 * Returns undefined when no attendee has that email.
 */
export async function getAttendeeByEmailFromApi(email: string): Promise<Attendee | undefined> {
  const response = await apiClient.get<{ data: Attendee[] }>('/attendees', { params: { email } })
  return response.data.data[0]
}

/**
 * Ensures an attendee exists in the real backend for this name/email
 * (POST /api/v1/attendees), so a subsequent registration lookup by email
 * succeeds. The registrations endpoint only searches for the attendee —
 * it never creates one — so callers must ensure the attendee exists first.
 * A duplicate-email conflict means the attendee already exists and is
 * treated as success; every other validation error is rethrown.
 */
export async function ensureAttendeeExistsInApi(name: string, email: string): Promise<void> {
  try {
    await apiClient.post('/attendees', { attendee: { name, email } })
  } catch (error) {
    if (axios.isAxiosError<ApiErrorBody>(error) && error.response?.status === 422) {
      const details = error.response.data?.error?.details ?? []
      const isDuplicateEmail = details.some(
        (detail) => typeof detail === 'string' && detail.toLowerCase().includes('email has already been taken'),
      )
      if (isDuplicateEmail) return
    }
    throw error
  }
}

/**
 * Loads a single attendee from the real backend (GET /api/v1/attendees/:id).
 * Returns undefined on a 404 so views can show a "not found" state.
 */
export async function getAttendeeByIdFromApi(id: number): Promise<Attendee | undefined> {
  try {
    const response = await apiClient.get<{ data: Attendee }>(`/attendees/${id}`)
    return response.data.data
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      return undefined
    }
    throw error
  }
}

/**
 * Loads a page of the sessions an attendee has registered for, from the real Rails backend
 * (GET /api/v1/attendees/:id/registrations), including session and workshop details, plus
 * real-time registration counts by status covering all of the attendee's registrations
 * (not just the current page).
 */
export async function getAttendeeRegistrationsFromApi(
  attendeeId: number,
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
): Promise<AttendeeRegistrationsResult> {
  const response = await apiClient.get<{
    message: string | null
    data: AttendeeRegistrationApiRecord[]
    status: string
    pagination: PaginationInfo
    status_counts: RegistrationStatusCounts
  }>(`/attendees/${attendeeId}/registrations`, { params: { page, per_page: perPage } })

  return {
    message: response.data.message,
    status: response.data.status,
    pagination: response.data.pagination,
    statusCounts: response.data.status_counts,
    data: response.data.data.map((record) => ({
      id: record.id,
      status: record.status,
      holdExpiresAt: record.hold_expires_at ?? undefined,
      confirmedAt: record.confirmed_at ?? undefined,
      cancelledAt: record.cancelled_at ?? undefined,
      session: record.session
        ? {
            id: record.session.id,
            startsAt: record.session.starts_at,
            endsAt: record.session.ends_at,
            capacity: record.session.capacity,
            status: record.session.status,
            workshop: record.session.workshop,
          }
        : undefined,
    })),
  }
}
