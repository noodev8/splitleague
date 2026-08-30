# CLAUDE.md

Guidance for Claude Code (claude.ai/code) working in this repository.

## ⚠️ Read this first: current work

**`docs/rebuild-plan.md` is the active working document.** Read it before doing anything
substantial. It holds the assessment of the codebase, the production usage analysis, the
decisions already made, the defect register, and the phased plan we are working through.

**`docs/next-ui-redesign.md` covers the look of the app.** Read it before changing any
UI. It holds the palette, the type scale, the one-filled-button-per-screen rule, and two
Flutter layout traps that have already cost time once.

Decisions already settled (do not re-litigate):
- **Fix in place — not a rewrite, and not a "SplitLeague 2" store listing.**
- Email verification is being mimicked away: mark verified on signup, send no email,
  keep the pipeline and the `verification_token` columns (password reset shares them).
- Phase 1 is a **public read-only league page** at `/l/<code>` plus lifting the 2-guest cap
  — not universal join links. Then stop and test with real people before deciding more.
- The guest data model is deliberately still open; decide it after Phase 1 ships.

## Project Overview

Sports league management app.

- **`splitleague-flutter/`** — Flutter app (Android, iOS, Web, Windows, macOS, Linux)
- **`splitleague-server/`** — Node.js Express REST API
- **PostgreSQL** — accessed directly with `pg`, no ORM

## Essential Commands

```bash
# Flutter (from splitleague-flutter/)
flutter pub get
flutter run
flutter test
flutter analyze
flutter build apk | ios | web | windows | macos      # production builds
flutter pub run flutter_launcher_icons              # after icon changes

# Server (from splitleague-server/)
npm install
npm run dev      # auto-reload
npm start
```

**Server `.env`** (gitignored): `DATABASE_URL`, `PORT`, `JWT_SECRET`, `RESEND_API_KEY`,
`FRONTEND_URL`, `EMAIL_VERIFICATION_URL`, `EMAIL_FROM`, `EMAIL_NAME`.

**Android toolchain is version-sensitive.** We are on Gradle 9.3.1, AGP 9.1.0, KGP 2.4.0,
Java 21 — the current Flutter template stack, warning-free. If a build fails, read the
actual Gradle error; the "Flutter Fix / AGP 9" panel the tool prints is usually a red
herring.

The Android build scripts are **Groovy, not Kotlin DSL** (`android/settings.gradle`,
`android/build.gradle`, `android/app/build.gradle`), and that is deliberate: AGP 9
deprecates the old `android { }` DSL at *error* level so a `.kts` script will not compile
against it, while Flutter 3.47's own Gradle plugin cannot yet run against AGP 9's new DSL.
Groovy is the only combination that builds. Keep `android.newDsl=false` and
`android.builtInKotlin=false`. Revert to `.kts` once Flutter supports the new DSL.

The root `build.gradle` raises each pub plugin's `compileSdk` to the app's after evaluation
— `fluttertoast` still declares 33, which AGP 9 rejects. Don't remove that hook.

Kotlin is compiled by **AGP's built-in Kotlin** (`android.builtInKotlin=true`), not the
Kotlin Gradle Plugin. That flag is global, so the app and every pub plugin must be on
versions that cooperate — don't downgrade `fluttertoast`, `package_info_plus`, `share_plus`
or `shared_preferences_android` below what `pubspec.yaml` pins, or the build breaks.

**`flutter_secure_storage` is pinned `>=10.0.0 <11.0.0` on purpose.** It holds the JWT, and
v11 cannot read data written by v9 — a v10 build has to ship and be widely installed first,
because v10 is what migrates that data on read. Going straight to v11 logs out every
existing user. See §6.0 of the rebuild plan.

## Database

**Source of truth is the live database.** There is no schema file to trust — the
`pg_dump` at `docs/archive/db-schema.sql` is from July 2025 and is stale.

**Querying production:** connect directly using `DATABASE_URL` from
`splitleague-server/.env`. A throwaway node script placed in `splitleague-server/` (so it
resolves `pg` and `dotenv`) is the quickest way to run read-only queries.
`fixture.updated_at` is the most reliable real-usage signal in the DB.

Seven tables: `app_user`, `league`, `league_members`, `fixture`, `league_points`,
`app_version_requirement`, `deletion_log`. Users create leagues; users join leagues
through `league_members`; fixtures belong to a league and reference two players;
`league_points` configures scoring 1:1 with a league.

Two things about the data that are not obvious and will bite:

- **Guests are rows in `app_user`** with the literal email `'guest'` and a nickname of the
  form `guest_Dave (g)`. They are placeholders for people in a league, not accounts, and
  **must never be able to log in** — the auth routes exclude them explicitly.
- **`app_version_requirement.minimum_version` is `text`, one row per platform.** Write a real
  version — `2.0.0`. A CHECK constraint enforces `major.minor[.patch]`. Raising a row is the
  lever that forces existing installs to update, and the two rows are separate so Android and
  iOS can be raised independently as each store goes live.

  It used to be `numeric(4,2)`, which stored a *decimal* while the Flutter client reads
  *dot-separated integers* — so `1.1` was stored as `1.10` and read as major 1 **minor 10**,
  locking out every `1.1.x` install. Changed to text on 2026-08-29. Never raise a row before
  the build is live and at 100% rollout on that store, or users hit a non-dismissible update
  wall with nothing to update to.

Schema changes are applied directly to PostgreSQL. There is no migration file to keep in sync.

## Conventions that differ from the defaults

These are the ones worth stating; everything else follows normal practice for the stack.

1. **Procedural, heavily commented.** Explain what the code does and why, in prose, for a
   reader coming from PowerBuilder. Lots of spacing. Not heavily object-oriented.
2. **All files lowercase with underscores** — `login_user_screen.dart`, `create_league.js`.
3. **Every endpoint is POST**, at `/function_name`. No REST verbs, no path parameters.
4. **Every response carries `return_code`** — `"SUCCESS"` or an error code — and the Flutter
   side checks that field, never the HTTP status alone.
5. **One-to-one file naming across the stack.** `routes/login_user.js` ↔
   `api/login_user_api.dart`. Adding an endpoint means adding both, plus registering it in
   `server.js`.
6. **Every route file opens with a header block** documenting method, purpose, request
   payload, success response, and the full list of return codes. Match the existing style
   in `splitleague-server/routes/`; screens carry a shorter comment saying what the screen
   is for.
7. **The design system is `lib/styles/app_palette.dart`, `app_type.dart` and the
   `lib/widgets/sl_*.dart` widgets.** Colours come from `AppPalette`, type from `AppType`,
   buttons from `SlButton` - and at most ONE filled `SlButton.primary` per screen, because
   it is what tells the user where to go next. `app_styles.dart` still exists but is only a
   compatibility layer over the palette for the few screens not yet rewritten; do not add
   to it. All UI must work with the accessibility provider (text scaling, high contrast).
   See `docs/next-ui-redesign.md`.

## Architecture

**Flutter** (`splitleague-flutter/lib/`): `api/` one file per endpoint, static methods,
`http` package · `providers/` Provider state (`LeagueProvider`, `AccessibilityProvider`) ·
`screens/` · `widgets/` · `helpers/` auth, config, error handling · `styles/` · `models/`
(minimal). JWT lives in Flutter Secure Storage, attached as `Authorization: Bearer <token>`
via `AuthHelper`. Errors go through `error_helper.dart` / `error_handler.dart`, surfaced
with `fluttertoast`.

**Express** (`splitleague-server/`): `routes/` one file per endpoint, registered in
`server.js` · `middleware/auth_middleware.js` verifies the JWT and sets `req.userId` ·
`utils/email_utils.js` wraps Resend · `db.js` holds the connection pool. Passwords are
bcrypt. Tokens last 180 days.

## Rules

1. **Parameterised queries always** (`$1, $2, ...`). Never string-concatenate SQL.
2. **Protected routes use `auth_middleware.js`** and read `req.userId`. Check
   *authorisation* too, not just authentication — most routes must confirm the user is the
   league's `created_by` before allowing a change.
3. **Changing an endpoint means changing both sides** — the route handler and its Flutter
   API file.
4. **Never let guest rows authenticate.** See the Database section.
5. Add widget tests in `test/` for new UI.
