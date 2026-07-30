import { attendeeStore, nextAttendeeId } from './mock-store'
import type { Attendee } from '../types/attendee'

export async function getAttendees(): Promise<Attendee[]> {
  await Promise.resolve()
  return [...attendeeStore]
}

export async function getAttendeeByEmail(email: string): Promise<Attendee | undefined> {
  await Promise.resolve()
  return attendeeStore.find((attendee) => attendee.email.toLowerCase() === email.toLowerCase())
}

export async function createAttendee(name: string, email: string): Promise<Attendee> {
  const existing = attendeeStore.find((attendee) => attendee.email.toLowerCase() === email.toLowerCase())
  if (existing) {
    return existing
  }

  const attendee: Attendee = {
    id: nextAttendeeId(),
    name,
    email,
  }

  attendeeStore.unshift(attendee)
  return attendee
}
