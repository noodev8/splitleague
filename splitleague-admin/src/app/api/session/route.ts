/*
=======================================================================================================================================
Route: /api/session
=======================================================================================================================================
Purpose: Signs the admin in and out.

  POST   { email, password }  ->  exchanges them for a token and sets the session cookie
  DELETE                      ->  clears the cookie

Why the browser does not talk to the SplitLeague API directly
-------------------------------------------------------------
It could, but then the token would come back into page JavaScript and would have to be
stored somewhere the browser can read - which means it can also be read by anything else
running on the page, and means a server component cannot see it at all.

Going through this route instead, the token is handed from the API to this server, put
straight into an httpOnly cookie, and never exists in the browser as a readable value.
=======================================================================================================================================
*/

import { NextResponse } from 'next/server';
import { admin_login } from '@/lib/api';
import { SESSION_COOKIE, SESSION_MAX_AGE } from '@/lib/session';

// POST /api/session - sign in
export async function POST(request: Request) {
  let email = '';
  let password = '';

  try {
    const body = await request.json();
    email = String(body.email || '');
    password = String(body.password || '');
  } catch {
    return NextResponse.json(
      { return_code: 'MISSING_FIELDS', message: 'Email and password are required' },
      { status: 400 }
    );
  }

  // Ask the SplitLeague API. It owns the credentials, not this app.
  //
  // admin_login never throws - it returns a return_code for every failure, including the
  // ones that are not about credentials at all - so its message is passed straight through
  // below rather than being flattened into one generic "could not reach" here. That
  // flattening is exactly what made a 404 on the route look like an unreachable server.
  const result = await admin_login(email, password);

  // Wrong credentials, or the API could not answer properly. The message is passed through
  // as-is; admin_login deliberately does not say which half of a bad credential was wrong.
  if (result.return_code !== 'SUCCESS' || !result.token) {
    // A problem reaching or talking to the API is not the same as a rejected password, and
    // the status should not claim it is.
    const is_upstream_problem = ['NO_CONNECTION', 'ROUTE_NOT_FOUND', 'BAD_RESPONSE'].includes(
      result.return_code
    );

    return NextResponse.json(
      { return_code: result.return_code, message: result.message || 'Sign in failed' },
      { status: is_upstream_problem ? 502 : 401 }
    );
  }

  const response = NextResponse.json({ return_code: 'SUCCESS' });

  response.cookies.set({
    name: SESSION_COOKIE,
    value: result.token,

    // Not readable by page scripts
    httpOnly: true,

    // Only sent over https once deployed. Left off locally, where there is no https.
    secure: process.env.NODE_ENV === 'production',

    // The tool makes no cross-site requests, so there is no reason to send this anywhere else
    sameSite: 'lax',

    path: '/',
    maxAge: SESSION_MAX_AGE,
  });

  return response;
}

// DELETE /api/session - sign out
export async function DELETE() {
  const response = NextResponse.json({ return_code: 'SUCCESS' });

  // Expire the cookie rather than just forgetting it, so the browser drops it immediately
  response.cookies.set({
    name: SESSION_COOKIE,
    value: '',
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    maxAge: 0,
  });

  return response;
}
