import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import axios from 'axios'
import type * as WorkshopsService from '../services/workshops'
import type * as SessionsService from '../services/sessions'
import type * as AttendeesService from '../services/attendees'
import type * as RegistrationsService from '../services/registrations'
import type * as DashboardService from '../services/dashboard'
import type * as ApiService from '../services/api'

let workshops: typeof WorkshopsService
let sessions: typeof SessionsService
let attendees: typeof AttendeesService
let registrations: typeof RegistrationsService
let dashboard: typeof DashboardService
let api: typeof ApiService

beforeEach(async () => {
  vi.resetModules()
  workshops = await import('../services/workshops')
  sessions = await import('../services/sessions')
  attendees = await import('../services/attendees')
  registrations = await import('../services/registrations')
  dashboard = await import('../services/dashboard')
  api = await import('../services/api')
})

afterEach(() => {
  vi.restoreAllMocks()
})

describe('getWorkshops', () => {
  it('requests active workshops by default', async () => {
    const responseBody = {
      message: 'Workshops returned correctly',
      status: 'ok',
      data: [
        { id: 1, title: 'Rails APIs for Modern Teams', description: '', topic: 'Rails', active: true },
        { id: 2, title: 'Vue 3 Patterns for Product Teams', description: '', topic: 'Vue', active: true },
      ],
      pagination: { page: 1, pages: 1, count: 2, limit: 10, next: null, prev: null },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await workshops.getWorkshops()

    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops', { params: { active: true, page: 1, per_page: 10 } })
    expect(result).toEqual(responseBody)
  })

  it('omits the active filter when activeOnly is false', async () => {
    const responseBody = {
      message: null,
      status: 'ok',
      data: [],
      pagination: { page: 2, pages: 3, count: 3, limit: 1, next: 3, prev: 1 },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await workshops.getWorkshops(2, 1, false)

    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops', {
      params: { active: undefined, page: 2, per_page: 1 },
    })
    expect(result).toEqual(responseBody)
  })
})

describe('createWorkshop', () => {
  it('posts the payload and returns the created workshop', async () => {
    const payload = { title: 'Testing Workshop', description: 'A test workshop', topic: 'Testing', active: true }
    const created = { id: 9, ...payload }
    vi.spyOn(api.apiClient, 'post').mockResolvedValue({ data: { data: created } })

    const workshop = await workshops.createWorkshop(payload)

    expect(api.apiClient.post).toHaveBeenCalledWith('/workshops', { workshop: payload })
    expect(workshop).toEqual(created)
  })
})

describe('getWorkshopById', () => {
  it('returns the matching workshop', async () => {
    const workshop = { id: 1, title: 'Rails APIs for Modern Teams', description: '', topic: 'Rails', active: true }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: { data: workshop } })

    const result = await workshops.getWorkshopById(1)

    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops/1')
    expect(result).toEqual(workshop)
  })

  it('returns undefined when not found', async () => {
    const axiosError = Object.assign(new Error('Not Found'), { isAxiosError: true, response: { status: 404, data: {} } })
    vi.spyOn(api.apiClient, 'get').mockRejectedValue(axiosError)
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    const workshop = await workshops.getWorkshopById(999999)
    expect(workshop).toBeUndefined()
  })
})

describe('updateWorkshop', () => {
  it('patches the workshop and returns the updated record', async () => {
    const payload = { title: 'Updated title', description: 'Updated description', topic: 'Updated', active: false }
    const updated = { id: 1, ...payload }
    vi.spyOn(api.apiClient, 'patch').mockResolvedValue({ data: { data: updated } })

    const result = await workshops.updateWorkshop(1, payload)

    expect(api.apiClient.patch).toHaveBeenCalledWith('/workshops/1', { workshop: payload })
    expect(result).toEqual(updated)
  })

  it('propagates backend errors', async () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: { status: 422, data: { error: { code: 'update_conflict', message: 'Could not update.', details: [] } } },
    })
    vi.spyOn(api.apiClient, 'patch').mockRejectedValue(axiosError)

    await expect(
      workshops.updateWorkshop(999999, { title: 'x', description: 'x', topic: 'x', active: true }),
    ).rejects.toBe(axiosError)
  })
})

describe('getWorkshopTopics', () => {
  it('returns the sorted, de-duplicated list of topics across all workshops', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: {
        data: [
          { id: 1, title: 'A', description: '', topic: 'Vue', active: true },
          { id: 2, title: 'B', description: '', topic: 'Rails', active: true },
          { id: 3, title: 'C', description: '', topic: 'Vue', active: false },
        ],
      },
    })

    const topics = await workshops.getWorkshopTopics()

    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops', { params: { per_page: 10 } })
    expect(topics).toEqual(['Rails', 'Vue'])
  })
})

describe('getSessionsForWorkshop', () => {
  it('fetches sessions filtered by workshop id and maps them from snake_case', async () => {
    const responseBody = {
      message: null,
      status: 'ok',
      data: [
        {
          id: 101,
          workshop_id: 1,
          workshop_title: 'Rails APIs for Modern Teams',
          starts_at: '2026-08-01T09:00:00.000Z',
          ends_at: '2026-08-01T11:00:00.000Z',
          capacity: 3,
          status: 'scheduled',
        },
      ],
      pagination: { page: 1, pages: 1, count: 1, limit: 10, next: null, prev: null },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await sessions.getSessionsForWorkshop(1)

    expect(api.apiClient.get).toHaveBeenCalledWith('/sessions', { params: { workshop_id: 1, page: 1, per_page: 10 } })
    expect(result.data).toEqual([
      {
        id: 101,
        workshopId: 1,
        startsAt: '2026-08-01T09:00:00.000Z',
        endsAt: '2026-08-01T11:00:00.000Z',
        capacity: 3,
        status: 'scheduled',
      },
    ])
  })

  it('paginates sessions', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: { message: null, status: 'ok', data: [], pagination: { page: 1, pages: 2, count: 2, limit: 1, next: 2, prev: null } },
    })

    const result = await sessions.getSessionsForWorkshop(1, 1, 1)

    expect(api.apiClient.get).toHaveBeenCalledWith('/sessions', { params: { workshop_id: 1, page: 1, per_page: 1 } })
    expect(result.pagination.pages).toBe(2)
  })
})

describe('getSessions', () => {
  it('maps filters to backend query params and session list items', async () => {
    const responseBody = {
      message: null,
      status: 'ok',
      data: [
        {
          id: 101,
          workshop_id: 1,
          workshop_title: 'Rails APIs for Modern Teams',
          topic: 'Rails',
          starts_at: '2026-08-01T09:00:00.000Z',
          ends_at: '2026-08-01T11:00:00.000Z',
          capacity: 3,
          status: 'scheduled',
          held_seats: 1,
          confirmed_seats: 1,
          waitlist_size: 0,
          available_seats: 1,
        },
      ],
      pagination: { page: 1, pages: 1, count: 1, limit: 10, next: null, prev: null },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await sessions.getSessions({
      from: '2026-08-01T00:00:00.000Z',
      topic: 'Rails',
      available: true,
      sort: 'available_seats',
      page: 1,
      perPage: 10,
    })

    expect(api.apiClient.get).toHaveBeenCalledWith('/sessions', {
      params: {
        starts_after: '2026-08-01T00:00:00.000Z',
        ends_before: undefined,
        topic: 'Rails',
        available: true,
        sort: 'available_seats',
        page: 1,
        per_page: 10,
      },
    })
    expect(result.data).toEqual([
      {
        id: 101,
        workshopId: 1,
        workshopTitle: 'Rails APIs for Modern Teams',
        topic: 'Rails',
        startsAt: '2026-08-01T09:00:00.000Z',
        endsAt: '2026-08-01T11:00:00.000Z',
        capacity: 3,
        status: 'scheduled',
        availableSeats: 1,
        heldCount: 1,
        confirmedCount: 1,
        waitlistCount: 0,
      },
    ])
  })

  it('caps perPage at MAX_SESSIONS_PER_PAGE', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: { message: null, status: 'ok', data: [], pagination: { page: 1, pages: 1, count: 0, limit: 50, next: null, prev: null } },
    })

    await sessions.getSessions({ perPage: 500 })

    expect(api.apiClient.get).toHaveBeenCalledWith(
      '/sessions',
      expect.objectContaining({ params: expect.objectContaining({ per_page: sessions.MAX_SESSIONS_PER_PAGE }) }),
    )
  })
})

describe('createSession', () => {
  it('posts the session under the workshop and returns the mapped session', async () => {
    const created = {
      id: 201,
      workshop_id: 2,
      workshop_title: 'Vue 3 Patterns for Product Teams',
      starts_at: '2026-09-01T09:00:00.000Z',
      ends_at: '2026-09-01T11:00:00.000Z',
      capacity: 5,
      status: 'scheduled',
    }
    vi.spyOn(api.apiClient, 'post').mockResolvedValue({ data: { data: created } })

    const session = await sessions.createSession({
      workshopId: 2,
      startsAt: '2026-09-01T09:00:00.000Z',
      endsAt: '2026-09-01T11:00:00.000Z',
      capacity: 5,
      status: 'scheduled',
    })

    expect(api.apiClient.post).toHaveBeenCalledWith('/workshops/2/sessions', {
      session: {
        starts_at: '2026-09-01T09:00:00.000Z',
        ends_at: '2026-09-01T11:00:00.000Z',
        capacity: 5,
        status: 'scheduled',
      },
    })
    expect(session).toEqual({
      id: 201,
      workshopId: 2,
      startsAt: '2026-09-01T09:00:00.000Z',
      endsAt: '2026-09-01T11:00:00.000Z',
      capacity: 5,
      status: 'scheduled',
    })
  })
})

describe('getSessionById', () => {
  it('returns the mapped session', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: {
        data: {
          id: 101,
          workshop_id: 1,
          workshop_title: 'Rails APIs for Modern Teams',
          starts_at: '2026-08-01T09:00:00.000Z',
          ends_at: '2026-08-01T11:00:00.000Z',
          capacity: 3,
          status: 'scheduled',
        },
      },
    })

    const session = await sessions.getSessionById(101)

    expect(api.apiClient.get).toHaveBeenCalledWith('/sessions/101')
    expect(session).toEqual({
      id: 101,
      workshopId: 1,
      startsAt: '2026-08-01T09:00:00.000Z',
      endsAt: '2026-08-01T11:00:00.000Z',
      capacity: 3,
      status: 'scheduled',
    })
  })

  it('returns undefined for an unknown session', async () => {
    const axiosError = Object.assign(new Error('Not Found'), { isAxiosError: true, response: { status: 404, data: {} } })
    vi.spyOn(api.apiClient, 'get').mockRejectedValue(axiosError)
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    const session = await sessions.getSessionById(999999)
    expect(session).toBeUndefined()
  })
})

describe('getAttendeeByEmailFromApi', () => {
  it('returns the first matching attendee', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: { data: [{ id: 1, name: 'Ana García', email: 'ana@example.com' }] },
    })

    const attendee = await attendees.getAttendeeByEmailFromApi('ANA@example.com')

    expect(api.apiClient.get).toHaveBeenCalledWith('/attendees', { params: { email: 'ANA@example.com' } })
    expect(attendee).toEqual({ id: 1, name: 'Ana García', email: 'ana@example.com' })
  })

  it('returns undefined when no attendee matches', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: { data: [] } })

    const attendee = await attendees.getAttendeeByEmailFromApi('nobody@example.com')

    expect(attendee).toBeUndefined()
  })
})

describe('getAttendeeByIdFromApi', () => {
  it('returns the attendee', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: { data: { id: 7, name: 'Ana García', email: 'ana@example.com' } },
    })

    const result = await attendees.getAttendeeByIdFromApi(7)

    expect(api.apiClient.get).toHaveBeenCalledWith('/attendees/7')
    expect(result).toEqual({ id: 7, name: 'Ana García', email: 'ana@example.com' })
  })

  it('returns undefined on a 404', async () => {
    const axiosError = Object.assign(new Error('Not Found'), { isAxiosError: true, response: { status: 404, data: {} } })
    vi.spyOn(api.apiClient, 'get').mockRejectedValue(axiosError)
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    const result = await attendees.getAttendeeByIdFromApi(999999)

    expect(result).toBeUndefined()
  })

  it('re-throws non-404 errors', async () => {
    const axiosError = Object.assign(new Error('Server error'), { isAxiosError: true, response: { status: 500, data: {} } })
    vi.spyOn(api.apiClient, 'get').mockRejectedValue(axiosError)
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    await expect(attendees.getAttendeeByIdFromApi(7)).rejects.toBe(axiosError)
  })
})

describe('getAttendeeRegistrationsFromApi', () => {
  it('fetches a page of the attendee\'s registrations and maps session/workshop details', async () => {
    const responseBody = {
      message: 'Registrations returned correctly',
      status: 'ok',
      data: [
        {
          id: 42,
          status: 'confirmed',
          hold_expires_at: null,
          confirmed_at: '2026-07-29T10:00:00.000Z',
          cancelled_at: null,
          session: {
            id: 101,
            starts_at: '2026-08-01T09:00:00.000Z',
            ends_at: '2026-08-01T11:00:00.000Z',
            capacity: 5,
            status: 'scheduled',
            workshop: { id: 1, title: 'Rails APIs for Modern Teams', topic: 'Rails' },
          },
        },
      ],
      pagination: { page: 1, pages: 1, count: 1, limit: 10, next: null, prev: null },
      status_counts: { held: 0, confirmed: 1, waitlisted: 0, cancelled: 0, expired: 0 },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await attendees.getAttendeeRegistrationsFromApi(7)

    expect(api.apiClient.get).toHaveBeenCalledWith('/attendees/7/registrations', { params: { page: 1, per_page: 10 } })
    expect(result.data).toEqual([
      {
        id: 42,
        status: 'confirmed',
        holdExpiresAt: undefined,
        confirmedAt: '2026-07-29T10:00:00.000Z',
        cancelledAt: undefined,
        session: {
          id: 101,
          startsAt: '2026-08-01T09:00:00.000Z',
          endsAt: '2026-08-01T11:00:00.000Z',
          capacity: 5,
          status: 'scheduled',
          workshop: { id: 1, title: 'Rails APIs for Modern Teams', topic: 'Rails' },
        },
      },
    ])
    expect(result.pagination).toEqual(responseBody.pagination)
    expect(result.statusCounts).toEqual({ held: 0, confirmed: 1, waitlisted: 0, cancelled: 0, expired: 0 })
  })

  it('handles a missing session gracefully', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: {
        message: null,
        status: 'ok',
        data: [{ id: 1, status: 'cancelled', hold_expires_at: null, confirmed_at: null, cancelled_at: null, session: null }],
        pagination: { page: 1, pages: 1, count: 1, limit: 10, next: null, prev: null },
        status_counts: { held: 0, confirmed: 0, waitlisted: 0, cancelled: 1, expired: 0 },
      },
    })

    const result = await attendees.getAttendeeRegistrationsFromApi(7)

    expect(result.data).toEqual([{ id: 1, status: 'cancelled', holdExpiresAt: undefined, confirmedAt: undefined, cancelledAt: undefined, session: undefined }])
    expect(result.statusCounts).toEqual({ held: 0, confirmed: 0, waitlisted: 0, cancelled: 1, expired: 0 })
  })
})

describe('getSessionAttendeeStatuses', () => {
  it('returns attendee info and status for each registration', async () => {
    const statuses = await sessions.getSessionAttendeeStatuses(101)

    expect(statuses).toEqual(
      expect.arrayContaining([
        { name: 'Ana García', email: 'ana@example.com', status: 'confirmed' },
        { name: 'Luis Pérez', email: 'luis@example.com', status: 'held' },
      ]),
    )
  })

  it('returns an empty list for a session with no registrations', async () => {
    const statuses = await sessions.getSessionAttendeeStatuses(103)
    expect(statuses).toEqual([])
  })
})

describe('getSessionAttendeesFromApi', () => {
  it('fetches a page of attendees from the backend and maps attendee details', async () => {
    const responseBody = {
      message: 'Registrations returned correctly',
      status: 'ok',
      data: [
        { id: 1, status: 'confirmed', attendee: { id: 1, name: 'Ana García', email: 'ana@example.com' } },
        { id: 2, status: 'held', attendee: { id: 2, name: 'Luis Pérez', email: 'luis@example.com' } },
      ],
      pagination: { page: 1, pages: 2, count: 12, limit: 10, next: 2, prev: null },
    }
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: responseBody })

    const result = await sessions.getSessionAttendeesFromApi(1, 101, 1, 10)

    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops/1/sessions/101/registrations', {
      params: { page: 1, per_page: 10 },
    })
    expect(result.data).toEqual([
      { attendeeId: 1, name: 'Ana García', email: 'ana@example.com', status: 'confirmed' },
      { attendeeId: 2, name: 'Luis Pérez', email: 'luis@example.com', status: 'held' },
    ])
    expect(result.pagination).toEqual(responseBody.pagination)
  })

  it('falls back to placeholder attendee details when the attendee is missing', async () => {
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({
      data: {
        message: null,
        status: 'ok',
        data: [{ id: 1, status: 'cancelled', attendee: null }],
        pagination: { page: 1, pages: 1, count: 1, limit: 10, next: null, prev: null },
      },
    })

    const result = await sessions.getSessionAttendeesFromApi(1, 101)

    expect(result.data).toEqual([
      { attendeeId: 0, name: 'Unknown attendee', email: 'unknown@example.com', status: 'cancelled' },
    ])
  })
})

describe('createRegistration', () => {
  it('holds the registration when capacity is available', async () => {
    const registration = await registrations.createRegistration({
      attendeeName: 'New Attendee',
      attendeeEmail: 'new-attendee@example.com',
      sessionId: 103,
    })

    expect(registration.status).toBe('held')
    expect(registration.holdExpiresAt).toEqual(expect.any(String))
  })

  it('waitlists the registration when the session is full', async () => {
    await registrations.createRegistration({
      attendeeName: 'First Attendee',
      attendeeEmail: 'first@example.com',
      sessionId: 103,
    })

    const second = await registrations.createRegistration({
      attendeeName: 'Second Attendee',
      attendeeEmail: 'second@example.com',
      sessionId: 103,
    })

    expect(second.status).toBe('waitlisted')
    expect(second.holdExpiresAt).toBeUndefined()
  })

  it('throws when the attendee already has an active registration for the session', async () => {
    await expect(
      registrations.createRegistration({
        attendeeName: 'Ana García',
        attendeeEmail: 'ana@example.com',
        sessionId: 101,
      }),
    ).rejects.toThrow('The attendee already has an active registration for this session.')
  })

  it('throws when the session does not exist', async () => {
    await expect(
      registrations.createRegistration({
        attendeeName: 'Someone',
        attendeeEmail: 'someone@example.com',
        sessionId: 999999,
      }),
    ).rejects.toThrow('Session not found')
  })

  it('reuses an existing attendee instead of creating a duplicate', async () => {
    await registrations.createRegistration({
      attendeeName: 'Luis Pérez',
      attendeeEmail: 'luis@example.com',
      sessionId: 103,
    })

    const all = await attendees.getAttendees()
    expect(all).toHaveLength(2)
  })
})

describe('confirmRegistration', () => {
  it('confirms a held registration', async () => {
    const confirmed = await registrations.confirmRegistration(5002)

    expect(confirmed.status).toBe('confirmed')
    expect(confirmed.confirmedAt).toEqual(expect.any(String))
    expect(confirmed.holdExpiresAt).toBeUndefined()
  })

  it('throws when the registration does not exist', async () => {
    await expect(registrations.confirmRegistration(999999)).rejects.toThrow('Registration not found')
  })
})

describe('cancelRegistration', () => {
  it('cancels a registration', async () => {
    const cancelled = await registrations.cancelRegistration(5002)

    expect(cancelled.status).toBe('cancelled')
    expect(cancelled.cancelledAt).toEqual(expect.any(String))
    expect(cancelled.holdExpiresAt).toBeUndefined()
  })

  it('throws when the registration does not exist', async () => {
    await expect(registrations.cancelRegistration(999999)).rejects.toThrow('Registration not found')
  })

  it('promotes the earliest waitlisted registration when a slot frees up', async () => {
    const held = await registrations.createRegistration({
      attendeeName: 'Held Attendee',
      attendeeEmail: 'held@example.com',
      sessionId: 103,
    })
    const waitlisted = await registrations.createRegistration({
      attendeeName: 'Waitlisted Attendee',
      attendeeEmail: 'waitlisted@example.com',
      sessionId: 103,
    })
    expect(waitlisted.status).toBe('waitlisted')

    await registrations.cancelRegistration(held.id)

    const statuses = await sessions.getSessionAttendeeStatuses(103)
    const promoted = statuses.find((s) => s.email === 'waitlisted@example.com')
    expect(promoted?.status).toBe('held')
  })

  it('does not promote anyone when there is no waitlist', async () => {
    await registrations.cancelRegistration(5002)

    const statuses = await sessions.getSessionAttendeeStatuses(101)
    expect(statuses.find((s) => s.email === 'ana@example.com')?.status).toBe('confirmed')
    expect(statuses.some((s) => s.status === 'held')).toBe(false)
  })
})

describe('getRegistrationsForAttendee', () => {
  it('returns all registrations for an attendee', async () => {
    const result = await registrations.getRegistrationsForAttendee(2)
    expect(result).toHaveLength(2)
  })

  it('returns an empty list when the attendee has no registrations', async () => {
    const result = await registrations.getRegistrationsForAttendee(999999)
    expect(result).toEqual([])
  })
})

describe('getRegistrationHistoryByEmail', () => {
  it('returns the attendee and their registrations', async () => {
    const history = await registrations.getRegistrationHistoryByEmail('luis@example.com')

    expect(history?.attendee.name).toBe('Luis Pérez')
    expect(history?.registrations).toHaveLength(2)
  })

  it('returns undefined for an unknown email', async () => {
    const history = await registrations.getRegistrationHistoryByEmail('nobody@example.com')
    expect(history).toBeUndefined()
  })
})

describe('reserveSeatFromApi', () => {
  it('ensures the attendee exists, then posts the attendee identity under the workshop/session and maps the created registration', async () => {
    const registrationRecord = {
      id: 55,
      attendee_id: 9,
      session_id: 101,
      status: 'held',
      hold_expires_at: '2026-07-29T18:10:00.000Z',
      confirmed_at: null,
      cancelled_at: null,
    }
    vi.spyOn(api.apiClient, 'post').mockImplementation((url) => {
      if (url === '/attendees') return Promise.resolve({ data: { data: { id: 9 } } })
      return Promise.resolve({ data: { data: registrationRecord } })
    })

    const result = await registrations.reserveSeatFromApi(1, {
      attendeeName: 'New Attendee',
      attendeeEmail: 'new-attendee@example.com',
      sessionId: 101,
    })

    expect(api.apiClient.post).toHaveBeenCalledWith('/attendees', {
      attendee: { name: 'New Attendee', email: 'new-attendee@example.com' },
    })
    expect(api.apiClient.post).toHaveBeenCalledWith('/workshops/1/sessions/101/registrations', {
      attendee: { name: 'New Attendee', email: 'new-attendee@example.com' },
    })
    expect(result).toEqual({
      id: 55,
      attendeeId: 9,
      sessionId: 101,
      status: 'held',
      holdExpiresAt: '2026-07-29T18:10:00.000Z',
      confirmedAt: undefined,
      cancelledAt: undefined,
    })
  })

  it('treats a duplicate-email conflict from attendee creation as success and still registers', async () => {
    const duplicateEmailError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: {
        status: 422,
        data: { error: { code: 'creation_conflict', message: 'Could not create.', details: ['Email has already been taken'] } },
      },
    })
    const registrationRecord = {
      id: 56,
      attendee_id: 3,
      session_id: 101,
      status: 'held',
      hold_expires_at: '2026-07-29T18:10:00.000Z',
      confirmed_at: null,
      cancelled_at: null,
    }
    vi.spyOn(api.apiClient, 'post').mockImplementation((url) => {
      if (url === '/attendees') return Promise.reject(duplicateEmailError)
      return Promise.resolve({ data: { data: registrationRecord } })
    })

    const result = await registrations.reserveSeatFromApi(1, {
      attendeeName: 'Existing Person',
      attendeeEmail: 'existing@example.com',
      sessionId: 101,
    })

    expect(result.id).toBe(56)
  })

  it('propagates a genuine attendee validation error without attempting to register', async () => {
    const validationError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: {
        status: 422,
        data: { error: { code: 'creation_conflict', message: 'Could not create.', details: ['Email is invalid'] } },
      },
    })
    vi.spyOn(api.apiClient, 'post').mockRejectedValue(validationError)

    await expect(
      registrations.reserveSeatFromApi(1, {
        attendeeName: 'A',
        attendeeEmail: 'not-an-email',
        sessionId: 101,
      }),
    ).rejects.toBe(validationError)

    expect(api.apiClient.post).toHaveBeenCalledTimes(1)
  })

  it('propagates backend conflicts from registration as axios errors', async () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: {
        status: 422,
        data: { error: { code: 'creation_conflict', message: 'Already registered.', details: [] } },
      },
    })
    vi.spyOn(api.apiClient, 'post').mockImplementation((url) => {
      if (url === '/attendees') return Promise.resolve({ data: { data: { id: 1 } } })
      return Promise.reject(axiosError)
    })

    await expect(
      registrations.reserveSeatFromApi(1, {
        attendeeName: 'Ana García',
        attendeeEmail: 'ana@example.com',
        sessionId: 101,
      }),
    ).rejects.toBe(axiosError)
  })
})

describe('getDashboardMetrics', () => {
  it('computes metrics from the current state', async () => {
    const metrics = await dashboard.getDashboardMetrics()

    expect(metrics).toMatchObject({
      upcomingSessions: 3,
      heldRegistrations: 1,
      confirmedRegistrations: 1,
      waitlistedRegistrations: 1,
      expiredHolds: 0,
      fullSessions: 0,
    })
    expect(metrics.topWaitlistedSessions).toEqual([
      { id: 102, title: 'Rails APIs for Modern Teams', waitlistSize: 1 },
    ])
  })

  it('reflects newly full sessions and re-sorts waitlisted sessions by size', async () => {
    await registrations.createRegistration({
      attendeeName: 'Filler',
      attendeeEmail: 'filler@example.com',
      sessionId: 103,
    })
    await registrations.createRegistration({
      attendeeName: 'Waitlisted 1',
      attendeeEmail: 'w1@example.com',
      sessionId: 103,
    })
    await registrations.createRegistration({
      attendeeName: 'Waitlisted 2',
      attendeeEmail: 'w2@example.com',
      sessionId: 103,
    })

    const metrics = await dashboard.getDashboardMetrics()

    expect(metrics.fullSessions).toBe(1)
    expect(metrics.topWaitlistedSessions[0]).toMatchObject({ id: 103, waitlistSize: 2 })
    expect(metrics.topWaitlistedSessions.length).toBeLessThanOrEqual(3)
  })
})

