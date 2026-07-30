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
