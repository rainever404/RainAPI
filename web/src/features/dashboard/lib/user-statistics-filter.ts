/*
Copyright (C) 2023-2026 QuantumNous

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <https://www.gnu.org/licenses/>.

For commercial licensing, please contact support@quantumnous.com
*/
import type { QuotaDataItem } from '@/features/dashboard/types'

const HIDDEN_USER_STATISTICS_USERNAMES = new Set(['poppy', 'mgfly', 'anshuo'])

function normalizeUsername(username: string): string {
  return username.trim().toLowerCase()
}

export function filterUserStatisticsData(
  data: QuotaDataItem[]
): QuotaDataItem[] {
  return data.filter((item) => {
    const username = item.username && normalizeUsername(item.username)
    return !username || !HIDDEN_USER_STATISTICS_USERNAMES.has(username)
  })
}

export function getUserStatisticsUsernames(data: QuotaDataItem[]): string[] {
  const usernames = new Map<string, string>()

  for (const item of data) {
    const label = item.username?.trim()
    if (!label) continue

    const value = normalizeUsername(label)
    if (!HIDDEN_USER_STATISTICS_USERNAMES.has(value)) {
      usernames.set(value, usernames.get(value) ?? label)
    }
  }

  return [...usernames.values()].sort((left, right) =>
    left.localeCompare(right)
  )
}

export function filterUserStatisticsDataByUsers(
  data: QuotaDataItem[],
  selectedUsers?: string[]
): QuotaDataItem[] {
  if (selectedUsers === undefined) return data

  const selected = new Set(selectedUsers.map(normalizeUsername))
  return data.filter((item) => {
    const username = item.username && normalizeUsername(item.username)
    return Boolean(username && selected.has(username))
  })
}
