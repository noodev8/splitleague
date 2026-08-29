/*
=======================================================================================================================================
Server actions
=======================================================================================================================================
Purpose: The writes. Archiving, restoring and deleting leagues, called from the buttons on
         the league detail and cleanup pages.
=======================================================================================================================================

Why these are server actions rather than fetches from the browser
-----------------------------------------------------------------
The admin token lives in an httpOnly cookie, which page JavaScript deliberately cannot read.
A server action runs on the server with that cookie already in scope, so the button can
trigger a privileged call without the token ever being exposed to the page.

It also means the pages can be revalidated immediately afterwards, so the table you were
just looking at redraws with the league gone rather than showing a stale row.
=======================================================================================================================================
*/

'use server';

import { revalidatePath } from 'next/cache';
import { league_action, AuthError, ApiError } from '@/lib/api';

export type ActionResult = {
  ok: boolean;
  message: string;

  // True when the session has expired - the caller sends the browser to /login
  expired?: boolean;
};

/*
 * Archive, restore or delete one or more leagues.
 *
 * Deleting requires confirm: true to reach the API at all, and that flag is set here rather
 * than being passed in from the page - so there is no path where a component forgets it and
 * silently gets a different behaviour.
 */
export async function run_league_action(
  action: 'archive' | 'restore' | 'delete',
  league_ids: number[]
): Promise<ActionResult> {
  // Nothing selected. Worth saying rather than making a pointless round trip.
  if (league_ids.length === 0) {
    return { ok: false, message: 'Nothing selected' };
  }

  try {
    const result = await league_action(action, league_ids, action === 'delete');

    // Redraw every page that could be showing these leagues. The dashboard counts change
    // too, so it is included.
    revalidatePath('/');
    revalidatePath('/leagues');
    revalidatePath('/cleanup');
    revalidatePath('/users');

    const count = result.affected.length;
    const noun = count === 1 ? 'league' : 'leagues';

    // A delete says what it took with it, because that is the part you cannot check
    // afterwards - the rows are gone.
    if (action === 'delete') {
      const fixtures = result.affected.reduce((sum, a) => sum + (a.fixtures_deleted || 0), 0);
      const guests = result.affected.reduce((sum, a) => sum + (a.guests_deleted || 0), 0);

      return {
        ok: true,
        message:
          `Deleted ${count} ${noun}, ${fixtures} fixtures` +
          (guests > 0 ? ` and ${guests} guest ${guests === 1 ? 'player' : 'players'}` : ''),
      };
    }

    return {
      ok: true,
      message: action === 'archive' ? `Archived ${count} ${noun}` : `Restored ${count} ${noun}`,
    };
  } catch (error) {
    if (error instanceof AuthError) {
      return { ok: false, expired: true, message: 'Your session has expired. Sign in again.' };
    }

    if (error instanceof ApiError) {
      return { ok: false, message: error.message };
    }

    return { ok: false, message: 'Something went wrong' };
  }
}
