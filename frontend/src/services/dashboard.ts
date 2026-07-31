import { apiClient } from './api'
import type { DashboardWorkshopSummary, WorkshopDashboardMetrics } from '../types/dashboard'

interface ApiEnvelope<T> {
  message: string | null
  data: T
  status: string
}

interface DashboardCurrentSessionResponse {
  id: number
  starts_at: string
  ends_at: string
  capacity: number
  available_seats: number
  in_progress: boolean
}

interface DashboardWorkshopResponse {
  id: number
  title: string
  topic: string
  description: string
  current_session: DashboardCurrentSessionResponse | null
}

interface WorkshopDashboardMetricsResponse {
  workshop_id: number
  workshop_title: string
  upcoming_sessions: number
  held_registrations: number
  confirmed_registrations: number
  waitlisted_registrations: number
  expired_holds_today: number
  full_sessions: number
  top_waitlisted_sessions: Array<{ session_id: number; starts_at: string | null; waitlist_size: number }>
}

function mapWorkshop(workshop: DashboardWorkshopResponse): DashboardWorkshopSummary {
  return {
    id: workshop.id,
    title: workshop.title,
    topic: workshop.topic,
    description: workshop.description,
    currentSession: workshop.current_session
      ? {
          id: workshop.current_session.id,
          startsAt: workshop.current_session.starts_at,
          endsAt: workshop.current_session.ends_at,
          capacity: workshop.current_session.capacity,
          availableSeats: workshop.current_session.available_seats,
          inProgress: workshop.current_session.in_progress,
        }
      : null,
  }
}

export async function getDashboardWorkshops(): Promise<DashboardWorkshopSummary[]> {
  const response = await apiClient.get<ApiEnvelope<DashboardWorkshopResponse[]>>('/dashboard')
  return response.data.data.map(mapWorkshop)
}

export async function getWorkshopDashboardMetrics(workshopId: number): Promise<WorkshopDashboardMetrics> {
  const response = await apiClient.get<ApiEnvelope<WorkshopDashboardMetricsResponse>>(
    `/workshops/${workshopId}/dashboard`,
  )
  const data = response.data.data

  return {
    workshopId: data.workshop_id,
    workshopTitle: data.workshop_title,
    upcomingSessions: data.upcoming_sessions,
    heldRegistrations: data.held_registrations,
    confirmedRegistrations: data.confirmed_registrations,
    waitlistedRegistrations: data.waitlisted_registrations,
    expiredHoldsToday: data.expired_holds_today,
    fullSessions: data.full_sessions,
    topWaitlistedSessions: data.top_waitlisted_sessions.map((item) => ({
      sessionId: item.session_id,
      startsAt: item.starts_at,
      waitlistSize: item.waitlist_size,
    })),
  }
}
