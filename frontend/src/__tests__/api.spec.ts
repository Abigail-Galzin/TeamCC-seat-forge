import { afterEach, describe, expect, it, vi } from 'vitest'
import axios from 'axios'
import { apiClient, checkBackendHealth, getErrorMessage } from '../services/api'

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
    expect(result.statusText).toContain('connected')
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
    expect(result.statusText).toContain('offline')
  })
})

describe('getErrorMessage', () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it('appends validation details to the backend message', () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: {
        status: 422,
        data: { error: { code: 'creation_conflict', message: 'Could not create the Session', details: ['Starts at must be in the future'] } },
      },
    })
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    expect(getErrorMessage(axiosError)).toBe('Could not create the Session: Starts at must be in the future')
  })

  it('joins multiple details', () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: {
        status: 422,
        data: { error: { code: 'creation_conflict', message: 'Could not create the Workshop', details: ['Title is too short', 'Topic can\'t be blank'] } },
      },
    })
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    expect(getErrorMessage(axiosError)).toBe("Could not create the Workshop: Title is too short, Topic can't be blank")
  })

  it('falls back to the backend message alone when there are no details', () => {
    const axiosError = Object.assign(new Error('Request failed'), {
      isAxiosError: true,
      response: { status: 404, data: { error: { code: 'not_found', message: 'Not found the Workshop', details: [] } } },
    })
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    expect(getErrorMessage(axiosError)).toBe('Not found the Workshop')
  })

  it('falls back to the axios message when the backend body has no error', () => {
    const axiosError = Object.assign(new Error('Request failed with status code 500'), {
      isAxiosError: true,
      response: { status: 500, data: {} },
    })
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(true)

    expect(getErrorMessage(axiosError)).toBe('Request failed with status code 500')
  })

  it('falls back to the fallback string for a non-axios, non-Error value', () => {
    vi.spyOn(axios, 'isAxiosError').mockReturnValue(false)

    expect(getErrorMessage('nope', 'Unexpected error')).toBe('Unexpected error')
  })
})
