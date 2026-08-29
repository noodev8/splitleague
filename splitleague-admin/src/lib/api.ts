/*
=======================================================================================================================================
Library: api.ts
=======================================================================================================================================
Purpose: The single place this tool talks to the SplitLeague API. One function per endpoint,
         mirroring splitleague-server/routes/admin_*.js one for one.
=======================================================================================================================================

The shape of every call
-----------------------
The SplitLeague API is POST-only, every endpoint is at /function_name, and every response
carries a return_code that is checked instead of the HTTP status. That is the house style on
both existing sides of this stack and this file follows it rather than inventing a third.

The one thing added here is that an expired or missing token is turned into a typed
AuthError, so pages can catch it and send the browser back to the login screen rather than
rendering an error page that says "UNAUTHORIZED" and leaves you stuck.

Caching is off on every call. This is an admin tool - a cached count is a wrong count.
=======================================================================================================================================
*/

import { get_session_token } from './session';

// Where the API lives. Set SPLITLEAGUE_API_URL in .env.local, or in the Vercel project.
const API_URL = process.env.SPLITLEAGUE_API_URL || 'http://localhost:3000';

// Thrown when the API says the token is missing, expired or not an admin token.
// Pages catch this by name and redirect to /login.
export class AuthError extends Error {
  constructor(message = 'Not signed in') {
    super(message);
    this.name = 'AuthError';
  }
}

// Thrown for anything else the API refuses to do, carrying the return_code so the page can
// say something more useful than "something went wrong".
export class ApiError extends Error {
  return_code: string;

  constructor(return_code: string, message: string) {
    super(message);
    this.name = 'ApiError';
    this.return_code = return_code;
  }
}

/*
 * Post to an admin endpoint with the signed-in admin's token attached.
 *
 * Everything this tool reads goes through here, which is why the token lookup, the header,
 * the no-cache and the return_code check all live in one function instead of being repeated
 * eight times below.
 */
async function post_admin<T>(endpoint: string, body: Record<string, unknown> = {}): Promise<T> {
  const token = await get_session_token();

  // No cookie at all - do not even make the request
  if (!token) throw new AuthError();

  let response: Response;

  try {
    response = await fetch(`${API_URL}/${endpoint}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(body),

      // Always hit the API. A dashboard that quietly serves last week's numbers is worse
      // than one that is slow.
      cache: 'no-store',
    });
  } catch {
    // The API host is unreachable - wrong URL, server down, no network
    throw new ApiError(
      'NO_CONNECTION',
      `Could not reach the SplitLeague API at ${API_URL}. Is the server running?`
    );
  }

  // A 401 or 403 means the token is no good. Both become AuthError, because from the
  // browser's point of view the answer is the same: sign in again.
  if (response.status === 401 || response.status === 403) {
    throw new AuthError();
  }

  // The body should be JSON. If it is not, something answered that was not this endpoint.
  let data: { return_code?: string; message?: string } & Record<string, unknown>;

  try {
    data = await response.json();
  } catch {
    // A 404 with an HTML body is Express saying "I have no such route", and it means one
    // specific thing: the API is running code that predates the admin routes. That is a
    // completely different problem from an unreachable host, and telling somebody to check
    // their URL when the URL is fine sends them looking in the wrong place.
    if (response.status === 404) {
      throw new ApiError('ROUTE_NOT_FOUND', route_not_found_message(endpoint));
    }

    throw new ApiError(
      'BAD_RESPONSE',
      `${API_URL}/${endpoint} answered HTTP ${response.status} but not with JSON. ` +
        `Something other than the SplitLeague API may be on that address.`
    );
  }

  // The house rule: trust return_code, not the status line
  if (data.return_code !== 'SUCCESS') {
    throw new ApiError(
      data.return_code || 'UNKNOWN',
      data.message || `${endpoint} returned ${data.return_code}`
    );
  }

  return data as T;
}

/* ===================================================================================== */
/* The types the API returns. These mirror the header blocks in the route files.          */
/* ===================================================================================== */

export type Stage = 'setup' | 'in_play' | 'complete';

export type Stats = {
  users: {
    real: number;
    guest: number;
    verified: number;
    never_in_a_league: number;
    new_30d: number;
    active_30d: number;
  };
  leagues: {
    total: number;
    setup: number;
    in_play: number;
    complete: number;
    archived: number;
    organisers: number;
    new_30d: number;
  };
  fixtures: {
    total: number;
    played: number;
    updated_7d: number;
    updated_30d: number;
    updated_90d: number;
  };
  memberships: number;
  last_activity: string | null;
  monthly: { month: string; users: number; guests: number; leagues: number }[];
};

export type LeagueRow = {
  id: number;
  name: string;
  public_code: string | null;
  share_slug: string | null;
  allow_code_share: boolean | null;
  active: boolean | null;
  created_at: string | null;
  organiser_id: number | null;
  organiser_name: string | null;
  organiser_email: string | null;
  members_total: number;
  members_real: number;
  members_guest: number;
  fixtures_total: number;
  fixtures_played: number;
  stage: Stage;
  last_activity: string | null;
  days_idle: number | null;
};

export type LeagueDetail = {
  league: {
    id: number;
    name: string;
    public_code: string | null;
    share_slug: string | null;
    allow_code_share: boolean | null;
    active: boolean | null;
    created_at: string | null;
    organiser_id: number | null;
    organiser_name: string | null;
    organiser_email: string | null;
    stage: Stage;
    last_activity: string | null;
  };
  members: {
    user_id: number | null;
    name: string | null;
    nickname: string | null;
    email: string | null;
    is_guest: boolean;
    is_organiser: boolean;
    joined_at: string | null;
    last_accessed: string | null;
    active: boolean | null;
    organiser_notes: string | null;
    fixtures: number;
    played: number;
  }[];
  fixtures: {
    id: number;
    player_1_id: number | null;
    player_1_name: string | null;
    player_2_id: number | null;
    player_2_name: string | null;
    scheduled_date: string | null;
    played: boolean | null;
    player_1_score: number | null;
    player_2_score: number | null;
    created_at: string | null;
    updated_at: string | null;
  }[];
  points: {
    points_for_win: number | null;
    points_for_draw: number | null;
    points_for_win_margin: number | null;
    points_for_close_loss: number | null;
    win_margin_threshold: number | null;
    play_each_other: number | null;
    win_type: string | null;
  } | null;
};

export type UserRow = {
  id: number;
  name: string | null;
  nickname: string | null;
  email: string | null;
  is_guest: boolean;
  email_verified: boolean | null;
  created_at: string | null;
  accessed: string | null;
  leagues_created: number;
  leagues_joined: number;
  last_activity: string | null;
  days_idle: number | null;
};

export type UserDetail = {
  user: {
    id: number;
    name: string | null;
    nickname: string | null;
    email: string | null;
    is_guest: boolean;
    email_verified: boolean | null;
    created_at: string | null;
    accessed: string | null;
  };
  leagues: {
    id: number;
    name: string;
    created_at: string | null;
    is_organiser: boolean;
    is_member: boolean;
    member_active: boolean | null;
    joined_at: string | null;
    last_accessed: string | null;
    stage: Stage;
    members_total: number;
    fixtures_total: number;
    fixtures_played: number;
  }[];
  record: { fixtures: number; played: number; last_scored: string | null };
};

export type CleanupReason =
  | 'empty'
  | 'abandoned_setup'
  | 'stalled'
  | 'dormant'
  | 'duplicate'
  | 'orphaned';

export type CleanupData = {
  thresholds: { idle_days: number; min_age_days: number };
  summary: Record<'candidates' | CleanupReason, number>;
  leagues: (Omit<LeagueRow, 'public_code' | 'share_slug' | 'allow_code_share' | 'organiser_email'> & {
    age_days: number;
    reasons: CleanupReason[];
    primary_reason: CleanupReason;
  })[];
};

/* ===================================================================================== */
/* One function per endpoint                                                              */
/* ===================================================================================== */

// The headline dashboard numbers
export function get_stats() {
  return post_admin<Stats>('admin_stats');
}

// Every league, for the leagues table
export function get_leagues() {
  return post_admin<{ leagues: LeagueRow[] }>('admin_leagues');
}

// One league in full
export function get_league_detail(league_id: number) {
  return post_admin<LeagueDetail>('admin_league_detail', { league_id });
}

// Everybody, real accounts and guests alike
export function get_users() {
  return post_admin<{ users: UserRow[] }>('admin_users');
}

// One user in full
export function get_user_detail(user_id: number) {
  return post_admin<UserDetail>('admin_user_detail', { user_id });
}

// The redundant-league shortlist, at whatever thresholds are asked for
export function get_cleanup(idle_days = 90, min_age_days = 30) {
  return post_admin<CleanupData>('admin_cleanup', { idle_days, min_age_days });
}

// Archive, restore or delete leagues. The only call in this file that writes anything.
export function league_action(
  action: 'archive' | 'restore' | 'delete',
  league_ids: number[],
  confirm = false
) {
  return post_admin<{
    action: string;
    affected: { id: number; name: string; fixtures_deleted?: number; members_deleted?: number; guests_deleted?: number }[];
    not_found: number[];
  }>('admin_league_action', { action, league_ids, confirm });
}

/*
 * Exchange the admin's email and password for a token.
 *
 * This is the one call made before there is a session, so it does not go through
 * post_admin. It never throws - it always returns something with a return_code, because the
 * login screen has to be able to show a reason for every possible failure.
 */
export async function admin_login(email: string, password: string) {
  let response: Response;

  try {
    response = await fetch(`${API_URL}/admin_login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
      cache: 'no-store',
    });
  } catch {
    // Nothing answered at all - wrong host, wrong port, server down, no network
    return {
      return_code: 'NO_CONNECTION',
      message: `Nothing is answering at ${API_URL}. Is splitleague-server running?`,
    };
  }

  try {
    return (await response.json()) as { return_code: string; token?: string; message?: string };
  } catch {
    // Reached a server, but it does not have this route - see the note in post_admin
    if (response.status === 404) {
      return { return_code: 'ROUTE_NOT_FOUND', message: route_not_found_message('admin_login') };
    }

    return {
      return_code: 'BAD_RESPONSE',
      message: `${API_URL} answered HTTP ${response.status} but not with JSON.`,
    };
  }
}

/*
 * The message for a 404 on an admin endpoint.
 *
 * Shared by both callers because it is the single most likely failure in this whole tool,
 * and the explanation is the useful part: the address is right, the server is up, it is
 * simply running a build from before these routes existed.
 */
function route_not_found_message(endpoint: string) {
  return (
    `The API at ${API_URL} is running, but has no /${endpoint} route (HTTP 404). ` +
    `It is running code from before the admin routes were added - restart splitleague-server ` +
    `locally, or deploy the admin routes to the server this points at.`
  );
}
