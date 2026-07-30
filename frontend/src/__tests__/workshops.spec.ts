import { beforeEach, describe, expect, it, vi } from 'vitest'
import type * as WorkshopsService from '../services/workshops'
import type * as ApiService from '../services/api'

let workshops: typeof WorkshopsService
let api: typeof ApiService

beforeEach(async () => {
  vi.resetModules()
  workshops = await import('../services/workshops')
  api = await import('../services/api')
})

describe('getWorkshops', () => {
  it('returns only active workshops that have at least one session by default', async () => {
    const result = await workshops.getWorkshops()

    expect(result.items.map((w) => w.id)).toEqual([1, 2])
    expect(result.total).toBe(2)
    expect(result.totalPages).toBe(1)
  })

  it('includes inactive workshops when activeOnly is false', async () => {
    const result = await workshops.getWorkshops(1, 5, false)

    expect(result.items).toHaveLength(3)
    expect(result.total).toBe(3)
  })

  it('paginates results', async () => {
    const result = await workshops.getWorkshops(2, 1, false)

    expect(result.items).toHaveLength(1)
    expect(result.page).toBe(2)
    expect(result.perPage).toBe(1)
    expect(result.totalPages).toBe(3)
  })
})

describe('createWorkshop', () => {
  it('creates a workshop and prepends it to the list', async () => {
    const workshop = await workshops.createWorkshop({
      title: 'Testing Workshop',
      description: 'A test workshop',
      topic: 'Testing',
      active: true,
    })

    expect(workshop).toMatchObject({
      title: 'Testing Workshop',
      topic: 'Testing',
      active: true,
    })
    expect(workshop.id).toEqual(expect.any(Number))

    const all = await workshops.getWorkshops(1, 10, false)
    expect(all.items[0]).toEqual(workshop)
  })
})

describe('getWorkshopById', () => {
  it('returns the matching workshop', async () => {
    const workshop = await workshops.getWorkshopById(1)
    expect(workshop?.title).toBe('Rails APIs for Modern Teams')
  })

  it('returns undefined when not found', async () => {
    const workshop = await workshops.getWorkshopById(999999)
    expect(workshop).toBeUndefined()
  })
})

describe('updateWorkshop', () => {
  it('updates an existing workshop', async () => {
    const updated = await workshops.updateWorkshop(1, {
      title: 'Updated title',
      description: 'Updated description',
      topic: 'Updated',
      active: false,
    })

    expect(updated).toMatchObject({
      id: 1,
      title: 'Updated title',
      active: false,
    })
  })

  it('throws when the workshop does not exist', async () => {
    await expect(
      workshops.updateWorkshop(999999, {
        title: 'x',
        description: 'x',
        topic: 'x',
        active: true,
      }),
    ).rejects.toThrow('Workshop not found')
  })
})

describe('getSessionsForWorkshop', () => {
  it('returns sessions for the given workshop', async () => {
    const result = await workshops.getSessionsForWorkshop(1)

    expect(result.items).toHaveLength(2)
    expect(result.items.every((s) => s.workshopId === 1)).toBe(true)
  })

  it('paginates sessions', async () => {
    const result = await workshops.getSessionsForWorkshop(1, 1, 1)

    expect(result.items).toHaveLength(1)
    expect(result.totalPages).toBe(2)
  })
})

describe('createSession', () => {
  it('creates a session and makes it retrievable', async () => {
    const session = await workshops.createSession({
      workshopId: 2,
      startsAt: '2026-09-01T09:00:00.000Z',
      endsAt: '2026-09-01T11:00:00.000Z',
      capacity: 5,
      status: 'scheduled',
    })

    const found = await workshops.getSessionById(session.id)
    expect(found).toEqual(session)
  })
})

describe('getSessionById', () => {
  it('returns undefined for an unknown session', async () => {
    const session = await workshops.getSessionById(999999)
    expect(session).toBeUndefined()
  })
})

describe('getAttendees', () => {
  it('returns a copy of the attendee list', async () => {
    const attendees = await workshops.getAttendees()
    expect(attendees).toHaveLength(2)

    attendees.push({ id: 999, name: 'Injected', email: 'injected@example.com' })

    const attendeesAgain = await workshops.getAttendees()
    expect(attendeesAgain).toHaveLength(2)
  })
})

describe('getAttendeeByEmail', () => {
  it('finds an attendee case-insensitively', async () => {
    const attendee = await workshops.getAttendeeByEmail('ANA@EXAMPLE.COM')
    expect(attendee?.name).toBe('Ana García')
  })

  it('returns undefined when no attendee matches', async () => {
    const attendee = await workshops.getAttendeeByEmail('nobody@example.com')
    expect(attendee).toBeUndefined()
  })
})

describe('createAttendee', () => {
  it('creates a new attendee', async () => {
    const attendee = await workshops.createAttendee('New Person', 'new@example.com')
    expect(attendee).toMatchObject({ name: 'New Person', email: 'new@example.com' })

    const all = await workshops.getAttendees()
    expect(all).toHaveLength(3)
  })

  it('returns the existing attendee instead of duplicating', async () => {
    const attendee = await workshops.createAttendee('Ana Duplicate', 'ANA@example.com')
    expect(attendee.id).toBe(1)
    expect(attendee.name).toBe('Ana García')

    const all = await workshops.getAttendees()
    expect(all).toHaveLength(2)
  })
})

describe('getSessionAttendeeStatuses', () => {
  it('returns attendee info and status for each registration', async () => {
    const statuses = await workshops.getSessionAttendeeStatuses(101)

    expect(statuses).toEqual(
      expect.arrayContaining([
        { name: 'Ana García', email: 'ana@example.com', status: 'confirmed' },
        { name: 'Luis Pérez', email: 'luis@example.com', status: 'held' },
      ]),
    )
  })

  it('returns an empty list for a session with no registrations', async () => {
    const statuses = await workshops.getSessionAttendeeStatuses(103)
    expect(statuses).toEqual([])
  })
})

describe('createRegistration', () => {
  it('holds the registration when capacity is available', async () => {
    const registration = await workshops.createRegistration({
      attendeeName: 'New Attendee',
      attendeeEmail: 'new-attendee@example.com',
      sessionId: 103,
    })

    expect(registration.status).toBe('held')
    expect(registration.holdExpiresAt).toEqual(expect.any(String))
  })

  it('waitlists the registration when the session is full', async () => {
    await workshops.createRegistration({
      attendeeName: 'First Attendee',
      attendeeEmail: 'first@example.com',
      sessionId: 103,
    })

    const second = await workshops.createRegistration({
      attendeeName: 'Second Attendee',
      attendeeEmail: 'second@example.com',
      sessionId: 103,
    })

    expect(second.status).toBe('waitlisted')
    expect(second.holdExpiresAt).toBeUndefined()
  })

  it('throws when the attendee already has an active registration for the session', async () => {
    await expect(
      workshops.createRegistration({
        attendeeName: 'Ana García',
        attendeeEmail: 'ana@example.com',
        sessionId: 101,
      }),
    ).rejects.toThrow('The attendee already has an active registration for this session.')
  })

  it('throws when the session does not exist', async () => {
    await expect(
      workshops.createRegistration({
        attendeeName: 'Someone',
        attendeeEmail: 'someone@example.com',
        sessionId: 999999,
      }),
    ).rejects.toThrow('Session not found')
  })

  it('reuses an existing attendee instead of creating a duplicate', async () => {
    await workshops.createRegistration({
      attendeeName: 'Luis Pérez',
      attendeeEmail: 'luis@example.com',
      sessionId: 103,
    })

    const attendees = await workshops.getAttendees()
    expect(attendees).toHaveLength(2)
  })
})

describe('confirmRegistration', () => {
  it('confirms a held registration', async () => {
    const confirmed = await workshops.confirmRegistration(5002)

    expect(confirmed.status).toBe('confirmed')
    expect(confirmed.confirmedAt).toEqual(expect.any(String))
    expect(confirmed.holdExpiresAt).toBeUndefined()
  })

  it('throws when the registration does not exist', async () => {
    await expect(workshops.confirmRegistration(999999)).rejects.toThrow('Registration not found')
  })
})

describe('cancelRegistration', () => {
  it('cancels a registration', async () => {
    const cancelled = await workshops.cancelRegistration(5002)

    expect(cancelled.status).toBe('cancelled')
    expect(cancelled.cancelledAt).toEqual(expect.any(String))
    expect(cancelled.holdExpiresAt).toBeUndefined()
  })

  it('throws when the registration does not exist', async () => {
    await expect(workshops.cancelRegistration(999999)).rejects.toThrow('Registration not found')
  })

  it('promotes the earliest waitlisted registration when a slot frees up', async () => {
    const held = await workshops.createRegistration({
      attendeeName: 'Held Attendee',
      attendeeEmail: 'held@example.com',
      sessionId: 103,
    })
    const waitlisted = await workshops.createRegistration({
      attendeeName: 'Waitlisted Attendee',
      attendeeEmail: 'waitlisted@example.com',
      sessionId: 103,
    })
    expect(waitlisted.status).toBe('waitlisted')

    await workshops.cancelRegistration(held.id)

    const statuses = await workshops.getSessionAttendeeStatuses(103)
    const promoted = statuses.find((s) => s.email === 'waitlisted@example.com')
    expect(promoted?.status).toBe('held')
  })

  it('does not promote anyone when there is no waitlist', async () => {
    await workshops.cancelRegistration(5002)

    const statuses = await workshops.getSessionAttendeeStatuses(101)
    expect(statuses.find((s) => s.email === 'ana@example.com')?.status).toBe('confirmed')
    expect(statuses.some((s) => s.status === 'held')).toBe(false)
  })
})

describe('getRegistrationsForAttendee', () => {
  it('returns all registrations for an attendee', async () => {
    const registrations = await workshops.getRegistrationsForAttendee(2)
    expect(registrations).toHaveLength(2)
  })

  it('returns an empty list when the attendee has no registrations', async () => {
    const registrations = await workshops.getRegistrationsForAttendee(999999)
    expect(registrations).toEqual([])
  })
})

describe('getRegistrationHistoryByEmail', () => {
  it('returns the attendee and their registrations', async () => {
    const history = await workshops.getRegistrationHistoryByEmail('luis@example.com')

    expect(history?.attendee.name).toBe('Luis Pérez')
    expect(history?.registrations).toHaveLength(2)
  })

  it('returns undefined for an unknown email', async () => {
    const history = await workshops.getRegistrationHistoryByEmail('nobody@example.com')
    expect(history).toBeUndefined()
  })
})

describe('getDashboardMetrics', () => {
  it('computes metrics from the current state', async () => {
    const metrics = await workshops.getDashboardMetrics()

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
    await workshops.createRegistration({
      attendeeName: 'Filler',
      attendeeEmail: 'filler@example.com',
      sessionId: 103,
    })
    await workshops.createRegistration({
      attendeeName: 'Waitlisted 1',
      attendeeEmail: 'w1@example.com',
      sessionId: 103,
    })
    await workshops.createRegistration({
      attendeeName: 'Waitlisted 2',
      attendeeEmail: 'w2@example.com',
      sessionId: 103,
    })

    const metrics = await workshops.getDashboardMetrics()

    expect(metrics.fullSessions).toBe(1)
    expect(metrics.topWaitlistedSessions[0]).toMatchObject({ id: 103, waitlistSize: 2 })
    expect(metrics.topWaitlistedSessions.length).toBeLessThanOrEqual(3)
  })
})

describe('getWorkshopsFromApi', () => {
  it('fetches workshops from the backend API', async () => {
    const mockData = [{ id: 1, title: 'From API', description: '', topic: '', active: true }]
    vi.spyOn(api.apiClient, 'get').mockResolvedValue({ data: mockData })

    const result = await workshops.getWorkshopsFromApi()

    expect(result).toEqual(mockData)
    expect(api.apiClient.get).toHaveBeenCalledWith('/workshops')
  })
})
