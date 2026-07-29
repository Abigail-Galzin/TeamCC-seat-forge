export type SessionStatus = 'scheduled' | 'in_progress' | 'completed' | 'cancelled'

export interface WorkshopSession {
  id: number
  workshopId: number
  startsAt: string
  endsAt: string
  capacity: number
  status: SessionStatus
  heldCount: number
  confirmedCount: number
  waitlistSize: number
}

export type SessionFormData = {
  startsAt: Date | null
  endsAt: Date | null
  capacity: number
  status: SessionStatus
}

export const SESSION_STATUS_OPTIONS: { label: string; value: SessionStatus }[] = [
  { label: 'Programada', value: 'scheduled' },
  { label: 'En curso', value: 'in_progress' },
  { label: 'Completada', value: 'completed' },
  { label: 'Cancelada', value: 'cancelled' },
]

export const emptySessionForm = (): SessionFormData => ({
  startsAt: null,
  endsAt: null,
  capacity: 20,
  status: 'scheduled',
})

export function getAvailableSeats(session: WorkshopSession): number {
  return Math.max(0, session.capacity - session.heldCount - session.confirmedCount)
}

export function formatSessionSchedule(startsAt: string, endsAt: string): string {
  const start = new Date(startsAt)
  const end = new Date(endsAt)

  const dateFormatter = new Intl.DateTimeFormat('es-ES', {
    weekday: 'short',
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
  const timeFormatter = new Intl.DateTimeFormat('es-ES', {
    hour: '2-digit',
    minute: '2-digit',
  })

  return `${dateFormatter.format(start)} · ${timeFormatter.format(start)} - ${timeFormatter.format(end)}`
}

export function getStatusSeverity(
  status: SessionStatus,
): 'success' | 'info' | 'warn' | 'danger' | 'secondary' {
  switch (status) {
    case 'scheduled':
      return 'info'
    case 'in_progress':
      return 'success'
    case 'completed':
      return 'secondary'
    case 'cancelled':
      return 'danger'
  }
}

export function getStatusLabel(status: SessionStatus): string {
  return SESSION_STATUS_OPTIONS.find((option) => option.value === status)?.label ?? status
}
