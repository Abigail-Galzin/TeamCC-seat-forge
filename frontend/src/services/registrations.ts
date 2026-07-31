import { getAttendeeByEmailFromApi, getAttendeeRegistrationsFromApi, ensureAttendeeExistsInApi } from './attendees'
import { apiClient, DEFAULT_PAGE_SIZE } from './api'
import type { Registration, RegistrationPayload, RegistrationApiRecord } from '../types/registration'
import type { Attendee, AttendeeRegistrationsResult } from '../types/attendee'

/**
 * Looks up an attendee by email (GET /api/v1/attendees?email=...) and loads a page of their
 * registration history (GET /api/v1/attendees/:id/registrations). Returns undefined when no
 * attendee has that email.
 */
export async function getRegistrationHistoryByEmail(
  email: string,
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
): Promise<(AttendeeRegistrationsResult & { attendee: Attendee }) | undefined> {
  const attendee = await getAttendeeByEmailFromApi(email)
  if (!attendee) {
    return undefined
  }

  const registrations = await getAttendeeRegistrationsFromApi(attendee.id, page, perPage)
  return { ...registrations, attendee }
}

function toRegistration(record: RegistrationApiRecord): Registration {
  return {
    id: record.id,
    attendeeId: record.attendee_id,
    sessionId: record.session_id,
    status: record.status,
    holdExpiresAt: record.hold_expires_at ?? undefined,
    confirmedAt: record.confirmed_at ?? undefined,
    cancelledAt: record.cancelled_at ?? undefined,
  }
}

/**
 * Reserves a seat against the real Rails backend
 * (POST /api/v1/workshops/:workshop_id/sessions/:session_id/registrations).
 * The registrations endpoint only looks up the attendee by email — it never creates
 * one — so this first ensures the attendee exists (POST /api/v1/attendees) before
 * registering. The backend is the source of truth for capacity, held-vs-waitlisted,
 * and conflict validation (duplicate/overlapping registration) — callers should
 * surface backend errors via getErrorMessage rather than a generic message.
 */
export async function reserveSeatFromApi(workshopId: number, payload: RegistrationPayload): Promise<Registration> {
  await ensureAttendeeExistsInApi(payload.attendeeName, payload.attendeeEmail)

  const response = await apiClient.post<{ data: RegistrationApiRecord }>(
    `/workshops/${workshopId}/sessions/${payload.sessionId}/registrations`,
    { attendee: { name: payload.attendeeName, email: payload.attendeeEmail } },
  )

  return toRegistration(response.data.data)
}
