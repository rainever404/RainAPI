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
import { useQuery } from '@tanstack/react-query'
import { VChart } from '@visactor/react-vchart'
import { Users } from 'lucide-react'
import { useEffect, useMemo, useState, useRef } from 'react'
import { useTranslation } from 'react-i18next'

import { IconBadge } from '@/components/ui/icon-badge'
import { Skeleton } from '@/components/ui/skeleton'
import { useTheme } from '@/context/theme-provider'
import { getUserQuotaDataByUsers } from '@/features/dashboard/api'
import {
  filterUserStatisticsData,
  filterUserStatisticsDataByUsers,
  getUserStatisticsUsernames,
  processUserChartData,
} from '@/features/dashboard/lib'
import type {
  ProcessedUserChartData,
  UserChartsFilters,
} from '@/features/dashboard/types'
import { getEndOfDay, getRollingDateRange, getStartOfDay } from '@/lib/time'
import { VCHART_OPTION } from '@/lib/vchart'

import { UserChartsFilterBar } from './user-charts-filter-bar'

let themeManagerPromise: Promise<
  (typeof import('@visactor/vchart'))['ThemeManager']
> | null = null

const USER_CHARTS: {
  value: string
  labelKey: string
  specKey: keyof ProcessedUserChartData
}[] = [
  {
    value: 'rank',
    labelKey: 'User Consumption Ranking',
    specKey: 'spec_user_rank',
  },
  {
    value: 'trend',
    labelKey: 'User Consumption Trend',
    specKey: 'spec_user_trend',
  },
]

interface UserChartsProps {
  filters: UserChartsFilters
  onFiltersChange: (filters: UserChartsFilters) => void
}

export function UserCharts(props: UserChartsProps) {
  const { t } = useTranslation()
  const { resolvedTheme } = useTheme()
  const [themeReady, setThemeReady] = useState(false)
  const themeManagerRef = useRef<
    (typeof import('@visactor/vchart'))['ThemeManager'] | null
  >(null)

  const timeGranularity = props.filters.timeGranularity
  const selectedRange = props.filters.selectedRange
  const topUserLimit = props.filters.topUserLimit

  const timeRange = useMemo(() => {
    if (selectedRange === 'custom') {
      const fallback = getRollingDateRange(29)
      const start = getStartOfDay(
        props.filters.customStartDate ?? fallback.start
      )
      const end = getEndOfDay(props.filters.customEndDate ?? fallback.end)
      return {
        start_timestamp: Math.floor(start.getTime() / 1000),
        end_timestamp: Math.floor(end.getTime() / 1000),
      }
    }

    const { start, end } = getRollingDateRange(selectedRange)
    return {
      start_timestamp: Math.floor(start.getTime() / 1000),
      end_timestamp: Math.floor(end.getTime() / 1000),
    }
  }, [
    props.filters.customEndDate,
    props.filters.customStartDate,
    selectedRange,
  ])

  useEffect(() => {
    const updateTheme = async () => {
      setThemeReady(false)
      if (!themeManagerPromise) {
        themeManagerPromise = import('@visactor/vchart').then(
          (m) => m.ThemeManager
        )
      }
      const ThemeManager = await themeManagerPromise
      themeManagerRef.current = ThemeManager
      ThemeManager.setCurrentTheme(resolvedTheme === 'dark' ? 'dark' : 'light')
      setThemeReady(true)
    }
    updateTheme()
  }, [resolvedTheme])

  const { data: userData, isLoading } = useQuery({
    queryKey: ['dashboard', 'user-quota', timeRange],
    queryFn: () => getUserQuotaDataByUsers(timeRange),
    select: (res) => (res.success ? filterUserStatisticsData(res.data) : []),
    staleTime: 60_000,
  })

  const availableUsers = useMemo(
    () => getUserStatisticsUsernames(userData ?? []),
    [userData]
  )
  const visibleUserData = useMemo(
    () =>
      filterUserStatisticsDataByUsers(
        userData ?? [],
        props.filters.selectedUsers
      ),
    [props.filters.selectedUsers, userData]
  )

  const chartData = useMemo(
    () =>
      processUserChartData(
        isLoading ? [] : visibleUserData,
        timeGranularity,
        t,
        topUserLimit
      ),
    [visibleUserData, isLoading, timeGranularity, t, topUserLimit]
  )

  return (
    <div className='space-y-3'>
      <UserChartsFilterBar
        filters={props.filters}
        availableUsers={availableUsers}
        loading={isLoading}
        onChange={props.onFiltersChange}
      />

      <div className='grid gap-3'>
        {USER_CHARTS.map((chart) => {
          const spec = chartData[chart.specKey]

          return (
            <div
              key={chart.value}
              className='overflow-hidden rounded-lg border'
            >
              <div className='flex w-full items-center gap-2 border-b px-3 py-2 sm:px-5 sm:py-3'>
                <IconBadge tone='info' size='sm'>
                  <Users />
                </IconBadge>
                <div className='text-sm font-semibold'>{t(chart.labelKey)}</div>
              </div>

              <div className='h-[300px] p-1.5 sm:h-96 sm:p-2'>
                {isLoading ? (
                  <Skeleton className='h-full w-full' />
                ) : (
                  themeReady &&
                  spec && (
                    <VChart
                      key={`user-${chart.value}-${topUserLimit}-${resolvedTheme}`}
                      spec={{
                        ...spec,
                        theme: resolvedTheme === 'dark' ? 'dark' : 'light',
                        background: 'transparent',
                      }}
                      option={VCHART_OPTION}
                    />
                  )
                )}
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
