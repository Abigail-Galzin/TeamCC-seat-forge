import { apiClient } from './api'
import { workshopStore, sessionStore, nextWorkshopId } from './mock-store'
import type { Workshop, CreateWorkshopPayload } from '../types/workshop'
import type { PaginatedResult } from '../types/pagination'

export async function getWorkshops(
  page = 1,
  perPage = 5,
  activeOnly = true,
): Promise<PaginatedResult<Workshop>> {
  await Promise.resolve()
  const filtered = activeOnly
    ? workshopStore.filter(
        (workshop) => workshop.active && sessionStore.some((session) => session.workshopId === workshop.id),
      )
    : workshopStore
  const total = filtered.length
  const start = (page - 1) * perPage
  const items = filtered.slice(start, start + perPage)
  return {
    items,
    total,
    page,
    perPage,
    totalPages: Math.max(1, Math.ceil(total / perPage)),
  }
}

export async function createWorkshop(payload: CreateWorkshopPayload): Promise<Workshop> {
  const workshop: Workshop = {
    id: nextWorkshopId(),
    ...payload,
  }

  workshopStore.unshift(workshop)
  return workshop
}

export async function getWorkshopById(id: number): Promise<Workshop | undefined> {
  await Promise.resolve()
  return workshopStore.find((workshop) => workshop.id === id)
}

export async function updateWorkshop(id: number, payload: CreateWorkshopPayload): Promise<Workshop> {
  await Promise.resolve()
  const workshop = workshopStore.find((item) => item.id === id)
  if (!workshop) {
    throw new Error('Workshop not found')
  }

  Object.assign(workshop, payload)
  return workshop
}

export async function getWorkshopsFromApi(): Promise<Workshop[]> {
  const response = await apiClient.get<Workshop[]>('/workshops')
  return response.data
}
