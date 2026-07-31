import type { Registration } from './registration'

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

export type SessionSort = 'starts_at' | 'available_seats'

export interface SessionListFilters {
  from?: string
  to?: string
  topic?: string
  available?: boolean
  sort?: SessionSort
  page?: number
  perPage?: number
}

export interface SessionListItem extends Session {
  workshopTitle: string
  topic: string
  availableSeats: number
  heldCount: number
  confirmedCount: number
  waitlistCount: number
}

export interface SessionAttendee {
  attendeeId: number
  name: string
  email: string
  status: Registration['status']
}

export interface SessionRegistrationApiRecord {
  id: number
  status: Registration['status']
  attendee: { id: number; name: string; email: string } | null
}
