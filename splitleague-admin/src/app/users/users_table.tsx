/*
 * The users table.
 *
 * Guests are hidden by default and revealed with a toggle. There are 153 of them against 252
 * real accounts, and they have no email, no signups and no activity of their own - left in,
 * they are more than a third of the rows and every one of them is noise when the question is
 * "who is actually using this?".
 */

'use client';

import { useMemo, useState } from 'react';
import type { UserRow } from '@/lib/api';
import { format_date, format_idle } from '@/lib/format';
import DataTable, { type Column, type Filter } from '@/components/data_table';
import { Pill } from '@/components/ui';

const columns: Column<UserRow>[] = [
  {
    key: 'name',
    label: 'Name',
    render: (user) => (
      <>
        {user.name || '—'}
        {user.is_guest && (
          <span className="ml-2">
            <Pill>guest</Pill>
          </span>
        )}
      </>
    ),
  },
  {
    key: 'nickname',
    label: 'Nickname',
    render: (user) => <span className="text-slate-600">{user.nickname || '—'}</span>,
  },
  {
    key: 'email',
    label: 'Email',
    // A guest's email is the literal string "guest", which is a detail of the data model
    // rather than something worth reading 153 times.
    render: (user) => (
      <span className="text-slate-600">{user.is_guest ? '—' : user.email || '—'}</span>
    ),
  },
  {
    key: 'leagues_created',
    label: 'Organises',
    align: 'right',
    render: (user) =>
      user.leagues_created > 0 ? (
        <span className="font-medium tabular-nums text-slate-900">{user.leagues_created}</span>
      ) : (
        <span className="text-slate-300">0</span>
      ),
  },
  {
    key: 'leagues_joined',
    label: 'Member of',
    align: 'right',
    render: (user) =>
      user.leagues_joined > 0 ? (
        <span className="tabular-nums">{user.leagues_joined}</span>
      ) : (
        <span className="text-slate-300">0</span>
      ),
  },
  {
    key: 'created_at',
    label: 'Signed up',
    render: (user) => format_date(user.created_at),
  },
  {
    key: 'days_idle',
    label: 'Last seen',
    // Ascending first, same as the leagues table - a small idle number is a live user
    first_dir: 'asc',
    render: (user) => (
      <span className={user.days_idle === null || user.days_idle > 180 ? 'text-slate-400' : ''}>
        {format_idle(user.days_idle)}
      </span>
    ),
  },
];

const filters: Filter<UserRow>[] = [
  { key: 'organisers', label: 'Organisers', test: (u) => u.leagues_created > 0 },

  // The cohort worth watching: signed up, never created anything, never joined anything
  {
    key: 'inactive',
    label: 'Never in a league',
    test: (u) => !u.is_guest && u.leagues_created === 0 && u.leagues_joined === 0,
  },

  { key: 'recent', label: 'Seen in 30 days', test: (u) => u.days_idle !== null && u.days_idle <= 30 },
  { key: 'new', label: 'New in 30 days', test: (u) => {
      if (!u.created_at) return false;
      const days = (Date.now() - new Date(u.created_at).getTime()) / (1000 * 60 * 60 * 24);
      return days <= 30;
    },
  },
];

export default function UsersTable({ users }: { users: UserRow[] }) {
  const [show_guests, set_show_guests] = useState(false);

  const rows = useMemo(
    () => (show_guests ? users : users.filter((user) => !user.is_guest)),
    [users, show_guests]
  );

  return (
    <>
      <label className="mb-3 flex w-fit cursor-pointer items-center gap-2 text-sm text-slate-600">
        <input
          type="checkbox"
          checked={show_guests}
          onChange={(e) => set_show_guests(e.target.checked)}
          className="h-4 w-4 rounded border-slate-300"
        />
        Show guest players
      </label>

      <DataTable
        rows={rows}
        columns={columns}
        filters={filters}
        row_key={(user) => user.id}
        // Guests get a detail page too. There is less on it, but "which league is this
        // guest in?" is a real question when you are deciding whether a league is real.
        href={(user) => `/users/${user.id}`}
        search={(user) => [user.name, user.nickname, user.email].filter(Boolean).join(' ')}
        search_placeholder="Search name, nickname, email…"
        // Most recently seen first, never-seen accounts at the bottom
        initial_sort={{ key: 'days_idle', dir: 'asc' }}
        empty="No users match."
      />
    </>
  );
}
