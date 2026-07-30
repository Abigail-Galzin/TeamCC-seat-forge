import { workshopStore, sessionStore, registrationStore, getActiveRegistrationsForSession } from './mock-store'
import type { DashboardMetrics } from '../types/dashboard'

export async function getDashboardMetrics(): Promise<DashboardMetrics> {
  await Promise.resolve()
  const upcomingSessions = sessionStore.filter((session) => session.status === 'scheduled').length
  const heldRegistrations = registrationStore.filter((registration) => registration.status === 'held').length
  const confirmedRegistrations = registrationStore.filter((registration) => registration.status === 'confirmed').length
  const waitlistedRegistrations = registrationStore.filter((registration) => registration.status === 'waitlisted').length
  const expiredHolds = registrationStore.filter((registration) => registration.status === 'expired').length
  const fullSessions = sessionStore.filter(
    (session) => getActiveRegistrationsForSession(session.id).length >= session.capacity,
  ).length

  const topWaitlistedSessions = sessionStore
    .map((session) => ({
      id: session.id,
      title: workshopStore.find((workshop) => workshop.id === session.workshopId)?.title ?? 'Workshop',
      waitlistSize: registrationStore.filter(
        (registration) => registration.sessionId === session.id && registration.status === 'waitlisted',
      ).length,
    }))
    .filter((entry) => entry.waitlistSize > 0)
    .sort((a, b) => b.waitlistSize - a.waitlistSize)
    .slice(0, 3)

  return {
    upcomingSessions,
    heldRegistrations,
    confirmedRegistrations,
    waitlistedRegistrations,
    expiredHolds,
    fullSessions,
    topWaitlistedSessions,
  }
}
