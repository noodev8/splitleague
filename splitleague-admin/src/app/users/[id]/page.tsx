/*
=======================================================================================================================================
Page: /users/[id]
=======================================================================================================================================
Purpose: One person - their account details, every league they organise or belong to, and
         their playing record.
=======================================================================================================================================
*/

import { redirect, notFound } from 'next/navigation';
import Link from 'next/link';
import { get_user_detail } from '@/lib/api';
import { load } from '@/lib/load';
import { format_date, format_datetime } from '@/lib/format';
import { PageTitle, SectionTitle, StageBadge, Pill, Field, Stat, Progress, Empty } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';

export const dynamic = 'force-dynamic';

export default async function UserDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const user_id = Number(id);

  if (!Number.isInteger(user_id)) notFound();

  const result = await load(get_user_detail(user_id));

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok && result.code === 'NOT_FOUND') notFound();
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  const { user, leagues, record } = result.data;

  const organised = leagues.filter((league) => league.is_organiser).length;

  return (
    <>
      <div className="mb-4">
        <Link href="/users" className="text-sm text-slate-500 hover:text-slate-900">
          ← All users
        </Link>
      </div>

      <div className="mb-5 flex flex-wrap items-center gap-3">
        <PageTitle title={user.is_guest ? user.nickname || user.name || 'Guest' : user.name || `User ${user.id}`} />
        <div className="mb-5">{user.is_guest && <Pill>guest player</Pill>}</div>
      </div>

      {/* A guest is a placeholder, and saying so plainly is more useful than letting the
          empty email and never-signed-in fields imply something is broken. */}
      {user.is_guest && (
        <div className="card mb-4 border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
          This is a guest placeholder, not an account. It was added to a league by an organiser
          so that somebody without the app could be included, and it cannot be logged into.
        </div>
      )}

      <div className="mb-5 grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Leagues organised" value={organised} />
        <Stat label="Leagues in" value={leagues.length} hint="organised or joined" />
        <Stat label="Fixtures" value={record.fixtures} hint={`${record.played} played`} />
        <Stat label="Last score entered" value={format_date(record.last_scored)} />
      </div>

      <div className="grid gap-4 lg:grid-cols-3">
        <div className="card h-fit">
          <SectionTitle>Account</SectionTitle>

          <div className="divide-y divide-slate-100">
            <Field label="Id">{user.id}</Field>
            <Field label="Name">{user.name || '—'}</Field>
            <Field label="Nickname">{user.nickname || '—'}</Field>
            <Field label="Email">
              <span className="text-slate-600">{user.is_guest ? '— (guest)' : user.email || '—'}</span>
            </Field>
            <Field label="Verified">{user.email_verified ? 'yes' : 'no'}</Field>
            <Field label="Signed up">{format_datetime(user.created_at)}</Field>
            <Field label="Last opened app">{format_datetime(user.accessed)}</Field>
          </div>
        </div>

        <div className="card lg:col-span-2">
          <SectionTitle>Leagues ({leagues.length})</SectionTitle>

          {leagues.length === 0 ? (
            <Empty>
              This person is not in a single league - they signed up and stopped there.
            </Empty>
          ) : (
            <div className="table-scroll">
              <table className="w-full">
                <thead className="border-b border-slate-200 bg-slate-50">
                  <tr>
                    <th className="th">League</th>
                    <th className="th">Role</th>
                    <th className="th">Stage</th>
                    <th className="th text-right">Members</th>
                    <th className="th">Fixtures</th>
                    <th className="th">Last opened</th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-slate-100">
                  {leagues.map((league) => (
                    <tr key={league.id} className="hover:bg-slate-50">
                      <td className="td">
                        <Link
                          href={`/leagues/${league.id}`}
                          className="font-medium text-slate-900 hover:text-blue-700 hover:underline"
                        >
                          {league.name}
                        </Link>
                      </td>

                      <td className="td">
                        <span className="inline-flex gap-1">
                          {league.is_organiser && <Pill tone="violet">organiser</Pill>}
                          {league.is_member && !league.is_organiser && <Pill>member</Pill>}
                          {/* Created it but is not in it. Rare, and worth seeing. */}
                          {!league.is_member && <Pill tone="amber">not a member</Pill>}
                          {league.member_active === false && <Pill tone="amber">hidden</Pill>}
                        </span>
                      </td>

                      <td className="td">
                        <StageBadge stage={league.stage} />
                      </td>

                      <td className="td text-right tabular-nums">{league.members_total}</td>

                      <td className="td">
                        <Progress played={league.fixtures_played} total={league.fixtures_total} />
                      </td>

                      <td className="td text-slate-500">{format_date(league.last_accessed)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </>
  );
}
