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
import assert from 'node:assert/strict'

import { describe, test } from 'vitest'

import type { QuotaDataItem } from '../../types'
import {
  filterUserStatisticsData,
  filterUserStatisticsDataByUsers,
  getUserStatisticsUsernames,
} from '../user-statistics-filter'

describe('user statistics visibility', () => {
  test('excludes configured users from all user statistics input data', () => {
    const data: QuotaDataItem[] = [
      { username: 'rain', created_at: 1, quota: 10 },
      { username: 'poppy', created_at: 1, quota: 20 },
      { username: 'MGFLY', created_at: 1, quota: 30 },
      { username: ' anshuo ', created_at: 1, quota: 40 },
      { username: 'nick', created_at: 1, quota: 50 },
    ]

    const filtered = filterUserStatisticsData(data)

    assert.deepEqual(
      filtered.map((item) => item.username),
      ['rain', 'nick']
    )
    assert.equal(data.length, 5)
  })

  test('preserves rows without a username for existing unknown-user handling', () => {
    const data: QuotaDataItem[] = [{ created_at: 1, quota: 10 }]

    assert.deepEqual(filterUserStatisticsData(data), data)
  })

  test('returns unique selectable users without configured hidden accounts', () => {
    const data: QuotaDataItem[] = [
      { username: 'rain', created_at: 1 },
      { username: 'Rain', created_at: 2 },
      { username: 'nick', created_at: 1 },
      { username: 'poppy', created_at: 1 },
      { created_at: 1 },
    ]

    assert.deepEqual(getUserStatisticsUsernames(data), ['nick', 'rain'])
  })

  test('shows only explicitly selected users and supports an empty selection', () => {
    const data: QuotaDataItem[] = [
      { username: 'rain', created_at: 1 },
      { username: 'nick', created_at: 1 },
      { username: 'hao', created_at: 1 },
      { created_at: 1 },
    ]

    assert.deepEqual(
      filterUserStatisticsDataByUsers(data, [' RAIN ', 'hao']).map(
        (item) => item.username
      ),
      ['rain', 'hao']
    )
    assert.deepEqual(filterUserStatisticsDataByUsers(data, []), [])
    assert.equal(filterUserStatisticsDataByUsers(data), data)
  })
})
