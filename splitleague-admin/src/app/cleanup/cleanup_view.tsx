/*
 * The cleanup list: reason filters, the threshold controls, a table with checkboxes, and the
 * bulk archive / delete bar.
 *
 * This is a bespoke table rather than the shared DataTable because it needs selection, and
 * bolting selection onto the generic component would make every other table pay for it.
 *
 * The safety rules here are deliberate and worth keeping:
 *   - nothing is selected when the page loads
 *   - "select all" selects only what is currently on screen, never the whole hidden list
 *   - deleting requires typing the number of leagues being deleted
 *   - dormant leagues are called out separately, because they contain real played matches
 */

'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useMemo, useState } from 'react';
import type { CleanupData, CleanupReason } from '@/lib/api';
import { format_date, format_idle, REASON_LABELS, REASON_HELP } from '@/lib/format';
import { StageBadge, Pill, SectionTitle } from '@/components/ui';
import { run_league_action } from '@/app/actions';

// The order the reasons are shown in, and the tone each one carries
const REASON_ORDER: CleanupReason[] = [
  'empty',
  'abandoned_setup',
  'stalled',
  'duplicate',
  'orphaned',
  'dormant',
];

const REASON_TONE: Record<CleanupReason, 'slate' | 'amber' | 'red' | 'blue' | 'violet'> = {
  empty: 'slate',
  abandoned_setup: 'amber',
  stalled: 'amber',
  duplicate: 'violet',
  orphaned: 'red',
  dormant: 'blue',
};

export default function CleanupView({ data }: { data: CleanupData }) {
  const router = useRouter();

  const [reason_filter, set_reason_filter] = useState<CleanupReason | null>(null);
  const [selected, set_selected] = useState<Set<number>>(new Set());
  const [busy, set_busy] = useState(false);
  const [message, set_message] = useState<{ ok: boolean; text: string } | null>(null);
  const [confirming, set_confirming] = useState(false);
  const [typed_count, set_typed_count] = useState('');

  // Thresholds, edited locally then applied by navigating - see the page header comment
  const [idle_days, set_idle_days] = useState(String(data.thresholds.idle_days));
  const [min_age_days, set_min_age_days] = useState(String(data.thresholds.min_age_days));

  // Filtered by the reason chip, then ordered by when anything last happened: most recently
  // active at the top, stale further down, and the ones nothing has ever happened in right
  // at the bottom. A null days_idle is the absence of a date, not the oldest one, so it
  // sorts last rather than pretending to be infinitely idle - the same rule DataTable uses.
  const visible = useMemo(() => {
    const rows = reason_filter
      ? data.leagues.filter((league) => league.reasons.includes(reason_filter))
      : data.leagues;

    return [...rows].sort((a, b) => {
      if (a.days_idle === null && b.days_idle === null) return 0;
      if (a.days_idle === null) return 1;
      if (b.days_idle === null) return -1;
      return a.days_idle - b.days_idle;
    });
  }, [data.leagues, reason_filter]);

  // How many of the selected leagues have real played matches in them. This drives the
  // warning on the delete panel - deleting 40 empty shells is housekeeping, deleting one
  // league somebody played fourteen matches in is not.
  const selected_with_data = data.leagues.filter(
    (league) => selected.has(league.id) && league.fixtures_played > 0
  );

  function toggle(id: number) {
    const next = new Set(selected);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    set_selected(next);
    set_confirming(false);
  }

  // Selects everything currently visible, and only that. If a reason filter is on, this
  // does not quietly reach past it.
  function toggle_all() {
    const all_shown = visible.every((league) => selected.has(league.id));
    set_selected(all_shown ? new Set() : new Set(visible.map((league) => league.id)));
    set_confirming(false);
  }

  async function act(action: 'archive' | 'delete') {
    set_busy(true);
    set_message(null);

    const result = await run_league_action(action, Array.from(selected));

    if (result.expired) {
      router.push('/login');
      return;
    }

    set_message({ ok: result.ok, text: result.message });
    set_busy(false);

    if (result.ok) {
      set_selected(new Set());
      set_confirming(false);
      set_typed_count('');
      router.refresh();
    }
  }

  function apply_thresholds() {
    router.push(`/cleanup?idle=${Number(idle_days) || 90}&age=${Number(min_age_days) || 0}`);
  }

  return (
    <div className="space-y-4">
      {/* ------------------------------------------------------------------------- */}
      {/* Thresholds                                                                  */}
      {/* ------------------------------------------------------------------------- */}
      <div className="card flex flex-wrap items-end gap-4 p-4">
        <div>
          <label className="mb-1 block text-xs font-medium text-slate-600">
            Quiet for at least (days)
          </label>
          <input
            value={idle_days}
            onChange={(e) => set_idle_days(e.target.value)}
            className="w-24 rounded-md border border-slate-300 px-3 py-1.5 text-sm outline-none focus:border-slate-900"
          />
        </div>

        <div>
          <label className="mb-1 block text-xs font-medium text-slate-600">
            Ignore leagues newer than (days)
          </label>
          <input
            value={min_age_days}
            onChange={(e) => set_min_age_days(e.target.value)}
            className="w-24 rounded-md border border-slate-300 px-3 py-1.5 text-sm outline-none focus:border-slate-900"
          />
        </div>

        <button
          onClick={apply_thresholds}
          className="btn border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
        >
          Apply
        </button>

        <p className="ml-auto max-w-md text-xs text-slate-500">
          A league is only a candidate if it is older than the second number. Dormant leagues -
          the ones with real played matches - use twice the first number before they count.
        </p>
      </div>

      {/* ------------------------------------------------------------------------- */}
      {/* Reason chips, doubling as the summary                                       */}
      {/* ------------------------------------------------------------------------- */}
      <div className="card p-4">
        <div className="mb-3 text-sm text-slate-600">
          <span className="font-semibold text-slate-900">{data.summary.candidates}</span> leagues
          match at least one reason. A league can match several.
        </div>

        <div className="flex flex-wrap gap-2">
          {REASON_ORDER.map((reason) => {
            const count = data.summary[reason];
            const on = reason_filter === reason;

            return (
              <button
                key={reason}
                title={REASON_HELP[reason]}
                onClick={() => {
                  set_reason_filter(on ? null : reason);
                  set_selected(new Set());
                }}
                disabled={count === 0}
                className={`rounded-md border px-3 py-1.5 text-left text-xs transition-colors disabled:opacity-40 ${
                  on
                    ? 'border-slate-900 bg-slate-900 text-white'
                    : 'border-slate-300 bg-white text-slate-700 hover:border-slate-400'
                }`}
              >
                <span className="font-semibold">{count}</span> {REASON_LABELS[reason]}
              </button>
            );
          })}
        </div>
      </div>

      {/* ------------------------------------------------------------------------- */}
      {/* The action bar. Only present when something is selected.                     */}
      {/* ------------------------------------------------------------------------- */}
      {selected.size > 0 && (
        <div className="card border-slate-400 p-4">
          <div className="flex flex-wrap items-center gap-3">
            <span className="text-sm font-medium text-slate-900">
              {selected.size} selected
            </span>

            <button
              onClick={() => act('archive')}
              disabled={busy}
              className="btn border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
            >
              Archive
            </button>

            <button
              onClick={() => set_confirming(!confirming)}
              disabled={busy}
              className="btn border border-red-200 bg-white text-red-700 hover:bg-red-50"
            >
              Delete…
            </button>

            <button
              onClick={() => {
                set_selected(new Set());
                set_confirming(false);
              }}
              className="text-sm text-slate-500 hover:text-slate-900"
            >
              Clear
            </button>
          </div>

          {confirming && (
            <div className="mt-3 rounded-md border border-red-200 bg-red-50 p-3">
              <p className="text-sm text-red-800">
                This permanently deletes {selected.size}{' '}
                {selected.size === 1 ? 'league' : 'leagues'}, every fixture and membership in
                them, and any guest players left with no other league. There is no undo.
              </p>

              {/* The one case worth stopping over. Everything else on this page is empty
                  shells; these are leagues somebody actually played. */}
              {selected_with_data.length > 0 && (
                <p className="mt-2 rounded border border-red-300 bg-white px-2 py-1.5 text-sm font-medium text-red-800">
                  {selected_with_data.length} of these have played matches in them:{' '}
                  {selected_with_data
                    .slice(0, 4)
                    .map((league) => league.name)
                    .join(', ')}
                  {selected_with_data.length > 4 && ` and ${selected_with_data.length - 4} more`}.
                </p>
              )}

              <label className="mt-3 block text-xs font-medium text-red-800">
                Type <span className="font-mono">{selected.size}</span> to confirm
              </label>

              <div className="mt-1 flex gap-2">
                <input
                  value={typed_count}
                  onChange={(e) => set_typed_count(e.target.value)}
                  className="w-24 rounded-md border border-red-300 px-3 py-1.5 text-sm outline-none focus:border-red-600"
                />
                <button
                  onClick={() => act('delete')}
                  disabled={busy || typed_count.trim() !== String(selected.size)}
                  className="btn bg-red-700 text-white hover:bg-red-800"
                >
                  {busy ? 'Deleting…' : `Delete ${selected.size}`}
                </button>
              </div>
            </div>
          )}
        </div>
      )}

      {message && (
        <div
          className={`card p-3 text-sm ${
            message.ok ? 'border-green-200 bg-green-50 text-green-800' : 'border-red-200 bg-red-50 text-red-700'
          }`}
        >
          {message.text}
        </div>
      )}

      {/* ------------------------------------------------------------------------- */}
      {/* The candidates                                                              */}
      {/* ------------------------------------------------------------------------- */}
      <div className="card">
        <SectionTitle>
          {reason_filter ? REASON_LABELS[reason_filter] : 'All candidates'} ({visible.length})
        </SectionTitle>

        <div className="table-scroll">
          <table className="w-full">
            <thead className="border-b border-slate-200 bg-slate-50">
              <tr>
                <th className="th w-8">
                  <input
                    type="checkbox"
                    checked={visible.length > 0 && visible.every((l) => selected.has(l.id))}
                    onChange={toggle_all}
                    className="h-4 w-4 rounded border-slate-300"
                  />
                </th>
                <th className="th">League</th>
                <th className="th">Organiser</th>
                <th className="th">Why</th>
                <th className="th">Stage</th>
                <th className="th text-right">Members</th>
                <th className="th text-right">Fixtures</th>
                <th className="th">Created</th>
                <th className="th">Last activity</th>
              </tr>
            </thead>

            <tbody className="divide-y divide-slate-100">
              {visible.map((league) => (
                <tr
                  key={league.id}
                  className={selected.has(league.id) ? 'bg-slate-50' : 'hover:bg-slate-50'}
                >
                  <td className="td">
                    <input
                      type="checkbox"
                      checked={selected.has(league.id)}
                      onChange={() => toggle(league.id)}
                      className="h-4 w-4 rounded border-slate-300"
                    />
                  </td>

                  <td className="td">
                    <Link
                      href={`/leagues/${league.id}`}
                      className="font-medium text-slate-900 hover:text-blue-700 hover:underline"
                    >
                      {league.name}
                    </Link>
                    {league.active === false && (
                      <span className="ml-2">
                        <Pill tone="amber">archived</Pill>
                      </span>
                    )}
                  </td>

                  <td className="td text-slate-600">
                    {league.organiser_id ? (
                      <Link
                        href={`/users/${league.organiser_id}`}
                        className="hover:text-blue-700 hover:underline"
                      >
                        {league.organiser_name || `#${league.organiser_id}`}
                      </Link>
                    ) : (
                      '—'
                    )}
                  </td>

                  <td className="td">
                    <span className="inline-flex flex-wrap gap-1">
                      {league.reasons.map((reason) => (
                        <span key={reason} title={REASON_HELP[reason]}>
                          <Pill tone={REASON_TONE[reason]}>{REASON_LABELS[reason]}</Pill>
                        </span>
                      ))}
                    </span>
                  </td>

                  <td className="td">
                    <StageBadge stage={league.stage} />
                  </td>

                  <td className="td text-right tabular-nums">
                    {league.members_total}
                    {league.members_guest > 0 && (
                      <span className="ml-1 text-xs text-slate-400">
                        ({league.members_guest}g)
                      </span>
                    )}
                  </td>

                  <td className="td text-right tabular-nums">
                    {league.fixtures_total === 0 ? (
                      <span className="text-slate-300">0</span>
                    ) : (
                      <span className={league.fixtures_played > 0 ? 'font-medium text-slate-900' : ''}>
                        {league.fixtures_played}/{league.fixtures_total}
                      </span>
                    )}
                  </td>

                  <td className="td text-slate-500">{format_date(league.created_at)}</td>

                  <td className="td text-slate-500">{format_idle(league.days_idle)}</td>
                </tr>
              ))}

              {visible.length === 0 && (
                <tr>
                  <td className="td text-slate-500" colSpan={9}>
                    Nothing matches. Either the thresholds are too strict, or there is nothing
                    to clear.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
