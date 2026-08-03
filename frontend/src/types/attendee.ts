import type { Registration, RegistrationStatusCounts } from './registration'
import type { PaginatedResult } from './pagination'

export interface Attendee {
  id: number
  name: string
  email: string
}

export interface AttendeeRegistrationSession {
  id: number
  startsAt: string
  endsAt: string
  capacity: number
  status: string
  workshop?: { id: number; title: string; topic: string }
}

export interface AttendeeRegistration {
  id: number
  status: Registration['status']
  holdExpiresAt?: string
  confirmedAt?: string
  cancelledAt?: string
  session?: AttendeeRegistrationSession
}

export interface AttendeeRegistrationApiRecord {
  id: number
  status: Registration['status']
  hold_expires_at: string | null
  confirmed_at: string | null
  cancelled_at: string | null
  session: {
    id: number
    starts_at: string
    ends_at: string
    capacity: number
    status: string
    workshop?: { id: number; title: string; topic: string }
  } | null
}

export interface AttendeeRegistrationsResult extends PaginatedResult<AttendeeRegistration> {
  statusCounts: RegistrationStatusCounts
}
