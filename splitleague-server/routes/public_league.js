/*
=======================================================================================================================================
API Route: public_league
=======================================================================================================================================
Method: GET  <-- deliberate exception to the POST-only rule
Purpose: Serves a public, read-only web page showing a league's standings and fixtures, at /l/<code>.
         No login, no account, no app install. The organiser shares the link however they like -
         WhatsApp, text, pinned behind the bar - and everyone else can just look.

This is the one route in the codebase that is a GET returning HTML rather than a POST returning
JSON. That is on purpose: the whole point is that a person can paste it into a browser. Every
other endpoint follows the normal convention.

The 4-digit public_code is the key. There is a unique index on league.public_code so the URL can
never be ambiguous, and create_league checks against every league rather than only active ones.

Note on privacy: a 4-digit code is a 9,000 value space, so these pages are enumerable by anyone
who cares to walk it. That was a deliberate, considered trade - the content is a pub league table
of nicknames and scores, and the sharing has to be frictionless to be worth anything. The page is
marked noindex so it stays out of search engines. Do not put anything sensitive on this page:
no email addresses, no real names beyond the nickname the player chose, no member counts of other
leagues, nothing about the organiser's account.
=======================================================================================================================================
URL: /l/1234

Responses: HTML, not JSON.
  200  the league page
  404  no league with that code, or the code is not 4 digits
  500  something went wrong
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const { calculateStandings } = require('../utils/standings_utils');


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
// Guests are stored as 'guest_Dave (g)'. The app strips the prefix and keeps the (g)
// marker, so the web page does exactly the same - a player should see the same name
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


// The page itself
const renderPage = (league, standings, played, upcoming) => {

  const winType = league.win_type;
  const isPts = winType === 'PTS';

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
      <div class="code">League code ${escapeHtml(league.public_code)}</div>
    </div>
  </header>

  <main class="wrap">
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
  </main>

  <footer class="wrap">
    Scores are kept in the SplitLeague app.<br>
    Join this league with code <strong>${escapeHtml(league.public_code)}</strong>.
  </footer>
</body>
</html>`;
};


// The page shown when the code does not match a league
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
    <p>Check the 4-digit code and try again.</p>
  </div>
</body>
</html>`;


// GET /l/:code
router.get('/:code', async (req, res) => {
  try {
    const { code } = req.params;

    // Keep search engines out of these pages regardless of the meta tag
    res.set('X-Robots-Tag', 'noindex, nofollow');

    // The code is always exactly 4 digits. Rejecting anything else here means we never
    // run a query on rubbish, and a scraper walking the URL space gets nowhere.
    if (!/^\d{4}$/.test(code)) {
      return res.status(404).type('html').send(renderNotFound());
    }

    // Find the league and its scoring rules
    const leagueResult = await pool.query(
      `SELECT l.id, l.name, l.public_code,
              lp.win_type, lp.points_for_win, lp.points_for_draw,
              lp.points_for_win_margin, lp.points_for_close_loss, lp.win_margin_threshold
       FROM league l
       JOIN league_points lp ON l.id = lp.league_id
       WHERE l.public_code = $1
         AND l.active = true`,
      [code]
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
