import { beforeEach, describe, expect, it, vi } from 'vitest'
import { setActivePinia, createPinia } from 'pinia'
import { useAuthStore } from '../stores/auth'
import { AUTH_TOKEN_STORAGE_KEY, apiClient, setUnauthorizedHandler } from '../services/api'
import { getCurrentUserFromApi, loginFromApi, logoutFromApi, registerFromApi } from '../services/auth'
import type { AuthSessionPayload, User } from '../types/user'

vi.mock('../services/auth', () => ({
  loginFromApi: vi.fn(),
  logoutFromApi: vi.fn(),
  registerFromApi: vi.fn(),
  getCurrentUserFromApi: vi.fn(),
}))

const attendeeUser: User = { id: 1, name: 'Jane Doe', email: 'jane@example.com', role: 'attendee', attendeeId: 10 }

const session: AuthSessionPayload = { token: 'aBc123', user: attendeeUser }

describe('auth store', () => {
  beforeEach(() => {
    localStorage.clear()
    setActivePinia(createPinia())
    vi.clearAllMocks()
  })

  it('persists the session and flips authenticated state on login', async () => {
    vi.mocked(loginFromApi).mockResolvedValue(session)
    const auth = useAuthStore()

    await auth.login('jane@example.com', 'password123')

    expect(auth.isAuthenticated).toBe(true)
    expect(auth.isAdmin).toBe(false)
    expect(auth.user?.role).toBe('attendee')
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBe('aBc123')
    expect(JSON.parse(localStorage.getItem('seatforge_user') ?? '{}')).toMatchObject({ id: 1 })
  })

  it('registers a session through the register endpoint', async () => {
    vi.mocked(registerFromApi).mockResolvedValue(session)
    const auth = useAuthStore()

    await auth.register('Jane Doe', 'jane@example.com', 'password123')

    expect(registerFromApi).toHaveBeenCalledWith('Jane Doe', 'jane@example.com', 'password123')
    expect(auth.isAuthenticated).toBe(true)
  })

  it('revokes the token on the backend and clears the session on logout', async () => {
    vi.mocked(loginFromApi).mockResolvedValue(session)
    vi.mocked(logoutFromApi).mockResolvedValue(undefined)
    const auth = useAuthStore()

    await auth.login('jane@example.com', 'password123')
    await auth.logout()

    expect(logoutFromApi).toHaveBeenCalledOnce()
    expect(auth.isAuthenticated).toBe(false)
    expect(auth.user).toBeNull()
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBeNull()
  })

  it('clears the local session even when the logout request fails', async () => {
    vi.mocked(loginFromApi).mockResolvedValue(session)
    vi.mocked(logoutFromApi).mockRejectedValue(new Error('network down'))
    const auth = useAuthStore()

    await auth.login('jane@example.com', 'password123')
    await expect(auth.logout()).resolves.toBeUndefined()

    expect(auth.isAuthenticated).toBe(false)
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBeNull()
  })

  it('restores the cached session and refreshes the user from the backend', async () => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, 'cached-token')
    vi.mocked(getCurrentUserFromApi).mockResolvedValue({ ...attendeeUser, role: 'admin' })
    const auth = useAuthStore()

    await auth.restore()

    expect(auth.isAuthenticated).toBe(true)
    expect(auth.isAdmin).toBe(true)
  })

  it('clears the session when restore finds an invalid or expired token', async () => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, 'stale-token')
    localStorage.setItem('seatforge_user', JSON.stringify(attendeeUser))
    vi.mocked(getCurrentUserFromApi).mockRejectedValue(Object.assign(new Error('Unauthorized'), { response: { status: 401 } }))
    const auth = useAuthStore()

    await auth.restore()

    expect(auth.isAuthenticated).toBe(false)
    expect(auth.user).toBeNull()
    expect(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY)).toBeNull()
  })

  it('does nothing on restore when no token is stored', async () => {
    const auth = useAuthStore()

    await auth.restore()

    expect(getCurrentUserFromApi).not.toHaveBeenCalled()
  })
})

describe('api client interceptors', () => {
  beforeEach(() => {
    localStorage.clear()
    vi.clearAllMocks()
  })

  interface RequestConfig {
  headers: Record<string, string | undefined>
}

const requestFulfilled = () =>
  (apiClient.interceptors.request as unknown as { handlers: [{ fulfilled: (config: RequestConfig) => RequestConfig }] }).handlers[0].fulfilled
  const responseRejected = () => (apiClient.interceptors.response as unknown as { handlers: [{ rejected?: (error: unknown) => Promise<never> }] }).handlers[0].rejected!

  it('attaches the bearer token to outgoing requests when one is stored', async () => {
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, 'token-xyz')

    const config = await requestFulfilled()({ headers: {} })

    expect(config.headers.Authorization).toBe('Bearer token-xyz')
  })

  it('does not attach a token when none is stored', async () => {
    const config = await requestFulfilled()({ headers: {} })

    expect(config.headers.Authorization).toBeUndefined()
  })

  it('invokes the unauthorized handler on a 401 response and re-throws the error', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    const axiosError = Object.assign(new Error('Unauthorized'), { isAxiosError: true, response: { status: 401 } })

    await expect(responseRejected()(axiosError)).rejects.toBe(axiosError)
    expect(handler).toHaveBeenCalledOnce()
  })

  it('does not invoke the unauthorized handler for non-401 errors', async () => {
    const handler = vi.fn()
    setUnauthorizedHandler(handler)
    const axiosError = Object.assign(new Error('Server error'), { isAxiosError: true, response: { status: 500 } })

    await expect(responseRejected()(axiosError)).rejects.toBe(axiosError)
    expect(handler).not.toHaveBeenCalled()
  })
})