/*
=======================================================================================================================================
Page: /leagues
=======================================================================================================================================
Purpose: Every league in one sortable table - who runs it, how many people are in it, what
         stage it is at, how far through its fixtures it is, and when it was last touched.
=======================================================================================================================================
*/

import { redirect } from 'next/navigation';
import { get_leagues } from '@/lib/api';
import { load } from '@/lib/load';
import { PageTitle } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';
import LeaguesTable from './leagues_table';

export const dynamic = 'force-dynamic';

export default async function LeaguesPage() {
  const result = await load(get_leagues());

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  const leagues = result.data.leagues;

  return (
    <>
      <PageTitle
        title="Leagues"
        subtitle={`${leagues.length} leagues. Click a name for members, fixtures and scoring.`}
      />

      {/* The table itself is a client component - sorting and filtering happen in the
          browser. See components/data_table.tsx for why. */}
      <LeaguesTable leagues={leagues} />
    </>
  );
}
