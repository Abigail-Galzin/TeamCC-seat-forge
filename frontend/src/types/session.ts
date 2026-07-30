export interface Session {
  id: number
  workshopId: number
  startsAt: string
  endsAt: string
  capacity: number
  status: 'scheduled' | 'cancelled' | 'completed'
}

export interface CreateSessionPayload {
  workshopId: number
  startsAt: string
  endsAt: string
  capacity: number
  status: 'scheduled' | 'cancelled' | 'completed'
}
