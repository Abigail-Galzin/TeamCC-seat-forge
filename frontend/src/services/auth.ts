import { apiClient } from './api'
import type { AuthSessionPayload, User } from '../types/user'

/**
 * Auth endpoints against the Rails backend.
 * Register and login return a session payload { token, user } — the token is
 * persisted by the auth store and attached to every subsequent request by the
 * apiClient request interceptor.
 */

export async function registerFromApi(name: string, email: string, password: string): Promise<AuthSessionPayload> {
  const response = await apiClient.post<{ data: AuthSessionPayload }>('/auth/register', {
    user: { name, email, password, password_confirmation: password },
  })
  return response.data.data
}

export async function loginFromApi(email: string, password: string): Promise<AuthSessionPayload> {
  const response = await apiClient.post<{ data: AuthSessionPayload }>('/auth/login', { email, password })
  return response.data.data
}

export async function logoutFromApi(): Promise<void> {
  await apiClient.delete('/auth/logout')
}

export async function getCurrentUserFromApi(): Promise<User> {
  const response = await apiClient.get<{ data: User }>('/auth/me')
  return response.data.data
}