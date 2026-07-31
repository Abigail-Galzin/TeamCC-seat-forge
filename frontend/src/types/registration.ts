export interface Registration {
  id: number
  attendeeId: number
  sessionId: number
  status: 'held' | 'confirmed' | 'waitlisted' | 'cancelled' | 'expired'
  holdExpiresAt?: string
  confirmedAt?: string
  cancelledAt?: string
}

export interface RegistrationPayload {
  attendeeName: string
  attendeeEmail: string
  sessionId: number
}

export interface RegistrationApiRecord {
  id: number
  attendee_id: number
  session_id: number
  status: Registration['status']
  hold_expires_at: string | null
  confirmed_at: string | null
  cancelled_at: string | null
}

export interface RegistrationStatusCounts {
  held: number
  confirmed: number
  waitlisted: number
  cancelled: number
  expired: number
}
