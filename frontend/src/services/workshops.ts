import axios from 'axios'
import { apiClient, DEFAULT_PAGE_SIZE } from './api'
import type { Workshop, CreateWorkshopPayload } from '../types/workshop'
import type { PaginatedResult, PaginationInfo } from '../types/pagination'

// GET /api/v1/workshops caps per_page at Pagy::DEFAULT[:items] (PAGY_DEFAULT_ITEMS) server-side.
const MAX_WORKSHOPS_PER_PAGE = DEFAULT_PAGE_SIZE

export async function getWorkshops(
  page = 1,
  perPage = DEFAULT_PAGE_SIZE,
  activeOnly = true,
): Promise<PaginatedResult<Workshop>> {
  const response = await apiClient.get<{
    message: string | null
    data: Workshop[]
    status: string
    pagination: PaginationInfo
  }>('/workshops', {
    params: { active: activeOnly || undefined, page, per_page: perPage },
  })

  return response.data
}

export async function createWorkshop(payload: CreateWorkshopPayload): Promise<Workshop> {
  const response = await apiClient.post<{ data: Workshop }>('/workshops', { workshop: payload })
  return response.data.data
}

/**
 * Loads a single workshop from the real backend (GET /api/v1/workshops/:id).
 * Returns undefined on a 404 so views can show a "not found" state.
 */
export async function getWorkshopById(id: number): Promise<Workshop | undefined> {
  try {
    const response = await apiClient.get<{ data: Workshop }>(`/workshops/${id}`)
    return response.data.data
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      return undefined
    }
    throw error
  }
}

export async function updateWorkshop(id: number, payload: CreateWorkshopPayload): Promise<Workshop> {
  const response = await apiClient.patch<{ data: Workshop }>(`/workshops/${id}`, { workshop: payload })
  return response.data.data
}

/**
 * Derives the sorted, de-duplicated topic list from every workshop (active or not), for use in
 * filter dropdowns. Fetches a single large page rather than a dedicated endpoint, so topics
 * beyond the first MAX_WORKSHOPS_PER_PAGE workshops won't appear.
 */
export async function getWorkshopTopics(): Promise<string[]> {
  const response = await apiClient.get<{ data: Workshop[] }>('/workshops', {
    params: { per_page: MAX_WORKSHOPS_PER_PAGE },
  })
  return Array.from(new Set(response.data.data.map((workshop) => workshop.topic))).sort()
}
