/*
=======================================================================================================================================
API Route: public_league
=======================================================================================================================================
Method: GET  <-- deliberate exception to the POST-only rule
Purpose: Serves a public, read-only web page showing a league's standings and fixtures, at /l/<slug>.
         No login, no account, no app install. The organiser shares the link however they like -
         WhatsApp, text, pinned behind the bar - and everyone else can just look.

This is the one route in the codebase that is a GET returning HTML rather than a POST returning
JSON. That is on purpose: the whole point is that a person can paste it into a browser. Every
other endpoint follows the normal convention.

league.share_slug is the key - ten characters of Crockford base32, generated once when the league
is created and never rotated or reused. See utils/share_slug_utils.js for why it exists.

The 4-digit public_code USED to be the key, and links built on it are already out in the wild -
in group chats, in messages, pinned behind the bar. So /l/<4-digit> still works: it looks the
league up by code and redirects to its slug. Those old links must never stop resolving.

Note on privacy: a 4-digit code is a 9,000 value space, so while it was the key these pages were
enumerable by anyone who cared to walk it - 189 leagues in 9,000 values is a 1-in-48 hit rate on
a random guess. The slug is a 50-bit space, which is not walkable. That is the point of the split.
The page is still marked noindex so it stays out of search engines, and the old rule still stands
regardless: do not put anything sensitive on this page - no email addresses, no real names beyond
the nickname the player chose, no member counts of other leagues, nothing about the organiser's
account.
=======================================================================================================================================
URL: /l/7jwpbsz5ym          the league page
     /l/1234                redirects to /l/<slug> for the same league

Responses: HTML, not JSON.
  200  the league page
  302  an old 4-digit link, redirected to the league's slug
  404  nothing has that slug or that code, or the identifier is neither shape
  500  something went wrong
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { calculateStandings } = require('../utils/standings_utils');
const { normaliseShareSlug } = require('../utils/share_slug_utils');


// Escape anything that came from a user before putting it in the page
//
// League names and nicknames are typed by people, so they are untrusted. Without this,
// a league called <script>...</script> would run in the browser of everyone who opened
// the link. Never interpolate a database value into the HTML below without this.
const escapeHtml = (value) => {
  if (value === null || value === undefined) {
    return '';
  }

  return String(value)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
};


// Turn a stored nickname into something fit to show
//
// Guests are stored as 'guest_Dave'. The app strips the 'guest_' prefix before showing
// the name, so the web page does exactly the same - a player should see the same name
// in both places.
const displayName = (nickname, name) => {
  const raw = nickname || name || 'Unknown player';

  return raw.startsWith('guest_') ? raw.substring(6) : raw;
};


// Format a date for display, e.g. "Thu 14 Aug"
const formatDate = (date) => {
  if (!date) {
    return '';
  }

  return new Date(date).toLocaleDateString('en-GB', {
    weekday: 'short',
    day: 'numeric',
    month: 'short'
  });
};


// Render the score of a played fixture
//
// PTS leagues record real scores, so "5 - 3" is meaningful. WIN and WDL leagues store
// results as 1-0, 0-1 or 1-1, where a raw score would be meaningless to a reader, so
// those get words instead.
const formatResult = (fixture, winType) => {
  if (winType === 'PTS') {
    return `${fixture.player_1_score} - ${fixture.player_2_score}`;
  }

  if (fixture.player_1_score === 1 && fixture.player_2_score === 1) {
    return 'Draw';
  }

  return fixture.player_1_score === 1 ? 'Player 1' : 'Player 2';
};


// Where somebody without the app should go
//
// These are the same two URLs the app itself uses for its forced-update prompt, kept in step
// with main.dart. The Apple link needs the numeric ID; the Play link needs the package name.
const PLAY_STORE_URL = 'https://play.google.com/store/apps/details?id=com.noodev8.splitleague';
const APP_STORE_URL = 'https://apps.apple.com/app/id6745337065';


// The block that tells a stranger what this page is and what to do about it
//
// This is the whole point of the page for somebody who has just been sent a link. Before
// today it said nothing: a league name, a bare code, and a table. Somebody who had never
// heard of SplitLeague had no idea they were being invited, or that an app existed.
//
// The wording depends on whether the league has started, because the honest answer changes:
//
//   Not started - they can join. Lead with the invitation.
//   Under way   - they CANNOT join. join_league.js returns FIXTURES_EXIST once fixtures
//                 exist, so a Join prompt here would send somebody off to install the app,
//                 register, type the code and be refused at the end of it. Say so instead,
//                 and point them at the organiser.
const renderCallToAction = (league, standings, played, upcoming, hasStarted) => {

  const organiser = league.organiser ? escapeHtml(displayName(league.organiser, null)) : null;

  const stores = `
      <div class="stores">
        <a class="store" href="${PLAY_STORE_URL}">Get it on Google Play</a>
        <a class="store" href="${APP_STORE_URL}">Download on the App Store</a>
      </div>`;

  // The league has started - no joining, but the table is worth following
  if (hasStarted) {
    const total = played.length + upcoming.length;

    return `
    <section class="cta">
      <h2>This league is under way</h2>
      <p class="cta-sub">${played.length} of ${total} ${total === 1 ? 'match' : 'matches'} played${organiser ? ` &middot; organised by ${organiser}` : ''}</p>
      <p class="cta-note">New players cannot join once a league has started${organiser ? ` - ask ${organiser} to add you next time` : ''}.</p>
      ${stores}
      <p class="cta-note">Get the app to follow the table and enter your own results.</p>
    </section>`;
  }

  // The league has not started - this is an invitation
  const playerCount = standings.length;

  return `
    <section class="cta">
      <h2>You have been invited to join</h2>
      <p class="cta-sub">${organiser ? `Organised by ${organiser}` : 'A SplitLeague league'}${playerCount ? ` &middot; ${playerCount} ${playerCount === 1 ? 'player' : 'players'} so far` : ''}</p>
      ${stores}
      <p class="cta-note">Already have the app? Open it and join with code <strong class="code-inline">${escapeHtml(league.public_code)}</strong>, or tap this link again on your phone.</p>
    </section>`;
};


// The page itself
const renderPage = (league, standings, played, upcoming) => {

  const winType = league.win_type;
  const isPts = winType === 'PTS';

  // A league has started once it has fixtures at all, played or not - the same test
  // join_league.js uses to decide whether anybody new is allowed in.
  const hasStarted = (played.length + upcoming.length) > 0;

  const callToAction = renderCallToAction(league, standings, played, upcoming, hasStarted);

  // WIN leagues have no concept of a draw, so that column is dropped
  const showDrawn = winType !== 'WIN';

  // Build the standings rows
  const standingsRows = standings.map((player, index) => `
        <tr>
          <td class="pos">${index + 1}</td>
          <td class="player">${escapeHtml(displayName(player.nickname, player.name))}</td>
          <td>${player.played}</td>
          <td>${player.won}</td>
          ${showDrawn ? `<td>${player.drawn}</td>` : ''}
          <td>${player.lost}</td>
          ${isPts ? `<td>${player.score_diff > 0 ? '+' : ''}${player.score_diff}</td>` : ''}
          <td class="pts">${player.points}</td>
        </tr>`).join('');

  // Build the results rows, most recent first
  const playedRows = played.map(fixture => `
        <li>
          <span class="side">${escapeHtml(displayName(fixture.player_1_nickname, fixture.player_1_name))}</span>
          <span class="score">${escapeHtml(formatResult(fixture, winType))}</span>
          <span class="side right">${escapeHtml(displayName(fixture.player_2_nickname, fixture.player_2_name))}</span>
        </li>`).join('');

  // Build the upcoming fixtures
  const upcomingRows = upcoming.map(fixture => `
        <li>
          <span class="side">${escapeHtml(displayName(fixture.player_1_nickname, fixture.player_1_name))}</span>
          <span class="score muted">${escapeHtml(formatDate(fixture.scheduled_date)) || 'v'}</span>
          <span class="side right">${escapeHtml(displayName(fixture.player_2_nickname, fixture.player_2_name))}</span>
        </li>`).join('');

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <title>${escapeHtml(league.name)} - SplitLeague</title>
  <style>
    :root {
      --ink: #14202b;
      --muted: #667888;
      --line: #e3e9ee;
      --card: #ffffff;
      --bg: #f4f7f9;
      --brand-top: #005F8A;
      --brand-bottom: #00B3A4;
    }

    * { box-sizing: border-box; }

    body {
      margin: 0;
      background: var(--bg);
      color: var(--ink);
      font: 16px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      -webkit-text-size-adjust: 100%;
    }

    header {
      background: linear-gradient(160deg, var(--brand-top), var(--brand-bottom));
      color: #fff;
      padding: 28px 20px 24px;
    }

    .wrap { max-width: 640px; margin: 0 auto; }

    h1 {
      margin: 0 0 4px;
      font-size: 26px;
      line-height: 1.2;
      font-weight: 650;
      overflow-wrap: anywhere;
    }

    .code {
      font-size: 14px;
      opacity: .85;
    }

    main { padding: 20px; }

    section {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 12px;
      padding: 16px;
      margin-bottom: 16px;
    }

    h2 {
      margin: 0 0 12px;
      font-size: 13px;
      font-weight: 650;
      letter-spacing: .08em;
      text-transform: uppercase;
      color: var(--muted);
    }

    .scroll { overflow-x: auto; }

    table {
      width: 100%;
      border-collapse: collapse;
      font-variant-numeric: tabular-nums;
    }

    th, td {
      padding: 9px 6px;
      text-align: right;
      white-space: nowrap;
      border-bottom: 1px solid var(--line);
    }

    th {
      font-size: 12px;
      font-weight: 600;
      color: var(--muted);
    }

    tr:last-child td { border-bottom: 0; }

    .pos { width: 24px; text-align: left; color: var(--muted); }

    .player {
      text-align: left;
      width: 99%;
      white-space: normal;
      overflow-wrap: anywhere;
    }

    .pts { font-weight: 650; }

    ul { list-style: none; margin: 0; padding: 0; }

    li {
      display: flex;
      align-items: center;
      gap: 10px;
      padding: 9px 0;
      border-bottom: 1px solid var(--line);
    }

    li:last-child { border-bottom: 0; }

    .side { flex: 1; overflow-wrap: anywhere; }
    .right { text-align: right; }

    .score {
      font-variant-numeric: tabular-nums;
      font-weight: 650;
      white-space: nowrap;
    }

    .muted { color: var(--muted); font-weight: 400; }

    .empty { color: var(--muted); margin: 0; }

    .cta {
      background: var(--card);
      border: 1px solid var(--line);
      border-radius: 12px;
      padding: 20px;
      margin-bottom: 24px;
      text-align: center;
    }

    .cta h2 { margin: 0 0 6px; }

    .cta-sub {
      margin: 0 0 16px;
      color: var(--muted);
      font-size: 15px;
    }

    .cta-note {
      margin: 14px 0 0;
      color: var(--muted);
      font-size: 14px;
      line-height: 1.5;
    }

    .code-inline {
      font-variant-numeric: tabular-nums;
      letter-spacing: 1px;
      color: var(--ink);
    }

    .stores {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
      justify-content: center;
    }

    a.store {
      display: inline-block;
      padding: 12px 18px;
      border-radius: 8px;
      background: var(--brand-top);
      color: #fff;
      text-decoration: none;
      font-weight: 600;
      font-size: 15px;
    }

    a.store:hover { opacity: 0.9; }

    footer {
      text-align: center;
      padding: 4px 20px 32px;
      color: var(--muted);
      font-size: 14px;
    }

    footer a { color: var(--brand-top); }

    @media (prefers-color-scheme: dark) {
      :root {
        --ink: #e8eef3;
        --muted: #93a5b3;
        --line: #26333f;
        --card: #16202a;
        --bg: #0e161d;
      }

      footer a { color: #4dd0c4; }
    }
  </style>
</head>
<body>
  <header>
    <div class="wrap">
      <h1>${escapeHtml(league.name)}</h1>
      <div class="code">${hasStarted ? 'Under way' : `Join code ${escapeHtml(league.public_code)}`}</div>
    </div>
  </header>

  <main class="wrap">
    ${hasStarted ? '' : callToAction}
    <section>
      <h2>Standings</h2>
      ${standings.length ? `
      <div class="scroll">
        <table>
          <thead>
            <tr>
              <th class="pos"></th>
              <th class="player">Player</th>
              <th>P</th>
              <th>W</th>
              ${showDrawn ? '<th>D</th>' : ''}
              <th>L</th>
              ${isPts ? '<th>+/-</th>' : ''}
              <th class="pts">Pts</th>
            </tr>
          </thead>
          <tbody>${standingsRows}
          </tbody>
        </table>
      </div>` : '<p class="empty">No players yet.</p>'}
    </section>

    <section>
      <h2>Results</h2>
      ${played.length ? `<ul>${playedRows}
      </ul>` : '<p class="empty">No matches played yet.</p>'}
    </section>

    ${upcoming.length ? `
    <section>
      <h2>Still to play</h2>
      <ul>${upcomingRows}
      </ul>
    </section>` : ''}

    ${hasStarted ? callToAction : ''}
  </main>

  <footer class="wrap">
    Scores are kept in the SplitLeague app.
  </footer>
</body>
</html>`;
};


// The page shown when the slug or code does not match a league
const renderNotFound = () => `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex, nofollow">
  <title>League not found - SplitLeague</title>
  <style>
    body {
      margin: 0;
      min-height: 100vh;
      display: flex;
      align-items: center;
      justify-content: center;
      background: #f4f7f9;
      color: #14202b;
      font: 16px/1.6 -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      text-align: center;
      padding: 24px;
    }

    h1 { font-size: 20px; margin: 0 0 8px; }
    p { color: #667888; margin: 0; }

    @media (prefers-color-scheme: dark) {
      body { background: #0e161d; color: #e8eef3; }
      p { color: #93a5b3; }
    }
  </style>
</head>
<body>
  <div>
    <h1>League not found</h1>
    <p>Check the link and try again.</p>
  </div>
</body>
</html>`;


// GET /l/:key
//
// :key is either the league's share slug - the normal case, and what every link built from
// today onwards contains - or a 4-digit public code, which is what links shared before the slug
// existed contain. A code is answered with a redirect rather than a page, so there is exactly
// one URL that renders a league.
router.get('/:key', async (req, res) => {
  try {
    const { key } = req.params;

    // Keep search engines out of these pages regardless of the meta tag
    res.set('X-Robots-Tag', 'noindex, nofollow');

    // Two exact shapes, checked before we go anywhere near the database
    //
    // Deliberately two strict patterns rather than one permissive one. The point of the check is
    // that a scraper walking the URL space never causes a query to run, and that only survives
    // if each pattern stays as tight as it was: exactly ten slug characters, or exactly four
    // digits. Anything else is a 404 without touching Postgres.
    //
    // normaliseShareSlug does the Crockford repairs on the way in - case is ignored, and the
    // characters the alphabet leaves out are read back as the ones they look like: I and L as 1,
    // O as 0. It still returns null for anything that is not ten slug characters after that, so
    // this is no looser than a plain match; it just forgives somebody retyping a link.
    const slug = normaliseShareSlug(key);
    const byCode = /^\d{4}$/.test(key);

    if (slug === null && !byCode) {
      return res.status(404).type('html').send(renderNotFound());
    }

    // A slug that had to be repaired is not the canonical URL for this page. Send the reader to
    // the real one so there is a single address for a league, whatever they arrived holding.
    if (slug !== null && slug !== key) {
      return res.redirect(302, `/l/${slug}`);
    }

    // An old 4-digit link: find the league it belongs to and send the reader to its slug
    //
    // A 302 rather than a 301, on purpose. reset_league_fixtures rotates a league's public_code
    // and frees the old value for another league to be given, so which league a code points at
    // is not permanent - and a 301 would be cached in the reader's browser forever. 302 makes
    // the server resolve it every time, which is the only way it can stay correct.
    if (byCode) {
      // share_slug IS NOT NULL is belt and braces. The column is meant to be NOT NULL, but the
      // constraint is relaxed while a deploy is pending, and a league created in that window
      // would have no slug. Without this check the redirect would send the reader to the
      // literal URL /l/null, which is a 404 dressed up as a working link. A plain 404 here is
      // at least honest, and the backfill puts such a league right.
      const redirectResult = await pool.query(
        `SELECT share_slug FROM league
         WHERE public_code = $1 AND active = true AND share_slug IS NOT NULL`,
        [key]
      );

      if (redirectResult.rows.length === 0) {
        return res.status(404).type('html').send(renderNotFound());
      }

      return res.redirect(302, `/l/${redirectResult.rows[0].share_slug}`);
    }

    // Find the league and its scoring rules
    const leagueResult = await pool.query(
      `SELECT l.id, l.name, l.public_code, l.share_slug,
              (SELECT u.nickname FROM app_user u WHERE u.id = l.created_by) AS organiser,
              lp.win_type, lp.points_for_win, lp.points_for_draw,
              lp.points_for_win_margin, lp.points_for_close_loss, lp.win_margin_threshold
       FROM league l
       JOIN league_points lp ON l.id = lp.league_id
       WHERE l.share_slug = $1
         AND l.active = true`,
      [slug]
    );

    if (leagueResult.rows.length === 0) {
      return res.status(404).type('html').send(renderNotFound());
    }

    const league = leagueResult.rows[0];

    // Get everyone in the league, including the organiser
    // This mirrors get_league_table exactly so the two tables always agree
    const membersResult = await pool.query(
      `SELECT lm.user_id, u.name, u.nickname
       FROM league_members lm
       JOIN app_user u ON lm.user_id = u.id
       WHERE lm.league_id = $1
       UNION
       SELECT u.id as user_id, u.name, u.nickname
       FROM app_user u
       JOIN league l ON u.id = l.created_by
       WHERE l.id = $1`,
      [league.id]
    );

    // Get every fixture with both players' names attached
    const fixturesResult = await pool.query(
      `SELECT f.*,
              p1.name AS player_1_name, p1.nickname AS player_1_nickname,
              p2.name AS player_2_name, p2.nickname AS player_2_nickname
       FROM fixture f
       JOIN app_user p1 ON f.player_1_id = p1.id
       JOIN app_user p2 ON f.player_2_id = p2.id
       WHERE f.league_id = $1
       ORDER BY f.updated_at DESC NULLS LAST, f.id DESC`,
      [league.id]
    );

    const allFixtures = fixturesResult.rows;

    // Split into results and still to play
    const played = allFixtures.filter(f => f.played);

    // Upcoming reads better in the order they will be played, oldest date first
    const upcoming = allFixtures
      .filter(f => !f.played)
      .sort((a, b) => {
        if (!a.scheduled_date) return 1;
        if (!b.scheduled_date) return -1;
        return new Date(a.scheduled_date) - new Date(b.scheduled_date);
      });

    // Work out the table using the shared rules
    const standings = calculateStandings(league, membersResult.rows, played);

    return res.status(200).type('html').send(renderPage(league, standings, played, upcoming));

  } catch (error) {
    console.error('Error in public_league route:', error);

    return res.status(500).type('html').send(renderNotFound());
  }
});

module.exports = router;
