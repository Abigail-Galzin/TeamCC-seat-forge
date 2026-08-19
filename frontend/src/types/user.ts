export type UserRole = 'admin' | 'attendee'

export interface User {
  id: number
  name: string
  email: string
  role: UserRole
  attendeeId: number | null
}

export interface AuthSessionPayload {
  token: string
  user: User
}