import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { getCurrentUserFromApi, loginFromApi, logoutFromApi, registerFromApi } from '../services/auth'
import { AUTH_TOKEN_STORAGE_KEY } from '../services/api'
import type { AuthSessionPayload, User } from '../types/user'

const USER_STORAGE_KEY = 'seatforge_user'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(localStorage.getItem(AUTH_TOKEN_STORAGE_KEY))
  const user = ref<User | null>(readStoredUser())

  const isAuthenticated = computed(() => token.value !== null)
  const isAdmin = computed(() => user.value?.role === 'admin')

  function persistSession(session: AuthSessionPayload) {
    token.value = session.token
    user.value = session.user
    localStorage.setItem(AUTH_TOKEN_STORAGE_KEY, session.token)
    localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(session.user))
  }

  function clearSession() {
    token.value = null
    user.value = null
    localStorage.removeItem(AUTH_TOKEN_STORAGE_KEY)
    localStorage.removeItem(USER_STORAGE_KEY)
  }

  async function login(email: string, password: string): Promise<void> {
    persistSession(await loginFromApi(email, password))
  }

  async function register(name: string, email: string, password: string): Promise<void> {
    persistSession(await registerFromApi(name, email, password))
  }

  async function logout(): Promise<void> {
    try {
      if (token.value) {
        await logoutFromApi()
      }
    } catch {
      // ignore server failures; the local session is cleared regardless
    } finally {
      clearSession()
    }
  }

  // Validates the stored token against GET /api/v1/auth/me on app boot. Refreshes
  // the cached user from the backend (source of truth for role changes) and
  // clears the session when the token is expired, revoked, or invalid.
  async function restore(): Promise<void> {
    if (!token.value) return

    try {
      user.value = await getCurrentUserFromApi()
      localStorage.setItem(USER_STORAGE_KEY, JSON.stringify(user.value))
    } catch {
      clearSession()
    }
  }

  return { token, user, isAuthenticated, isAdmin, login, register, logout, clearSession, restore }
})

function readStoredUser(): User | null {
  const raw = localStorage.getItem(USER_STORAGE_KEY)
  if (!raw) return null
  try {
    return JSON.parse(raw) as User
  } catch {
    return null
  }
}