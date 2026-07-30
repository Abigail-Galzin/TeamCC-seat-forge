export interface DashboardMetrics {
  upcomingSessions: number
  heldRegistrations: number
  confirmedRegistrations: number
  waitlistedRegistrations: number
  expiredHolds: number
  fullSessions: number
  topWaitlistedSessions: Array<{ id: number; title: string; waitlistSize: number }>
}
