export interface Workshop {
  id: number
  title: string
  description: string
  topic: string
  active: boolean
}

export interface CreateWorkshopPayload {
  title: string
  description: string
  topic: string
  active: boolean
}
