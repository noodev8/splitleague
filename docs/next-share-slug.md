# Next task: the share slug

Read `docs/rebuild-plan.md` §"Phase 1.5" first — the decision and reasoning are there.
This file is just the handover.

## What is already done

Deep links work end to end on Android, tested on a real device.
`/l/<4-digit-code>` opens the app on the join screen with the code filled in; on desktop
or without the app it opens a public landing page.

- `splitleague-server/routes/well_known.js` — assetlinks.json + apple-app-site-association, deployed
- `splitleague-server/routes/public_league.js` — the public page, two states (not started / under way)
- `splitleague-server/routes/get_league_preview.js` — league name, organiser, player count from a code
- `splitleague-flutter/lib/helpers/deep_link_helper.dart` — cold start parks the code, dashboard collects it
- `splitleague-flutter/lib/helpers/share_helper.dart` — builds the shared message
- `splitleague-flutter/lib/screens/join_league_screen.dart` — invite header + Join button
- Android manifest intent-filter, iOS `Runner.entitlements` — both committed

## What to build

The public URL is currently the 4-digit join code, so every league page is enumerable
(189 leagues in a 9,000 space) and one identifier is doing two unrelated jobs.

Split them:

- **4-digit `public_code`** stays as the say-it-out-loud join code, typed by hand
- **new `league.share_slug`** (~10 chars Crockford base32, generated once, never rotated,
  never reused) becomes the key for `/l/<slug>`
- `/l/<4-digit>` redirects to `/l/<slug>` so links already sent out keep working
- backfill all existing leagues; generate on create

**The user chose option B for the app side:** `join_league` should accept the slug too, so
an invite screen reached from a link shows *no* code boxes — just the league name,
organiser and a Join button. Someone who followed a link never sees a code. This also
removes the last assumption that the identifier is 4 characters long.

## Things that will bite

- `public_league.js` guards on `^\d{4}$` before touching the database, deliberately, so a
  scraper never reaches a query. Widen it to two exact patterns — do not loosen it to one
  permissive one.
- `deep_link_helper.dart` extracts `pathSegments[1]` and treats it as a join code. That
  assumption has to go.
- `PinInput` is structurally four boxes. The slug path wants a different widget, not a
  longer PIN.
- The Android intent-filter uses `pathPrefix="/l/"`, so it already covers slugs. No manifest
  change needed.
- `reset_league_fixtures.js:161` rotates `public_code` and returns the old value to the
  pool, where `create_league.js` can hand it to a different league — so a shared link can
  resolve to a stranger's league. The slug fixes the link half (never rotated). The
  join-code half still needs a decision. Its uniqueness check also filters `active = true`
  while `create_league.js` does not, so it can throw an uncaught `23505`.

## How this project works

- Read `CLAUDE.md` — conventions differ from the defaults (POST-only routes, `return_code`
  on every response, one file per endpoint on both sides, heavy prose comments).
- Schema changes go straight to production PostgreSQL. There is no migration file.
  Connect with `DATABASE_URL` from `splitleague-server/.env`.
- Server changes need deploying: `docs/deploy.txt`. The Flutter app talks to production.
- Test device: Android phone on adb. Test leagues: `1231` (not started), `9810` (League 2).
