import { sessionStore, registrationStore, attendeeStore, nextSessionId } from './mock-store'
import type { Session, CreateSessionPayload } from '../types/session'
import type { PaginatedResult } from '../types/pagination'
import type { Registration } from '../types/registration'

export async function getSessionsForWorkshop(
  workshopId: number,
  page = 1,
  perPage = 5,
): Promise<PaginatedResult<Session>> {
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
