export interface Workshop {
  id: number
  title: string
  description: string
  topic: string
  active: boolean
}

export type WorkshopFormData = Omit<Workshop, 'id'>

export const emptyWorkshopForm = (): WorkshopFormData => ({
  title: '',
  description: '',
  topic: '',
  active: true,
})
