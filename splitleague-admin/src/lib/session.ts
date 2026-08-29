/*
=======================================================================================================================================
Library: session.ts
=======================================================================================================================================
Purpose: Holds the admin's JWT in an httpOnly cookie and reads it back on the server.
=======================================================================================================================================

Why a cookie rather than localStorage
-------------------------------------
Every page in this tool renders on the server and calls the SplitLeague API from there. For
that to work the token has to arrive with the request, and only a cookie does that - a token
in localStorage is invisible to a server component.

httpOnly then follows for free, and it is worth having: this token can delete leagues, and
an httpOnly cookie cannot be read by any script on the page. It is sent automatically, used
on the server, and never touched by browser JavaScript at all.
=======================================================================================================================================
*/

import { cookies } from 'next/headers';

// The cookie name. One place, because the middleware, the login route and the API client
// all have to agree on it.
export const SESSION_COOKIE = 'sl_admin_token';

// Seven days, matching the expiry the server puts inside the token itself. If the two ever
// disagree the shorter one wins in practice - the API rejects an expired token no matter
// how long the browser was willing to keep the cookie.
export const SESSION_MAX_AGE = 60 * 60 * 24 * 7;

// Read the admin's token on the server. Returns null when nobody is signed in.
export async function get_session_token(): Promise<string | null> {
  const jar = await cookies();
  return jar.get(SESSION_COOKIE)?.value ?? null;
}
