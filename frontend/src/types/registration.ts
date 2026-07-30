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
