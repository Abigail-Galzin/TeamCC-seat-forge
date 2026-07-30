import axios from 'axios'

/**
 * Servicio API centralizado para comunicarse con el backend Rails.
 * La URL base se obtiene de la variable de entorno VITE_API_BASE_URL.
 */

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

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
 * Función de ejemplo que realiza una llamada al endpoint /up del backend de Rails.
 */
export async function checkBackendHealth(): Promise<BackendHealthResult> {
  const targetUrl = `${API_BASE_URL}/up`
  const now = new Date().toLocaleTimeString()

  try {
    const response = await apiClient.get('/up')

    return {
      ok: true,
      statusText: 'Backend Conectado (HTTP 200 OK)',
      statusCode: response.status,
      url: targetUrl,
      timestamp: now,
    }
  } catch (error: unknown) {
    if (axios.isAxiosError(error) && error.response) {
      return {
        ok: false,
        statusText: `El servidor respondió con código HTTP ${error.response.status}`,
        statusCode: error.response.status,
        url: targetUrl,
        timestamp: now,
      }
    }

    return {
      ok: false,
      statusText: 'No se pudo conectar con el backend (Servidor fuera de línea o error CORS)',
      url: targetUrl,
      timestamp: now,
    }
  }
}
