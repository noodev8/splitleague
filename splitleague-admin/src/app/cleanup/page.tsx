/*
=======================================================================================================================================
Page: /cleanup
=======================================================================================================================================
Purpose: The shortlist of leagues that look redundant, each one with the evidence for why,
         and the controls to archive or delete them in bulk.
=======================================================================================================================================

The thresholds are in the URL
-----------------------------
?idle=90&age=30 - so a particular view of the cleanup list can be bookmarked or sent to
somebody, and so that changing them is a page load rather than hidden client state that
disagrees with what the server counted.
=======================================================================================================================================
*/

import { redirect } from 'next/navigation';
import { get_cleanup } from '@/lib/api';
import { load } from '@/lib/load';
import { PageTitle } from '@/components/ui';
import ErrorPanel from '@/components/error_panel';
import CleanupView from './cleanup_view';

export const dynamic = 'force-dynamic';

export default async function CleanupPage({
  searchParams,
}: {
  searchParams: Promise<{ idle?: string; age?: string }>;
}) {
  const params = await searchParams;

  // Fall back to the defaults on anything that is not a sensible number, rather than
  // erroring - a hand-edited URL should still show the page.
  const idle_days = Number(params.idle) > 0 ? Number(params.idle) : 90;
  const min_age_days = Number(params.age) >= 0 ? Number(params.age) : 30;

  const result = await load(get_cleanup(idle_days, min_age_days));

  if (!result.ok && result.expired) redirect('/login');
  if (!result.ok) return <ErrorPanel code={result.code} message={result.error} />;

  return (
    <>
      <PageTitle
        title="Cleanup"
        subtitle="Leagues that look redundant, and why. Nothing here is deleted until you say so."
      />

      <CleanupView data={result.data} />
    </>
  );
}
