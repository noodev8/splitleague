/*
=======================================================================================================================================
Page: / - Dashboard
=======================================================================================================================================
Purpose: The one screen that answers "is anybody using this?" - totals for users, leagues
         and fixtures, what stage the leagues are at, and twelve months of growth.
=======================================================================================================================================

The numbers are chosen to be read together
------------------------------------------
A total on its own says almost nothing. 192 leagues sounds healthy until you see that 133 of
them never got as far as generating a fixture, and 252 signups sounds healthy until you see
how many of those people never created or joined anything.

So each tile that could be read too optimistically carries the qualifier underneath it, and
the "signs of life" row is separated out at the top, because recent activity is the number
that actually tells you whether the app is alive this week.
=======================================================================================================================================
*/

import { redirect } from 'next/navigation';
import { get_stats } from '@/lib/api';
import { load } from '@/lib/load';
import { format_datetime } from '@/lib/format';
import { Stat, PageTitle, SectionTitle } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';

// Always render on request. A cached dashboard is a wrong dashboard.
export const dynamic = 'force-dynamic';

export default async function DashboardPage() {
  const result = await load(get_stats());

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  const stats = result.data;

  // How stale is the most recent sign of life? This drives the colour of the tile - a green
  // number that is three months old would be actively misleading.
  const last = stats.last_activity ? new Date(stats.last_activity) : null;
  const days_since_last = last
    ? Math.floor((Date.now() - last.getTime()) / (1000 * 60 * 60 * 24))
    : null;

  const activity_tone =
    days_since_last === null ? 'bad' : days_since_last <= 7 ? 'good' : days_since_last <= 30 ? 'warn' : 'bad';

  // The bar chart is scaled against the busiest month in the window, so the tallest bar
  // always fills the space and the shape of the trend is visible whatever the absolute
  // numbers are.
  const peak = Math.max(
    1,
    ...stats.monthly.map((month) => Math.max(month.users + month.guests, month.leagues))
  );

  return (
    <>
      <PageTitle
        title="Dashboard"
        subtitle="Everything on this page comes straight from the live database."
      />

      {/* ---------------------------------------------------------------------------- */}
      {/* Signs of life. The row that answers the actual question.                       */}
      {/* ---------------------------------------------------------------------------- */}
      <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat
          label="Last activity"
          value={
            days_since_last === null
              ? 'never'
              : days_since_last === 0
                ? 'today'
                : `${days_since_last}d ago`
          }
          hint={format_datetime(stats.last_activity)}
          tone={activity_tone}
        />
        <Stat
          label="Scores entered"
          value={stats.fixtures.updated_7d}
          hint="in the last 7 days"
          tone={stats.fixtures.updated_7d > 0 ? 'good' : 'bad'}
        />
        <Stat
          label="Scores entered"
          value={stats.fixtures.updated_30d}
          hint="in the last 30 days"
        />
        <Stat
          label="Users active"
          value={stats.users.active_30d}
          hint="opened the app in 30 days"
        />
      </div>

      {/* ---------------------------------------------------------------------------- */}
      {/* People                                                                         */}
      {/* ---------------------------------------------------------------------------- */}
      <h2 className="mb-2 text-sm font-semibold text-slate-900">People</h2>

      <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Stat label="Accounts" value={stats.users.real} hint="real, can log in" />
        <Stat label="Guests" value={stats.users.guest} hint="placeholders, cannot log in" />
        <Stat label="Organisers" value={stats.leagues.organisers} hint="have created a league" />
        <Stat
          label="Never in a league"
          value={stats.users.never_in_a_league}
          hint="signed up, did nothing"
          tone={stats.users.never_in_a_league > stats.users.real / 2 ? 'warn' : 'plain'}
        />
        <Stat label="New accounts" value={stats.users.new_30d} hint="in the last 30 days" />
      </div>

      {/* ---------------------------------------------------------------------------- */}
      {/* Leagues                                                                        */}
      {/* ---------------------------------------------------------------------------- */}
      <h2 className="mb-2 text-sm font-semibold text-slate-900">Leagues</h2>

      <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-5">
        <Stat label="Leagues" value={stats.leagues.total} hint={`${stats.memberships} memberships`} />
        <Stat
          label="Setting up"
          value={stats.leagues.setup}
          hint="no fixtures generated"
          tone="warn"
        />
        <Stat label="In play" value={stats.leagues.in_play} hint="fixtures, not all played" tone="good" />
        <Stat label="Complete" value={stats.leagues.complete} hint="every fixture played" />
        <Stat label="New leagues" value={stats.leagues.new_30d} hint="in the last 30 days" />
      </div>

      {/* ---------------------------------------------------------------------------- */}
      {/* Fixtures                                                                       */}
      {/* ---------------------------------------------------------------------------- */}
      <h2 className="mb-2 text-sm font-semibold text-slate-900">Fixtures</h2>

      <div className="mb-6 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Fixtures" value={stats.fixtures.total} />
        <Stat
          label="Played"
          value={stats.fixtures.played}
          hint={`${Math.round((stats.fixtures.played / Math.max(1, stats.fixtures.total)) * 100)}% of all fixtures`}
        />
        <Stat label="Touched in 30 days" value={stats.fixtures.updated_30d} />
        <Stat label="Touched in 90 days" value={stats.fixtures.updated_90d} />
      </div>

      {/* ---------------------------------------------------------------------------- */}
      {/* Twelve months of growth.                                                       */}
      {/*                                                                                */}
      {/* Two bars per month rather than a line chart: the two series are counts of       */}
      {/* different things, so putting them on a shared line would invite reading a       */}
      {/* relationship between them that is not there.                                    */}
      {/* ---------------------------------------------------------------------------- */}
      <div className="card mb-6">
        <SectionTitle>Last 12 months</SectionTitle>

        <div className="p-4">
          <div className="mb-3 flex items-center gap-4 text-xs text-slate-600">
            <span className="flex items-center gap-1.5">
              <span className="inline-block h-2.5 w-2.5 rounded-sm bg-slate-800" /> Accounts
            </span>
            <span className="flex items-center gap-1.5">
              <span className="inline-block h-2.5 w-2.5 rounded-sm bg-slate-300" /> Guests
            </span>
            <span className="flex items-center gap-1.5">
              <span className="inline-block h-2.5 w-2.5 rounded-sm bg-green-600" /> Leagues
            </span>
          </div>

          <div className="flex items-end gap-2 overflow-x-auto pb-1">
            {stats.monthly.map((month) => {
              const users_height = (month.users / peak) * 120;
              const guests_height = (month.guests / peak) * 120;
              const leagues_height = (month.leagues / peak) * 120;

              return (
                <div key={month.month} className="flex min-w-[52px] flex-1 flex-col items-center gap-1">
                  <div className="flex h-[120px] w-full items-end justify-center gap-1">
                    {/* Accounts and guests stack, because together they are "people added" */}
                    <div
                      className="flex w-4 flex-col justify-end"
                      title={`${month.users} accounts, ${month.guests} guests`}
                    >
                      <div
                        className="w-full rounded-t-sm bg-slate-300"
                        style={{ height: `${guests_height}px` }}
                      />
                      <div className="w-full bg-slate-800" style={{ height: `${users_height}px` }} />
                    </div>

                    <div
                      className="w-4 rounded-t-sm bg-green-600"
                      style={{ height: `${leagues_height}px` }}
                      title={`${month.leagues} leagues`}
                    />
                  </div>

                  <div className="text-[10px] tabular-nums text-slate-500">
                    {month.month.slice(2)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </>
  );
}
