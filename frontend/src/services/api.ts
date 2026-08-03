import axios from 'axios'
import type { ApiErrorBody } from '../types/api-error'

/**
 * Centralized API service for communicating with the Rails backend.
 * The base URL comes from the VITE_API_BASE_URL environment variable.
 */

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

// Shared default page size for every paginator in the app, matches the backend's PAGY_DEFAULT_ITEMS.
export const DEFAULT_PAGE_SIZE = Number(import.meta.env.VITE_PAGE_DEFAULT_ITEMS) || 10

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: 'application/json',
  },
})

export interface BackendHealthResult {
  ok: boolean
  statusText: string
  statusCode?: number
  url: string
  timestamp: string
}

/**
 * Example function that calls the Rails backend's /up endpoint.
 */
export async function checkBackendHealth(): Promise<BackendHealthResult> {
  const targetUrl = `${API_BASE_URL}/up`
  const now = new Date().toLocaleTimeString()

  try {
    const response = await apiClient.get('/up')

    return {
      ok: true,
      statusText: 'Backend connected (HTTP 200 OK)',
      statusCode: response.status,
      url: targetUrl,
      timestamp: now,
    }
  } catch (error: unknown) {
    if (axios.isAxiosError(error) && error.response) {
      return {
        ok: false,
        statusText: `The server responded with HTTP status ${error.response.status}`,
        statusCode: error.response.status,
        url: targetUrl,
        timestamp: now,
      }
    }

    return {
      ok: false,
      statusText: 'Could not connect to the backend (server offline or CORS error)',
      url: targetUrl,
      timestamp: now,
    }
  }
}

/**
 * Extracts a user-facing message from either a mock service error (plain Error)
 * or a real backend error following the { error: { code, message, details } } contract.
 * Views should always go through this instead of reading error.message directly,
 * so no view code needs to change once a service swaps its mock body for a real apiClient call.
 */
export function getErrorMessage(error: unknown, fallback = 'Unexpected error'): string {
  if (axios.isAxiosError<ApiErrorBody>(error)) {
    const apiError = error.response?.data?.error
    if (apiError?.message) {
      const details = apiError.details?.filter((detail): detail is string => typeof detail === 'string')
      return details?.length ? `${apiError.message}: ${details.join(', ')}` : apiError.message
    }

    return error.message || fallback
  }

  if (error instanceof Error) {
    return error.message
  }

  return fallback
}
