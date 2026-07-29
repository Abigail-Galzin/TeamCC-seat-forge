export interface Attendee {
  id: number
  workshopId: number
  name: string
  email: string
}

export type AttendeeFormData = Omit<Attendee, 'id'>

export const emptyAttendeeForm = (): AttendeeFormData => ({
  name: '',
  email: '',
  workshopId: 0,
})

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())
}
