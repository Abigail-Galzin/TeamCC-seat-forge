export interface PaginationInfo {
  page: number
  pages: number
  count: number
  limit: number
  next: number | null
  prev: number | null
}

export interface PaginatedResult<T> {
  message: string | null
  data: T[]
  status: string
  pagination: PaginationInfo
}

export function emptyPaginatedResult<T>(limit: number): PaginatedResult<T> {
  return {
    message: null,
    data: [],
    status: 'ok',
    pagination: { page: 1, pages: 1, count: 0, limit, next: null, prev: null },
  }
}
