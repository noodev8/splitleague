/*
=======================================================================================================================================
Library: load.ts
=======================================================================================================================================
Purpose: One way for every page to fetch its data and deal with the two things that can go
         wrong - the session has expired, or the API is unreachable.
=======================================================================================================================================

Why this is not just a try/catch in each page
---------------------------------------------
Next's redirect() works by throwing, so calling it inside a catch block that also catches
everything else is a trap: the redirect gets swallowed by its own error handling. Separating
"work out what happened" from "act on it" avoids that entirely - this function only ever
returns, and the page decides what to do with the answer.
=======================================================================================================================================
*/

import { AuthError, ApiError } from './api';

export type Loaded<T> =
  | { ok: true; data: T }
  | { ok: false; expired: true }
  | { ok: false; expired: false; error: string; code: string };

/*
 * Await an API call and describe the outcome instead of throwing.
 *
 * Pages then do:
 *
 *   const result = await load(get_stats());
 *   if (!result.ok && result.expired) redirect('/login');
 *   if (!result.ok) return <ErrorPanel ... />;
 */
export async function load<T>(promise: Promise<T>): Promise<Loaded<T>> {
  try {
    return { ok: true, data: await promise };
  } catch (error) {
    // The token is missing, expired, or is not an admin token
    if (error instanceof AuthError) {
      return { ok: false, expired: true };
    }

    // The API answered, but refused
    if (error instanceof ApiError) {
      return { ok: false, expired: false, error: error.message, code: error.return_code };
    }

    // Anything else - a bug in this app, most likely
    return {
      ok: false,
      expired: false,
      error: error instanceof Error ? error.message : 'Unknown error',
      code: 'UNEXPECTED',
    };
  }
}
