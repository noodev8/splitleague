# Outstanding after the share slug

Share slug is **done, deployed and live** (see `docs/next-share-slug.md`). Three things left.
Read `CLAUDE.md` first — conventions differ from the defaults.

## 1. iOS Universal Links

There is still no `ios/Runner/Runner.entitlements`. Needs the Associated Domains capability
(`applinks:splitleague.noodev8.com`) added in **Xcode on a Mac**.

The server side is already done and serving — `routes/well_known.js` returns a valid
`apple-app-site-association` with appID `43A5Y7KJMA.com.noodev8.splitleague`, paths scoped to
`/l/*`. Nothing to build server-side; this is purely the Xcode step.

## 2. The third landing-page state: *finished*

`routes/public_league.js` has two states, chosen on fixture count: not started / under way.
A league where **every** fixture is played still renders as "under way" and says
"100 of 100 matches played".

Wanted: name the winner and present the table as final. Same file, same render functions —
add a third branch alongside the existing `hasStarted` logic.

## 3. The join-code reuse defect

`routes/reset_league_fixtures.js:161` rotates `public_code` and frees the old value, which
`create_league.js` can later hand to a **different** league.

The **link half is now fixed** — `share_slug` is never rotated or reused, so shared links are
safe. What remains is the join code itself:

- **Needs a decision, not just a fix:** should resetting a league rotate the code at all now that
  links no longer depend on it?
- **Straight bug regardless:** its uniqueness check at `reset_league_fixtures.js:59` filters
  `active = true`, while `create_league.js` deliberately does not. With the unique index on
  `public_code` in place, that path can throw an uncaught `23505`.

## Also worth knowing

- The **Flutter changes are committed but not shipped** — no store release yet. Production runs
  the new server against the old app, which works via the `public_code` fallback in
  `join_league` / `get_league_preview` and the `/l/<4-digit>` → slug redirect. A store build is
  needed before anyone sees the new no-code-boxes invite screen.
- The **admin routes** (`splitleague-admin/`, `routes/admin_*.js`, `middleware/admin_middleware.js`
  and the registrations in `server.js`) are **uncommitted in-progress work** and were left alone.
  `admin_leagues.js` / `admin_league_detail.js` show `public_code` only — add `share_slug` there
  if useful.
- Test accounts: `brookfieldcomfort@gmail.com` and `aandreou25@gmail.com`, both `12345678`.
  Android test device on adb, PIN 3333. For device testing against local code:
  `adb reverse tcp:3000 tcp:<your port>` and pick "ADB Reverse" in the developer screen.
