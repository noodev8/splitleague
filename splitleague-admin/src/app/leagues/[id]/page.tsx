/*
=======================================================================================================================================
Page: /leagues/[id]
=======================================================================================================================================
Purpose: One league in full - who is in it, every fixture, the scoring configuration, and the
         archive / delete controls.
=======================================================================================================================================
*/

import { redirect, notFound } from 'next/navigation';
import Link from 'next/link';
import { get_league_detail } from '@/lib/api';
import { load } from '@/lib/load';
import { format_date, format_datetime } from '@/lib/format';
import { PageTitle, SectionTitle, StageBadge, Pill, Field, Progress, Empty } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';
import LeagueActions from '@/components/league_actions';

export const dynamic = 'force-dynamic';

export default async function LeagueDetailPage({ params }: { params: Promise<{ id: string }> }) {
  // In Next 15 the route params arrive as a promise
  const { id } = await params;
  const league_id = Number(id);

  // A non-numeric id in the URL is a 404, not a server error
  if (!Number.isInteger(league_id)) notFound();

  const result = await load(get_league_detail(league_id));

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok && result.code === 'NOT_FOUND') notFound();
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  const { league, members, fixtures, points } = result.data;

  const played = fixtures.filter((fixture) => fixture.played).length;

  return (
    <>
      <div className="mb-4">
        <Link href="/leagues" className="text-sm text-slate-500 hover:text-slate-900">
          ← All leagues
        </Link>
      </div>

      <div className="mb-5 flex flex-wrap items-center gap-3">
        <PageTitle title={league.name} />
        <div className="mb-5 flex gap-2">
          <StageBadge stage={league.stage} />
          {league.active === false && <Pill tone="amber">archived</Pill>}
        </div>
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        {/* ------------------------------------------------------------------------- */}
        {/* Left column: the facts about the league, and the controls                   */}
        {/* ------------------------------------------------------------------------- */}
        <div className="space-y-4">
          <div className="card">
            <SectionTitle>League</SectionTitle>

            <div className="divide-y divide-slate-100">
              <Field label="Id">{league.id}</Field>

              <Field label="Organiser">
                {league.organiser_id ? (
                  <Link
                    href={`/users/${league.organiser_id}`}
                    className="text-blue-700 hover:underline"
                  >
                    {league.organiser_name || `#${league.organiser_id}`}
                  </Link>
                ) : (
                  <Pill tone="red">no organiser</Pill>
                )}
              </Field>

              <Field label="Organiser email">
                <span className="text-slate-600">{league.organiser_email || '—'}</span>
              </Field>

              <Field label="Created">{format_datetime(league.created_at)}</Field>
              <Field label="Last activity">{format_datetime(league.last_activity)}</Field>

              <Field label="Join code">
                <span className="font-mono">{league.public_code || '—'}</span>
              </Field>

              <Field label="Share link">
                {/* The public page is served by the API host itself - see the /l route in
                    splitleague-server/server.js - so it is shown, not linked, because this
                    tool does not know the public hostname. */}
                <span className="font-mono text-slate-600">
                  {league.share_slug ? `/l/${league.share_slug}` : '—'}
                </span>
              </Field>

              <Field label="Code sharing">
                {league.allow_code_share ? 'allowed' : 'not allowed'}
              </Field>
            </div>
          </div>

          <div className="card">
            <SectionTitle>Scoring</SectionTitle>

            {points ? (
              <div className="divide-y divide-slate-100">
                <Field label="Win type">{points.win_type || '—'}</Field>
                <Field label="Points for a win">{points.points_for_win ?? '—'}</Field>
                <Field label="Points for a draw">{points.points_for_draw ?? '—'}</Field>
                <Field label="Win margin bonus">{points.points_for_win_margin ?? '—'}</Field>
                <Field label="Margin threshold">{points.win_margin_threshold ?? '—'}</Field>
                <Field label="Close loss bonus">{points.points_for_close_loss ?? '—'}</Field>
                <Field label="Times each pair meets">{points.play_each_other ?? '—'}</Field>
              </div>
            ) : (
              <Empty>No scoring row for this league.</Empty>
            )}
          </div>

          <div className="card border-slate-300">
            <SectionTitle>Actions</SectionTitle>
            <LeagueActions
              league_id={league.id}
              league_name={league.name}
              active={league.active !== false}
            />
          </div>
        </div>

        {/* ------------------------------------------------------------------------- */}
        {/* Right column: the people and the matches                                    */}
        {/* ------------------------------------------------------------------------- */}
        <div className="space-y-4 lg:col-span-2">
          <div className="card">
            <SectionTitle>
              Members ({members.length})
              {members.some((member) => member.is_guest) && (
                <span className="ml-2 font-normal text-slate-500">
                  {members.filter((member) => member.is_guest).length} guest
                </span>
              )}
            </SectionTitle>

            {members.length === 0 ? (
              <Empty>Nobody is in this league.</Empty>
            ) : (
              <div className="table-scroll">
                <table className="w-full">
                  <thead className="border-b border-slate-200 bg-slate-50">
                    <tr>
                      <th className="th">Name</th>
                      <th className="th">Email</th>
                      <th className="th">Joined</th>
                      <th className="th">Last opened</th>
                      <th className="th text-right">Played</th>
                      <th className="th">Notes</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {members.map((member) => (
                      <tr key={`${member.user_id}`} className="hover:bg-slate-50">
                        <td className="td">
                          {/* Guests have no detail page worth visiting - they have no
                              account, no history and nothing to show beyond this row. */}
                          {member.is_guest || !member.user_id ? (
                            <span className="text-slate-700">{member.nickname || member.name}</span>
                          ) : (
                            <Link
                              href={`/users/${member.user_id}`}
                              className="font-medium text-slate-900 hover:text-blue-700 hover:underline"
                            >
                              {member.name}
                            </Link>
                          )}

                          <span className="ml-2 inline-flex gap-1">
                            {member.is_organiser && <Pill tone="violet">organiser</Pill>}
                            {member.is_guest && <Pill>guest</Pill>}
                            {member.active === false && <Pill tone="amber">hidden</Pill>}
                          </span>
                        </td>

                        <td className="td text-slate-500">
                          {member.is_guest ? '—' : member.email}
                        </td>
                        <td className="td">{format_date(member.joined_at)}</td>
                        <td className="td">{format_date(member.last_accessed)}</td>
                        <td className="td text-right tabular-nums">
                          {member.played}/{member.fixtures}
                        </td>
                        <td className="td text-slate-500">{member.organiser_notes || '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className="card">
            <SectionTitle>
              Fixtures ({fixtures.length})
              <span className="ml-3 inline-block align-middle font-normal">
                <Progress played={played} total={fixtures.length} />
              </span>
            </SectionTitle>

            {fixtures.length === 0 ? (
              <Empty>
                No fixtures yet - this league is still being set up. Generating fixtures is the
                one-way door into &ldquo;In play&rdquo;.
              </Empty>
            ) : (
              <div className="table-scroll">
                <table className="w-full">
                  <thead className="border-b border-slate-200 bg-slate-50">
                    <tr>
                      <th className="th">Player 1</th>
                      <th className="th">Player 2</th>
                      <th className="th text-right">Score</th>
                      <th className="th">Scheduled</th>
                      <th className="th">Last updated</th>
                    </tr>
                  </thead>

                  <tbody className="divide-y divide-slate-100">
                    {fixtures.map((fixture) => (
                      <tr key={fixture.id} className="hover:bg-slate-50">
                        <td className="td">{fixture.player_1_name || '—'}</td>
                        <td className="td">{fixture.player_2_name || '—'}</td>

                        <td className="td text-right tabular-nums">
                          {fixture.played ? (
                            <span className="font-medium">
                              {fixture.player_1_score} – {fixture.player_2_score}
                            </span>
                          ) : (
                            <span className="text-slate-400">not played</span>
                          )}
                        </td>

                        <td className="td">{format_date(fixture.scheduled_date)}</td>
                        <td className="td text-slate-500">{format_date(fixture.updated_at)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
