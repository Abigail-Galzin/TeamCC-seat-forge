export interface DashboardCurrentSession {
  id: number
  startsAt: string
  endsAt: string
  capacity: number
  availableSeats: number
  inProgress: boolean
}

export interface DashboardWorkshopSummary {
  id: number
  title: string
  topic: string
  description: string
  currentSession: DashboardCurrentSession | null
}

export interface DashboardTopWaitlistedSession {
  sessionId: number
  startsAt: string | null
  waitlistSize: number
}

export interface WorkshopDashboardMetrics {
  workshopId: number
  workshopTitle: string
  upcomingSessions: number
  heldRegistrations: number
  confirmedRegistrations: number
  waitlistedRegistrations: number
  expiredHoldsToday: number
  fullSessions: number
  topWaitlistedSessions: DashboardTopWaitlistedSession[]
}
