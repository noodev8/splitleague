/*
=======================================================================================================================================
middleware.ts
=======================================================================================================================================
Purpose: Keeps signed-out visitors out of the tool.

This is the outer door, not the lock. All it checks is whether a session cookie is present -
it does not verify the signature, because the real check happens on every API call anyway
and the SplitLeague API is the only thing that can actually hand data over.

So a forged cookie gets you as far as an empty page that immediately bounces you back to
/login when the first API call returns UNAUTHORIZED. What this middleware buys is the
ordinary case: no cookie, no flash of an admin screen.
=======================================================================================================================================
*/

import { NextResponse, type NextRequest } from 'next/server';

const SESSION_COOKIE = 'sl_admin_token';

export function middleware(request: NextRequest) {
  const has_session = Boolean(request.cookies.get(SESSION_COOKIE)?.value);
  const is_login_page = request.nextUrl.pathname === '/login';

  // Not signed in, and asking for anything other than the login page
  if (!has_session && !is_login_page) {
    return NextResponse.redirect(new URL('/login', request.url));
  }

  // Already signed in and going to the login page - send them to the dashboard instead
  if (has_session && is_login_page) {
    return NextResponse.redirect(new URL('/', request.url));
  }

  return NextResponse.next();
}

export const config = {
  // Everything except Next's own assets and the session endpoint. /api/session has to stay
  // reachable while signed out, or there would be no way to sign in.
  matcher: ['/((?!api/session|_next/static|_next/image|favicon.ico).*)'],
};
