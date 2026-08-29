/*
 * The leagues table. Client-side because it sorts and filters in the browser.
 *
 * The columns are ordered the way the questions get asked: what is it, who runs it, how many
 * people, how far along, and when did anything last happen.
 */

'use client';

import Link from 'next/link';
import type { LeagueRow } from '@/lib/api';
import { format_date, format_idle } from '@/lib/format';
import DataTable, { type Column, type Filter } from '@/components/data_table';
import { StageBadge, Progress, Pill } from '@/components/ui';

const columns: Column<LeagueRow>[] = [
  {
    key: 'name',
    label: 'League',
    // The link is added by DataTable on the first column, so this only renders the text
    render: (league) => league.name,
  },
  {
    key: 'organiser_name',
    label: 'Organiser',
    render: (league) =>
      league.organiser_id ? (
        <Link
          href={`/users/${league.organiser_id}`}
          className="text-slate-700 hover:text-blue-700 hover:underline"
        >
          {league.organiser_name || `#${league.organiser_id}`}
        </Link>
      ) : (
        // created_by is null, or the account was deleted. Worth flagging rather than
        // showing an empty cell, because nobody can administer this league from the app.
        <Pill tone="red">no organiser</Pill>
      ),
  },
  {
    key: 'stage',
    label: 'Stage',
    render: (league) => <StageBadge stage={league.stage} />,
    // Sorted by the stage's position in the life of a league, not alphabetically - the
    // useful order is setup, in play, complete, and "complete, in_play, setup" is not it.
    value: (league) => ({ setup: 0, in_play: 1, complete: 2 })[league.stage],
  },
  {
    key: 'members_total',
    label: 'Members',
    align: 'right',
    render: (league) => (
      <span className="tabular-nums">
        {league.members_total}
        {league.members_guest > 0 && (
          <span className="ml-1 text-xs text-slate-400">({league.members_guest} guest)</span>
        )}
      </span>
    ),
  },
  {
    key: 'fixtures_played',
    label: 'Fixtures',
    render: (league) => <Progress played={league.fixtures_played} total={league.fixtures_total} />,
    // Sort by how much has actually been played, which is the interesting end
    value: (league) => league.fixtures_played,
  },
  {
    key: 'created_at',
    label: 'Created',
    render: (league) => format_date(league.created_at),
  },
  {
    key: 'days_idle',
    label: 'Last activity',
    render: (league) => (
      <span className={league.days_idle === null || league.days_idle > 180 ? 'text-slate-400' : ''}>
        {format_idle(league.days_idle)}
      </span>
    ),
  },
  {
    key: 'active',
    label: 'State',
    render: (league) =>
      league.active === false ? <Pill tone="amber">archived</Pill> : <span className="text-slate-400">—</span>,
  },
];

const filters: Filter<LeagueRow>[] = [
  { key: 'setup', label: 'Setting up', test: (l) => l.stage === 'setup' },
  { key: 'in_play', label: 'In play', test: (l) => l.stage === 'in_play' },
  { key: 'complete', label: 'Complete', test: (l) => l.stage === 'complete' },

  // The two that matter when hunting for junk
  { key: 'thin', label: '1 member or fewer', test: (l) => l.members_total <= 1 },
  { key: 'idle', label: 'Idle 90+ days', test: (l) => l.days_idle === null || l.days_idle >= 90 },

  { key: 'archived', label: 'Archived', test: (l) => l.active === false },
];

export default function LeaguesTable({ leagues }: { leagues: LeagueRow[] }) {
  return (
    <DataTable
      rows={leagues}
      columns={columns}
      filters={filters}
      row_key={(league) => league.id}
      href={(league) => `/leagues/${league.id}`}
      // Searching the code and the slug too, so a link somebody sent you can be pasted in
      search={(league) =>
        [league.name, league.organiser_name, league.organiser_email, league.public_code, league.share_slug]
          .filter(Boolean)
          .join(' ')
      }
      search_placeholder="Search name, organiser, code…"
      initial_sort={{ key: 'created_at', dir: 'desc' }}
      empty="No leagues match."
    />
  );
}
