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
import { Loader2 } from 'lucide-react'
import { useCallback, useMemo } from 'react'
import { useTranslation } from 'react-i18next'

import { DatePicker } from '@/components/date-picker'
import { MultiSelect } from '@/components/multi-select'
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs'
import {
  TIME_GRANULARITY_OPTIONS,
  TIME_RANGE_PRESETS,
} from '@/features/dashboard/constants'
import { getDefaultDays, saveGranularity } from '@/features/dashboard/lib'
import type { UserChartsFilters } from '@/features/dashboard/types'
import { getRollingDateRange, type TimeGranularity } from '@/lib/time'

const TOP_USER_LIMIT_OPTIONS = [5, 10, 20, 50]

interface UserChartsFilterBarProps {
  filters: UserChartsFilters
  availableUsers: string[]
  loading: boolean
  onChange: (filters: UserChartsFilters) => void
}

export function UserChartsFilterBar({
  filters,
  availableUsers,
  loading,
  onChange,
}: UserChartsFilterBarProps) {
  const { t } = useTranslation()
  const userOptions = useMemo(
    () =>
      availableUsers.map((username) => ({
        label: username,
        value: username.trim().toLowerCase(),
      })),
    [availableUsers]
  )
  const selectedUsers =
    filters.selectedUsers ?? userOptions.map((option) => option.value)

  const handleRangeChange = useCallback(
    (value: string) => {
      if (value === 'custom') {
        const days =
          typeof filters.selectedRange === 'number'
            ? filters.selectedRange
            : getDefaultDays(filters.timeGranularity)
        const { start, end } = getRollingDateRange(days)
        onChange({
          ...filters,
          selectedRange: 'custom',
          customStartDate: filters.customStartDate ?? start,
          customEndDate: filters.customEndDate ?? end,
        })
        return
      }

      onChange({
        ...filters,
        selectedRange: Number(value),
        customStartDate: undefined,
        customEndDate: undefined,
      })
    },
    [filters, onChange]
  )

  const handleGranularityChange = useCallback(
    (granularity: TimeGranularity) => {
      saveGranularity(granularity)
      onChange({
        ...filters,
        timeGranularity: granularity,
        selectedRange:
          filters.selectedRange === 'custom'
            ? 'custom'
            : getDefaultDays(granularity),
      })
    },
    [filters, onChange]
  )

  const handleStartDateChange = useCallback(
    (date: Date | undefined) => {
      if (!date) return
      onChange({
        ...filters,
        selectedRange: 'custom',
        customStartDate: date,
        customEndDate:
          filters.customEndDate && filters.customEndDate < date
            ? date
            : filters.customEndDate,
      })
    },
    [filters, onChange]
  )

  const handleEndDateChange = useCallback(
    (date: Date | undefined) => {
      if (!date) return
      onChange({
        ...filters,
        selectedRange: 'custom',
        customStartDate:
          filters.customStartDate && filters.customStartDate > date
            ? date
            : filters.customStartDate,
        customEndDate: date,
      })
    },
    [filters, onChange]
  )

  return (
    <div className='space-y-2'>
      <div className='flex items-center gap-1.5 overflow-x-auto pb-1 sm:gap-2'>
        <Tabs
          value={String(filters.selectedRange)}
          onValueChange={handleRangeChange}
          className='shrink-0'
        >
          <TabsList>
            {TIME_RANGE_PRESETS.map((preset) => (
              <TabsTrigger
                key={preset.days}
                value={String(preset.days)}
                className='px-2.5 text-xs'
              >
                {t(preset.label)}
              </TabsTrigger>
            ))}
            <TabsTrigger value='custom' className='px-2.5 text-xs'>
              {t('Custom')}
            </TabsTrigger>
          </TabsList>
        </Tabs>

        <Tabs
          value={filters.timeGranularity}
          onValueChange={(value) =>
            handleGranularityChange(value as TimeGranularity)
          }
          className='shrink-0'
        >
          <TabsList>
            {TIME_GRANULARITY_OPTIONS.map((option) => (
              <TabsTrigger
                key={option.value}
                value={option.value}
                className='px-2.5 text-xs'
              >
                {t(option.label)}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>

        <Tabs
          value={String(filters.topUserLimit)}
          onValueChange={(value) =>
            onChange({ ...filters, topUserLimit: Number(value) })
          }
          className='shrink-0'
        >
          <TabsList>
            <span className='text-muted-foreground px-2 text-xs font-medium whitespace-nowrap'>
              {t('Top Users')}
            </span>
            {TOP_USER_LIMIT_OPTIONS.map((limit) => (
              <TabsTrigger
                key={limit}
                value={String(limit)}
                className='px-2.5 text-xs'
              >
                {t('Top {{count}}', { count: limit })}
              </TabsTrigger>
            ))}
          </TabsList>
        </Tabs>

        {loading && (
          <Loader2 className='text-muted-foreground size-4 shrink-0 animate-spin' />
        )}
      </div>

      <div className='flex flex-col gap-2 sm:flex-row sm:flex-wrap sm:items-center'>
        <label
          htmlFor='user-statistics-users'
          className='text-muted-foreground text-xs font-medium'
        >
          {t('Users')}
        </label>
        <MultiSelect
          id='user-statistics-users'
          options={userOptions}
          selected={selectedUsers}
          onChange={(values) =>
            onChange({
              ...filters,
              selectedUsers:
                values.length === userOptions.length ? undefined : values,
            })
          }
          placeholder={t('Users')}
          className='min-w-0 sm:w-72'
          renderSelectedSummary={(values) =>
            filters.selectedUsers === undefined
              ? `${t('All')} (${values.length})`
              : `${t('Users')}: ${values.length}`
          }
        />

        {filters.selectedRange === 'custom' && (
          <div className='flex flex-col gap-2 sm:flex-row sm:items-center'>
            <span className='text-muted-foreground text-xs font-medium'>
              {t('Start Time')}
            </span>
            <DatePicker
              selected={filters.customStartDate}
              onSelect={handleStartDateChange}
              placeholder={t('Start Time')}
              className='w-full sm:w-40'
            />
            <span className='text-muted-foreground text-xs font-medium'>
              {t('End Time')}
            </span>
            <DatePicker
              selected={filters.customEndDate}
              onSelect={handleEndDateChange}
              placeholder={t('End Time')}
              className='w-full sm:w-40'
            />
          </div>
        )}
      </div>
    </div>
  )
}
