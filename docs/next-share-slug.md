# The share slug — built 2026-08-29

Read `docs/rebuild-plan.md` §"Phase 1.5" for the decision and reasoning. This file is the
handover: what got built, what is verified, and the one step still outstanding.

## The one thing still to do

**Deploy the server (`docs/deploy.txt`), then put the NOT NULL back on `league.share_slug`.**

The column was added, backfilled and made NOT NULL against production; the constraint was then
**deliberately relaxed again**, because the production server still runs the old `create_league`,
which does not write a slug — with NOT NULL in place nobody could create a league in the gap
between the schema change and the deploy.

So, after `pm2 restart splitleague_prod`:

```sql
-- Anything created during the gap has no slug; give it one first.
-- (Run from a throwaway node script in splitleague-server/ so it resolves pg and dotenv,
--  using generateUniqueShareSlug from utils/share_slug_utils.js.)
UPDATE league SET share_slug = <generated> WHERE share_slug IS NULL;

ALTER TABLE league ALTER COLUMN share_slug SET NOT NULL;
```

Check first: `SELECT count(*) FROM league WHERE share_slug IS NULL;` — if it is 0, the ALTER is
the only statement needed.

## What was built

### Database (applied to production)

- `league.share_slug varchar(16)` — ten characters of Crockford base32, lowercase.
- All **192** existing leagues backfilled: 192 distinct, 0 malformed.
- `CREATE UNIQUE INDEX league_share_slug_key ON league (share_slug)`.
- NOT NULL added, then relaxed until deploy — see above.

### Server

- **`utils/share_slug_utils.js`** — new. Generation (`crypto.randomInt`, never `Math.random`),
  `normaliseShareSlug` (Crockford repairs: case ignored, `i`/`l` → `1`, `o` → `0`),
  `isShareSlug`, `resolveLeagueKey` (works out whether an identifier is a slug or a code and
  returns the column to look it up against), and `generateUniqueShareSlug`.
- **`create_league.js`** — generates the slug inside the transaction, so a league cannot exist
  without one. A slug failure rolls the create back and returns `CODE_GENERATION_FAILED`.
- **`copy_league.js`** — a copy gets its **own** slug. It must not inherit the original's: a link
  already shared for the original has to keep pointing at the original.
- **`public_league.js`** — `/l/<slug>` renders the page; `/l/<4-digit>` **302 redirects** to the
  league's slug so links already in the wild keep working. A 302 not a 301, because
  `reset_league_fixtures` rotates codes, so a cached permanent redirect would eventually lie.
  A slug that needed Crockford repair redirects to its canonical lowercase URL.
  The guard is still **two exact patterns**, never one permissive one — nothing reaches Postgres
  unless it is exactly ten slug characters or exactly four digits.
- **`join_league.js` and `get_league_preview.js`** — accept `league_key`, holding either shape.
  Both still read `public_code` as a fallback, because installs already on people's phones only
  know about that field and the server updates before the app does.
- **`reset_league_fixtures.js`** — a comment saying `share_slug` must never be rotated here, and
  why. No behaviour change.
- **`get_league_info`, `get_user_leagues`, `get_hidden_leagues`, `update_league_name`** — all now
  return `share_slug`, which is what the app builds share links from.

### Flutter

- **`share_helper.dart`** — the link is `/l/<share_slug>`. If no slug is in hand it shares
  **nothing**, rather than quietly falling back to the fragile code link the slug replaces.
- **`deep_link_helper.dart`** — the path segment is now an opaque *league key*, passed through
  untouched. `extractCode` → `extractLeagueKey`, `_pendingCode` → `_pendingKey`. No length or
  shape check anywhere: the server decides.
- **`join_league_screen.dart`** — option B, as chosen. Arriving from a link shows **no code
  boxes at all**: league name, organiser, player count, one button. Typing a code still gets the
  four boxes. Three headings — "You've been invited", "You're already in" (button reads
  *Open League*), and "Already under way" for a league with fixtures, which shows no Join button
  and says to ask the organiser instead, because `join_league` would refuse with
  `FIXTURES_EXIST`.
- **`pin_input.dart`** — `initialValue` removed. It existed to pre-fill a code out of a link, and
  a link no longer carries a code to pre-fill.
- **`test/share_slug_test.dart`** — new. Pins down the two assumptions that were wrong before:
  the identifier is opaque, and a link arrival sees no PIN boxes.

## Verified

**Server, against production data, on a locally run instance:**

- `/l/<slug>` renders both landing-page states (not started, under way).
- **All 192** active leagues: `/l/<4-digit>` → 302 → the right slug. Every one.
- Guard: `0000`, `abcd`, `12345`, 9 and 11 character slugs, `<script>`, an SQL-injection-shaped
  code and an all-`i` string all 404 without a query.
- `NKC63VHZD4` → 302 → `/l/nkc63vhzd4`; a slug retyped with `l` for `1` repairs to the real one.
- `get_league_preview` and `join_league` answer correctly for a slug, an uppercase slug, a
  4-digit code, and the legacy `public_code` field; an under-way league still returns
  `FIXTURES_EXIST` whichever identifier reached it.

**On a real Android device** (debug build pointed at the local server over `adb reverse`):

- Cold start from `/l/nkc63vhzd4` on a fresh install → login screen → after login the dashboard
  collected the parked key → **"You've been invited / Ver 2 Test / Organised by Andreas /
  4 players so far", no code boxes** → Join → the league appeared on the dashboard.
- Warm resume from an under-way league's link → "Already under way", no Join button,
  "ask Andreas".
- The legacy `/l/5374` link → same screen, "You're already in" / *Open League*.
- The typed route still shows the four boxes and its Join button stays disabled until complete.
- Share sheet opens from the details screen with the invite wording and a `/l/<slug>` URL.

`flutter analyze` clean, `flutter test` 12 passing.

The test join was undone afterwards — Brookfield's membership of league 201 was removed, leaving
the data as it was found.

## Still open, deliberately

- **iOS Universal Links.** Unchanged by this work and still needs Xcode on a Mac. The server
  side has been ready since the deep-link work.
- **The third landing-page state, *finished*.** A league with every fixture played still renders
  as "under way".
- **The join-code reuse defect.** `reset_league_fixtures.js:161` still rotates `public_code` and
  frees the old value for `create_league` to hand to a different league. The slug fixes the
  *link* half of this permanently — links are never rotated and never reused. The *join code*
  half still needs a decision. Its uniqueness check also still filters `active = true` while
  `create_league` does not, so it can throw an uncaught `23505`.
- **The admin routes** (`admin_leagues.js`, `admin_league_detail.js`) show `public_code` and were
  left alone — they are in-progress work, not part of this.
