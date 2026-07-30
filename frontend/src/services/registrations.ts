import { registrationStore, nextRegistrationId, getActiveRegistrationsForSession } from './mock-store'
import { getSessionById } from './sessions'
import { createAttendee, getAttendeeByEmail } from './attendees'
import type { Registration, RegistrationPayload } from '../types/registration'
import type { Attendee } from '../types/attendee'

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
    id: nextRegistrationId(),
    attendeeId: attendee.id,
    sessionId: session.id,
    status,
    holdExpiresAt: status === 'held' ? new Date(Date.now() + 10 * 60 * 1000).toISOString() : undefined,
  }

  registrationStore.unshift(registration)
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

export async function getRegistrationHistoryByEmail(
  email: string,
): Promise<{ attendee: Attendee; registrations: Registration[] } | undefined> {
  const attendee = await getAttendeeByEmail(email)
  if (!attendee) {
    return undefined
  }

  const registrations = await getRegistrationsForAttendee(attendee.id)
  return { attendee, registrations }
}
