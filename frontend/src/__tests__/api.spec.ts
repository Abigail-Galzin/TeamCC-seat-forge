import { afterEach, describe, expect, it, vi } from 'vitest'
import axios from 'axios'
import { apiClient, checkBackendHealth } from '../services/api'

describe('api client', () => {
  it('uses the /api/v1 base URL', () => {
    expect(apiClient.defaults.baseURL).toBe('/api/v1')
  })

  it('sends an Accept: application/json header', () => {
    expect(apiClient.defaults.headers.Accept).toBe('application/json')
  })
})

describe('checkBackendHealth', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('returns ok:true when the backend responds successfully', async () => {
    vi.spyOn(apiClient, 'get').mockResolvedValue({ status: 200 })

    const result = await checkBackendHealth()

    expect(result.ok).toBe(true)
    expect(result.statusCode).toBe(200)
    expect(result.statusText).toContain('Conectado')
    expect(result.url).toBe('/api/v1/up')
  })

  it('returns ok:false with the HTTP status when the backend responds with an error', async () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: { status: 500, data: {} },
    })
    vi.spyOn(apiClient, 'get').mockRejectedValue(axiosError)
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    const result = await checkBackendHealth()

    expect(result.ok).toBe(false)
    expect(result.statusCode).toBe(500)
    expect(result.statusText).toContain('500')
  })

  it('returns ok:false without a status code on a network/CORS error', async () => {
    vi.spyOn(apiClient, 'get').mockRejectedValue(new Error('Network Error'))
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(false)

    const result = await checkBackendHealth()

    expect(result.ok).toBe(false)
    expect(result.statusCode).toBeUndefined()
    expect(result.statusText).toContain('fuera de línea')
  })
})
