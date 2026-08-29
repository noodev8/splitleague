# SplitLeague — Assessment & Rebuild Plan

**Written:** 2026-08-29
**Status:** Working document. We work through this in steps and tick items off.
**Decision made:** Fix and modernise in place. **Not** a rewrite, **not** a "SplitLeague 2" listing.

---

## 1. Why the verdict is "fix, not rebuild"

### 1.1 The code is not rotten

Ran `flutter analyze` against the installed **Flutter 3.47.0 / Dart 3.13.0** (stable, Aug 2026):

```
27 issues found — 0 errors, 4 warnings, 23 info
```

The 23 info items are all mechanical deprecations (`withOpacity` → `withValues`, `background`/`onBackground` → `surface`/`onSurface`). The 4 warnings are unused imports and unused private fields. **Nothing is broken.** The app compiles on today's stable Flutter as-is.

### 1.2 The architecture is the one we already chose

The backend is the same pattern we use on lmslocal right now:

- Express + `pg` with parameterised queries (`$1, $2`) throughout — no SQL injection found
- POST-only `/function_name` routes, one file per route
- `return_code` on every response
- JWT via a single `middleware/auth_middleware.js`

**Authentication is not scattered.** One middleware, one `AuthHelper` on the Flutter side, one token key in secure storage. 27 of 37 routes use `verifyToken`; the 10 that don't are the correct ones (register, login, forgot/reset password, verify email, app version).

**Authorisation was also checked, not just authentication.** Spot-checked the sensitive routes and they are correct:

| Route | Check |
|---|---|
| `update_league_name.js:91` | `league.created_by !== userId` → reject |
| `reset_league_scores.js:79` | `league.created_by !== userId` → reject |
| `remove_player_from_league.js:73` | `created_by !== organizerId` → reject |
| `add_guest_player.js:84` | `created_by !== organizerId` → reject |
| `update_fixture_score.js:70` | creator **or** one of the two players → otherwise reject |

That is better than a lot of code that ships.

### 1.3 It is small

| | Size |
|---|---|
| Flutter (`lib/`) | ~18,000 lines Dart, 77 files |
| Server | ~5,600 lines JS, 37 routes |

A rewrite would reproduce ~90% of this file-for-file on the identical stack. The cost would be: two live store listings, the `com.noodev8.splitleague` bundle IDs, the signing keys, every existing install, and a database migration we'd have to do anyway.

**The problems are product problems and a handful of specific defects. They are not architectural.**

---

## 2. Production reality

All figures queried from the live database on 2026-08-29.

### 2.1 The app has never stopped being used

This is the most important thing in this document, and it is easy to miss because the dead-league count is so high.

**Scores were entered in 16 of the 17 months since launch** (only June 2025 had none). Not signups — actual humans entering actual match results.

| Month | Scores entered | Leagues active |
|---|---|---|
| 2025-04 | 1 | 1 |
| 2025-05 | 14 | 3 |
| 2025-07 | 16 | 4 |
| 2025-08 | 37 | 3 |
| 2025-09 | 11 | 2 |
| 2025-10 | 10 | 2 |
| 2025-11 | 22 | 3 |
| 2025-12 | 23 | 4 |
| 2026-01 | 2 | 1 |
| 2026-02 | 13 | 5 |
| 2026-03 | 44 | 7 |
| 2026-04 | 10 | 4 |
| 2026-05 | 14 | 4 |
| 2026-06 | 7 | 2 |
| 2026-07 | 28 | 6 |
| 2026-08 | 1 | 1 |

**Most recent activity, as of 2026-08-29:**

| Event | When | Days ago |
|---|---|---|
| Last score entered | 2026-08-16 | 13 |
| Last member opened a league | 2026-08-24 | 5 |
| Last league created | 2026-08-24 | 5 |
| Last signup | 2026-08-24 | 5 |

Strangers signed up and created a league five days ago. This is a live product with a small, continuous user base — not a dormant one.

### 2.2 Monthly reach

Distinct users opening a league (`league_members.last_accessed`):

```
2025-08 ██████████ 21
2025-10 ███████ 14
2025-12 █████ 11
2026-01 ███████ 15
2026-02 ██████████████████ 36
2026-03 █████████████████████████ 50
2026-04 █████████████ 26
2026-05 ██████████████████████████ 53
2026-06 ████████████ 24
2026-07 ███████████ 22
2026-08 █████ 10  (partial month)
```

Real signups per month tell the same story, with a clear surge and taper:

```
2026-01 ████████████ 12
2026-02 ██████████████████████████ 26
2026-03 ██████████████████████████████████████████ 42
2026-04 ████████████████████████████ 28
2026-05 ████████████████████████████████████████████████ 48
2026-06 ████████████ 12
2026-07 █████████████ 13
2026-08 ██████ 6  (partial month)
```

**Worth understanding:** something drove Feb–May 2026 (48 signups in May alone) and it tapered off from June. If that was a store-listing change, a seasonal effect, or someone linking to it, it is worth knowing — it is the closest thing we have to an acquisition channel.

### 2.3 The funnel — where it breaks

| Stage | Count | |
|---|---|---|
| Leagues created (all time) | 188 | all still `active = true` |
| Leagues with **exactly 1 active member** | **74 of 157** | **47% — nobody ever joined** |
| Leagues with 2 members | 35 | |
| Leagues with 3 members | 39 | |
| Leagues with 4+ members | 9 | 6% |
| Leagues that ever generated fixtures | 57 | 30% |
| Leagues that ever had a score entered | 41 | 22% |
| Leagues that ever **completed** | **8** | **4%** |
| Leagues containing a fake "guest" player | 72 | the organiser's workaround |
| Real signups that never verified email | **75 of 251** | **30% lost at the door** |

Members per league:

```
1 member   ████████████████████████████████████  74
2 members  █████████████████                     35
3 members  ███████████████████                   39
4 members  █                                      3
5 members  ▏                                      1
6 members  █                                      3
7 members  ▏                                      1
11 members ▏                                      1
```

Organisers: **93 created exactly one league**, 17 created two, and a small committed tail created 3–10 each (two people created 10 apiece). **Only 22 of 122 organisers (18%) ever got a single score entered.**

### 2.4 What people actually use it for

The league names are the clearest product signal in the database. This is pub and club sport:

> FIFA Fridays · Snooker Tuesdays · Tungsten Invitational · Darts · Pool at Telepost Club · The RTG League · Nags Chess · Garden league · The Lounge league · Championship · Division 6

And when it works, it really works — leagues that ran to completion:

| League | Fixtures | Played |
|---|---|---|
| Tungsten Top 4 & J Lunt | 50 | **50** |
| Snooker | 40 | 30 |
| Fifa Fridays Championship | 27 | 20 |
| FIFA Fridays | 27 | 14 |
| The RTG League | 40 | 12 |
| Pool | 10 | **10** |
| Chess (id 12) | 11 | **11** |

The product works. The problem is purely getting the second person through the door.

### 2.5 Guests are the path that works — this reverses an earlier assumption

I initially read the 72 guest-using leagues as "organisers working around a broken join flow". The data says something more interesting.

**League composition (active members):**

| Real members | Guests | Leagues |
|---|---|---|
| 1 | 0 | **65** |
| **1** | **2** | **37** ← second most common shape |
| 1 | 1 | 15 |
| 0 | 2 | 11 |
| 0 | 1 | 9 |
| 2 | 0 | 9 |
| 3+ | 0 | 11 |

**Guest leagues engage roughly twice as well as all-real leagues:**

| | Leagues | Got fixtures | Got a score |
|---|---|---|---|
| All real members | 85 | 18 (**21%**) | 16 (**19%**) |
| Has guests | 72 | 35 (**49%**) | 22 (**31%**) |

**The 2-guest cap is hard-binding.** Of the 72 leagues using guests, **48 sit exactly on the limit** and 24 have one. Two-thirds of everyone who uses the feature is pressed against the ceiling.

```
0 guests ████████████████████████████████ 85
1 guest  █████████ 24
2 guests ██████████████████ 48   ← the cap
3+       (impossible)
```

**And the conversion theory produced nothing.** The cap existed to push guests toward real signups. In 17 months, **zero guests have ever been converted to real accounts** — all 146 guest rows still carry both `email = 'guest'` and a `guest_%` nickname.

**Why it never happened — it is structural, not just "registration was rubbish".** The feature *is* wired up (`league_members_screen.dart:402` → `convert_guest_to_user.js`), but look at what it actually requires. It is a **merge tool for the organiser, not an upgrade path for the guest**:

1. Organiser adds guest "Dave"
2. Dave independently finds the app, downloads it, registers — **and gets past the email verification wall** (where 30% fail)
3. Dave tells the organiser which email address he used
4. Organiser opens league members, finds Dave, taps convert, and types Dave's exact email
5. `convert_guest_to_user.js` returns `USER_NOT_FOUND` unless that account already exists

There is no path where a guest converts themselves, and no invite. The guest never even knows they are in a league. So the conversion rate was never going to be anything but zero — and removing the verification wall (§4.1) only fixes step 2 of five. Whatever we build next, **the guest needs a way to claim their own place**.

**What this means:** the model that actually works is *one organiser running the whole league on everyone else's behalf*. That is the pub darts captain with a notebook. Requiring every player to have an account is the friction — and the cap throttles the one mechanic that is outperforming everything else. This should change how we think about Phase 1 (see §4.2).

### 2.6 Diagnosis

1. **Half of everyone who creates a league never gets a second human into it.**
2. **30% of signups are locked out by email verification.** `login_user.js:83` returns `EMAIL_NOT_VERIFIED` and hard-blocks login.
3. **72 organisers added a fake guest** rather than get a real person in — with a 2-per-league cap (`add_guest_player.js:117`).
4. **There are no deep links at all.** Checked `AndroidManifest.xml` (only the `LAUNCHER` intent-filter) and the iOS project (no associated domains). Sending a join link is currently impossible.

Today's join path is five steps before anyone sees anything:

```
install app → register → check email → click verify → find the 4-digit code → type it in
```

---

## 3. Data cleanup — scoping

Agreed: clean up so we know where we stand. Nothing destructive runs until we have checked it together.

### 3.1 Integrity is already clean — good news

There are **no foreign keys in the database at all** (§5.2), so orphan rows were a real possibility. Checked; there are none:

| Check | Result |
|---|---|
| `league_members` → missing league | **0** |
| `league_members` → missing user | **0** |
| `fixture` → missing league | **0** |
| `fixture` → missing player | **0** |
| Leagues with no `league_points` row | **0** |
| Duplicate `public_code` among active leagues | **0** |
| Duplicate `(league_id, user_id)` membership rows | **0** |
| **Duplicate real email addresses** | **5** |

### 3.2 The 5 duplicate emails — mystery solved

They are not a bug in registration. Every one of the five pairs was created **minutes apart**, and both copies have `accessed = null`:

| Email | Gap between the two signups |
|---|---|
| `lukaszkogut26@…` | 1 min 33 s |
| `william.hallam100@…` | 1 min 24 s |
| `stephengallacher16@…` | 1 min 53 s |
| `rileybobs00@…` | 5 min 12 s |
| `carterduffy15@…` | 7 min 26 s |

This is somebody registering, not getting (or not finding) the verification email, and immediately registering again — then never getting in either time. **The verification wall caused all five.** Removing it (§4.1) removes the cause; deduping them is then just tidy-up.

### 3.3 Deletion candidates

**Leagues**

| Rule | Count | Notes |
|---|---|---|
| A — Solo (≤1 active member), **no fixtures ever**, created >90 days ago | **83** | Dead on arrival. Safe. |
| C — Has fixtures, **none ever played**, created >180 days ago | **6** | Abandoned before first score. |
| **Keep** — has a played fixture **or** ≥2 active members | **91** | The real estate. |

⚠️ **The rule must key off played fixtures, not membership.** Leagues 7, 8 and 12 have **zero active members but completed fixtures** — league 12 ("Chess") is 11 of 11 played. Members left or hid the league; the history is still real. Never delete on member count alone.

✅ **Your chess league is safe.** League 13 "Chess" (you + Dimitri, id 9) — 2 members, 15 fixtures, 6 played, last score **2026-06-10**. It has played fixtures, so it lands in "keep" under every rule above. Untouched.

**Users**

| Rule | Count | Notes |
|---|---|---|
| Unverified, no league created, no membership | **75** | Exactly the people the wall locked out. |
| No membership and no league created (any verify state) | **89** | Superset of the above. |
| Guest rows total (`email = 'guest'`) | **146** | Handle via the guest migration (§4.2), not here. |
| Guest rows **orphaned** (no membership at all) | **26** | Pure junk, delete. |

⚠️ **Do not delete on `accessed IS NULL`.** 182 of 251 real users have it null, but only 69 have it set and 62 of those are within the last year — the column was added later (see §5.6) and back-populates nothing. It is not a "never used" signal.

💡 **Consider before deleting the 75.** Once verification is gone, those accounts work. A one-off "your account is ready, just log in" email is a cheap reactivation of 75 people who already wanted the app — and a far better use of them than `DELETE`.

### 3.4 Cleanup order

- [x] Full `pg_dump` backup taken 2026-08-29 — both formats in `~/Downloads`: `splitleague.sql` (custom `PGDMP`, for `pg_restore`) and `splitleague-text.sql` (plain SQL). Verified by content, not by restore: all 7 tables present with data, row counts match production exactly (app_user 397, app_version_requirement 2, deletion_log 11, fixture 1113, league 188, league_members 388, league_points 188). **Deliberately not committed** — they hold real emails and password hashes. Keep them somewhere safe off this machine
- [ ] Review the 83 + 6 league list by name together before deleting anything
- [ ] Dedupe the 5 email pairs (both copies are unused in every case — keep the lower id)
- [ ] Delete orphaned guest rows (26)
- [ ] Delete rule-A leagues + their `league_members` / `fixture` / `league_points` rows (83)
- [ ] Delete rule-C leagues and children (6)
- [ ] Decide on the 75 locked-out accounts: reactivation email, or delete
- [ ] Re-run §2.3 and record the new baseline here

One transaction per rule, row count printed before commit.

---

## 4. Decisions

### 4.1 Email verification — mimic it, don't rip it out ✅ DECIDED

Keep the registration pipeline exactly as it is. Mark the account verified immediately on signup and send no email. Simplest possible change, smallest blast radius, no schema churn.

**Changes:**

- `register_user.js` — set `email_verified = true` on insert; stop generating a verification token; **stop calling the verification email send**
- `login_user.js` — delete the `EMAIL_NOT_VERIFIED` block (this is the actual win)
- `login_user_screen.dart:92` — remove the `EMAIL_NOT_VERIFIED` branch
- `login_user_screen.dart:148` — remove the inline resend call. Note this screen calls `/resend_verification` via a raw `http.post` rather than through `lib/api/` — tidy that up while we are in there
- `verify_email.js`, `verify_web_email.js`, `resend_verification.js` — leave the files in place for now, just unreferenced; delete in a later tidy-up once we are happy
- Data: `UPDATE app_user SET email_verified = true` for everyone

**Keep the column.** Leaving `email_verified` in place (always true) means zero schema migration and nothing else to break.

⚠️ **Do not touch `verification_token` / `verification_expires`.** Password reset reuses the same two columns:

- `forgot_password.js:70` — `UPDATE app_user SET verification_token = $1, verification_expires = $2`
- `reset_password.js:50,81` — looks them up and clears them

Since we are mimicking rather than ripping out, the earlier rename suggestion is dropped — leave them alone entirely. Less to test.

**Testing (§8 covers the full pass):** register fresh → straight in, no email. Then password reset end-to-end on `aandreou25@gmail.com` and `brookfieldcomfort@gmail.com`, because that flow shares the token columns and is the thing most likely to break.

### 4.2 Guest players — still open 🔶

**Context that changes the picture:** the 2-guest cap was a deliberate choice — restrict guests to push people toward creating real logins, with the restriction as a possible future paywall. Neither happened.

**And the data (§2.5) says the strategy backfired.** Zero guests converted to real accounts in 17 months. Meanwhile guest leagues engage at roughly twice the rate of all-real leagues (49% vs 21% reach fixtures), and 48 of the 72 guest-using leagues sit exactly on the 2-guest ceiling. The cap is throttling the one mechanic that outperforms everything else, and it bought us nothing in return.

**Lifting the cap is the single cheapest engagement win available in this codebase.** It is a one-line change (`add_guest_player.js:117`) that unblocks 48 leagues. It should arguably move into Phase 1, ahead of the deeper model rework.

**How it works today** (`add_guest_player.js:130-155`):

```javascript
const displayNickname = `guest_${baseNickname} (g)`;
const passwordHash = await bcrypt.hash('guest', saltRounds);
INSERT INTO app_user (name, nickname, email, password_hash, email_verified, created_at)
VALUES ('guest', displayNickname, 'guest', passwordHash, true)
```

**Problems, independent of which model we pick:**

1. **It is a login hole.** `login_user.js` looks up `WHERE email = $1` and takes `rows[0]`. `POST /login_user {"email":"guest","password":"guest"}` returns a valid **180-day JWT** for whichever guest row comes back first — a real member of a real league. 146 such rows exist. Small blast radius, but a universally-known credential.
2. **Identity by string prefix.** `nickname LIKE 'guest_%'` is the guest test. A real user picking a nickname starting `guest_` becomes a guest.
3. **Display name is baked into the data.** `guest_Dave (g)` is stored, not derived.
4. **The 2-per-league cap** is actively hurting the main use case — 72 leagues use guests.
5. Guests are 146 of 397 `app_user` rows (37%).

**Options:**

| Option | Shape | Pro | Con |
|---|---|---|---|
| **A — keep in `app_user`, done properly** (the lmslocal approach) | `is_guest boolean`, `email NULL`, `password_hash NULL`, real nickname | One player table; fixtures/standings joins unchanged; guest→real conversion is an UPDATE and `convert_guest_to_user.js` already exists | `app_user` holds rows that can never log in; every auth query must exclude them |
| **B — guest lives on `league_members`** | nullable `user_id` + `guest_name` | Cleanest model; a guest genuinely *is* "a name in a league" | `fixture.player_1_id` → `app_user.id` breaks; needs a player-identity rethink across fixtures and standings |
| **C — separate `guest_player` table** | Own table, own ids | Explicit | Two id spaces for players; every fixture/standings query becomes a union. Worst of both. |

**Non-negotiable whichever we pick:** `guest` / `guest` stops being a valid login, and the cap goes.

**✅ DECIDED — public read-only league page.** Rather than universal links plus install-survival plus onboarding, Phase 1 ships a public read-only league page at `splitleague.noodev8.com/l/<code>`. Far cheaper, and it fits what people already do: the captain enters the scores, everyone else just wants to look. Signing up becomes optional — for players who want to enter their own results.

It is also the right move regardless of which guest model we land on, which is why it goes first. **We are not committing to a hard route beyond this.** Ship the cap removal and the league view, get it in front of real people, feel the flow, then decide the guest model on evidence rather than in the abstract.

**On monetisation.** Getting users first is right — the funnel data says we do not yet have a product to charge for. When the question comes back, the guest cap is now proven to be a limit people genuinely hit (48 leagues on it), which makes it *tempting* as a paywall. I would still not use it: it is the mechanic doing the most work for engagement, and throttling it is what produced the current numbers. Better candidates later are organiser-side and appear after people are hooked — multiple concurrent leagues, season history and archives, or a club/venue tier. Never charge for getting the next player in.

### 4.3 UI redesign — no wholesale redesign 🔶 PARTIAL

The UI is competent Material 3 and is not what is costing us the 74 dead leagues. But see §6 — the theme is a Material 2/3 hybrid and is worth rebuilding properly. **Modernise the theme, redesign the onboarding path, leave the rest.**

---

## 5. Defect register

### 5.1 Guest login hole ✅ FIXED 2026-08-29
§4.2(1). Independent of the model decision. 146 rows share a guessable credential that mints a 180-day token.

Two locks, so that removing either one does not reopen it:

- [x] `login_user.js` excludes guest rows outright — `AND LOWER(email) <> 'guest'`. Guest rows are placeholders for people in a league, not accounts, and can never log in
- [x] `add_guest_player.js` no longer mints `bcrypt.hash('guest')`. New guest rows get `crypto.randomBytes(32)` hashed, so no password matches even if the filter above were removed
- [x] Same exclusion applied to `forgot_password.js` and `resend_verification.js` — same hole class, both would otherwise act on guest rows
- [ ] Scramble `password_hash` on the **146 existing** guest rows. They still carry the old `bcrypt('guest')` hash. Unreachable now that login refuses them, so this is defence in depth rather than urgent — and safe, since guests never log in and `convert_guest_to_user` sets a fresh password anyway

**Verified against production data, server running locally:**

| Request | Response |
|---|---|
| `POST /login_user {"email":"guest","password":"guest"}` | `INVALID_CREDENTIALS` |
| `POST /login_user {"email":"GUEST","password":"guest"}` | `INVALID_CREDENTIALS` (case-folded) |
| `POST /forgot_password {"email":"guest"}` | `EMAIL_NOT_FOUND` |
| Login query against a real account | resolves, 1 row |
| Login query against `'guest'` | 0 rows of 146 |

### 5.2 The database has primary keys and nothing else
Every table has a `_pkey` and that is all. No foreign keys, no unique indexes, no secondary indexes.

- [ ] Unique index on `app_user.email` (dedupe the 5 first; allow NULL for guests)
- [ ] Unique index on `league.public_code` — today it is an app-level check against *active* leagues only (`create_league.js:72`), so a collision is a live race
- [ ] Unique index on `league_members (league_id, user_id)`
- [ ] FKs: `league_members.league_id`, `league_members.user_id`, `fixture.league_id`, `fixture.player_1_id`, `fixture.player_2_id`, `league_points.league_id`, `league.created_by`
- [ ] Indexes on `league_members.league_id`, `league_members.user_id`, `fixture.league_id`

### 5.3 No server hardening
`server.js:17` is `app.use(cors())` — fully open — with no rate limiting and no `helmet`, on public `/login_user`, `/register_user`, `/forgot_password`.

- [ ] `express-rate-limit` on auth routes
- [ ] `helmet`
- [ ] CORS allowlist

### 5.4 Version gate compares a stale constant ✅ FIXED 2026-08-29
`config.dart:13` was `static const String appVersion = '1.10';` while `pubspec.yaml` says `1.1.2+112`. `version_helper.dart` compared that hardcoded string to the server minimum. It failed open, so nobody was locked out — and forced update only worked if you remembered to hand-bump the constant.

The mechanism itself was fine: `splash_screen.dart:150` → `VersionHelper.isAppVersionValid()` → POST `/get_app_version` → compare against `app_version_requirement`. Non-dismissible dialog, store link, `SystemNavigator.pop()`. Fails open on any server or network error. **Raising the database row is the lever that forces existing installs to update, and it works.**

- [x] Read the version from `package_info_plus` (pinned to `^9.0.1` — v10+ needs `win32 ^6`, which collides with `flutter_secure_storage` 9; the v11 upgrade in §6 clears that)
- [x] `Config.appVersion` is now loaded in `main()` from `PackageInfo.fromPlatform()`, i.e. straight from `pubspec.yaml`. Do not hardcode it again
- [x] Version comparison hardened: tolerates `1.1.2+112`, `2.0.0-beta`, and the old two-digit `1.05` database values; a segment that is not a number counts as 0 instead of throwing
- [x] Fails open on a blank/unreadable version and on a blank server minimum

**Two things this now demands, verified by running the comparison over the real values:**

| Running build reports | DB minimum | Result |
|---|---|---|
| `1.1.2` (real, new) | `1.01` android | allowed |
| `1.1.2` (real, new) | `1.05` ios | **BLOCKED** |
| `1.10` (legacy hardcoded) | `1.0.0` | allowed |
| `1.10` (legacy hardcoded) | `2.0.0` | **BLOCKED** ← this is the force |

1. ✅ **APPLIED 2026-08-29 — both rows lowered to `1.00`** (`android` was `1.01`, `ios` was `1.05`). Without this, an iOS build reporting its real `1.1.2` would lose to `1.05` and walk every iOS user into the update wall. A no-op for anything in the field today: every shipped build reports the hardcoded `1.10`, which clears both old and new values.
2. **The rebuild release should ship as `2.0.0`.** Legacy installs all report `1.10`, which beats any `1.x` minimum below `1.10` — so no `1.x` floor can ever force them. `2.0.0` does, cleanly. `numeric(4,2)` can hold `2.00`, so this works either way.

**⚠️ `minimum_version` is `numeric(4,2)`, not text.** This is why the scheme was ever `1.01`/`1.05` — they are decimals, not versions. `1.0.0` is literally not storable, which is why the rows read `1.00`. Two consequences:

- Nothing beyond `major.minor` fits. A minimum of `2.1.3` cannot be expressed at all, and `99.99` is the ceiling.
- **The formats disagree about what `1.10` means.** As a decimal it is one-point-one; our client parser reads it as major 1, minor 10. Today that is harmless (it is exactly what makes the legacy hardcoded `1.10` clear a `1.00` floor), but it is a trap the first time someone types a decimal minimum meaning one-point-one.

**Decision: the column becomes `text` eventually, but not while it could break live users.** ✅ DECIDED 2026-08-29 — deferred to **Phase 4**, gated on the `2.0.0` forced update having landed. Until then we live with `numeric(4,2)`. The forcing plan does not need the change:

| Running build reports | DB minimum `2.00` | Result |
|---|---|---|
| `1.10` (legacy hardcoded) | `2.00` | **BLOCKED** ← the force works |
| `2.0.0` (rebuild release) | `2.00` | allowed |

**What we live with until then:** minimums are `major.minor` only, capped at `99.99`. Set the row to `2.00` — never `2.0.0`, which the column rejects outright. The client parser already handles both, so only the database side is constrained.

### 5.5 `node_modules` is committed to git ✅ FIXED
**599 of 917 tracked files**, despite `.gitignore` listing `node_modules/` — they were added before the ignore rule.

- [x] `git rm -r --cached splitleague-server/node_modules` and commit — done in `efb73bc`. 0 tracked now, 320 files total

### 5.6 DDL on the hot path ✅ FIXED 2026-08-29
`update_user_accessed.js:48-65` queried `information_schema` and conditionally ran `ALTER TABLE app_user ADD COLUMN accessed` **on every single call** — i.e. every time anyone opens the app. It also explains why `accessed` is unreliable for old accounts (§3.3).

- [x] Deleted the check. Confirmed against production first: `app_user.accessed` exists, `timestamp with time zone`
- [x] Collapsed the route from three queries to one — the existence check is now `UPDATE ... RETURNING id`, and no row back means the account behind the token is gone (same `UNAUTHORIZED` response as before)

### 5.7 Dead weight
- `models/sample_league.dart` (239) + `sample_fixtures_screen.dart` (491) + `sample_standings_screen.dart` (508) = **1,238 lines of fake data** powering "Take a look around" — 7% of the Dart codebase serving the worst onboarding step
- `.gitignore` still references `splitdine_server` / `splitdine_flutter` — copied from another project
- Unused: `_isLoadingNotes` (`league_details_screen.dart:46`), `_leagueProvider` (`league_members_screen.dart:47`), two unused imports in `league_members_screen.dart`

### 5.8 Joining is blocked once fixtures exist
`join_league.js:104` returns `FIXTURES_EXIST`. A latecomer can never be added to a running league. Either allow joining with fixtures regenerated, or give the organiser an explicit "add player and rebuild fixtures" action.

---

## 6. Flutter upgrade — what is actually there

### 6.0 Android toolchain — was blocking all builds ✅ FIXED 2026-08-29

`flutter build` failed outright. The "Flutter Fix / AGP 9" panel the tool prints is a red herring — `android.newDsl=false` and `android.builtInKotlin=false` are already set. The real cause is that Flutter 3.47 enforces **hard error floors** in `DependencyVersionChecker.kt`, and the project was under three of them at once. Gradle just failed first.

| | Was | Errors below | Warns below | Flutter template | **Set to** |
|---|---|---|---|---|---|
| Gradle | 8.10.2 | **8.14.0** | 9.1.0 | 9.3.1 | **8.14.3** |
| AGP | 8.7.0 | **8.11.1** | 9.0.1 | 9.1.0 | **8.11.1** |
| Kotlin (KGP) | 2.1.0 | **2.2.20** | 2.3.20 | 2.4.0 | **2.2.20** |
| Java | 21 ✅ | 17 | 17 | — | 21 |

Deliberately took the **clear-the-floor** option, not the full template stack: it keeps the old Gradle DSL the `build.gradle.kts` files are written in, keeps `newDsl=false`, and touches no dependencies. Verified: `flutter build apk --debug` ✅ and `flutter build appbundle --release` ✅ (signed, 54.3 MB).

Three "will soon be dropped" warnings remain (one per row above). They are advisory. Going warning-free means Gradle 9.3.1 / AGP 9.1.0 / KGP 2.4.0 — that belongs in Phase 3, alongside the dependency majors, because `fluttertoast` 8.2.12 still declares Groovy `compileSdkVersion 33` in its own build file and is the most likely thing to break under AGP 9.

Also noted, not fixed: `namespace` is still `com.example.splitleague_flutter` (harmless — `applicationId` is correctly `com.noodev8.splitleague`), and `main.dart` carries a dead `AuthWrapper` with a duplicate copy of the version check that nothing routes to (`home:` is `SplashScreen`) — dead weight for §5.7.

### 6.1 Everything else

**We are already on the latest Flutter.** Installed SDK is 3.47.0 stable / Dart 3.13.0, and the project analyses clean against it. There is no version jump to make and no upgrade cliff.

**On the "major UI changes":** I checked the installed SDK's Material library directly (`packages/flutter/lib/src/material/`, 184 files). There is **no Material 3 Expressive widget set in it** — no `ButtonGroup`, no `SplitButton`, no FAB menu, no new `LoadingIndicator`. The only "expressive" thing present is `DynamicSchemeVariant.expressive`, a colour-scheme variant for `ColorScheme.fromSeed` that has been available for a while. There is no big new widget vocabulary waiting for us.

**What is genuinely worth doing:**

- [ ] **Rebuild the theme.** `main.dart:51` still uses `primarySwatch: Colors.indigo` (Material 2) alongside a hand-built `ColorScheme.light(primary:, secondary:)`. It is a hybrid. Replace with a single `ColorScheme.fromSeed(...)`, optionally `DynamicSchemeVariant.expressive`, and let the app derive from it. **This is the change that will actually make it look current.**
- [ ] Clear the 23 deprecations: `withOpacity` → `withValues`, `background`/`onBackground` → `surface`/`onSurface` (`accessibility_provider.dart:69-70`), `value` → `initialValue` (`developer_screen.dart:261`)
- [ ] **Drop `pull_to_refresh`.** Unmaintained since 2021, used in only **2 files**; built-in `RefreshIndicator` replaces it. This removes our one genuinely risky dependency.
- [ ] Take the held-back majors: `flutter_secure_storage` 9 → 11, `fluttertoast` 8 → 10, `intl` 0.19 → 0.20. (`flutter_secure_storage_macos` and `js` are both flagged **discontinued** in the current resolution; the v11 upgrade clears the first.)
- [ ] Raise `IPHONEOS_DEPLOYMENT_TARGET` from 12.0 if the new deps require it

---

## 7. Documentation and repo layout

Organised the same way as lmslocal: hyphenated folders, `docs/` at the repo root, `CLAUDE.md` stays at root, superseded material in `docs/archive/`. **`splitleague_library/` is gone** — everything from it now lives under `docs/`.

```
splitleague/
  CLAUDE.md
  splitleague-server/        ← was splitleague_server
  splitleague-flutter/       ← was splitleague_flutter
  docs/
    rebuild-plan.md            ← this file
    deploy.txt                 ← pm2 deploy steps (includes a one-time rename step)
    db-details.txt
    responsive.txt
    appstore-testers.txt
    splitleague-brief.docx
    graphics/                  ← was splitleague_library/Graphics
    screenshots/               ← was splitleague_library/Screenshot
      ios-screenshots/
    archive/                   ← to be deleted once we are confident
      project-guidelines.txt     superseded by CLAUDE.md
      db-schema.sql              pg_dump from Jul 2025, stale; we go direct to the DB now
      query-get_league_fixtures.txt
      query-get_organiser_leagues.txt
```

**Naming rule** (matches lmslocal): folders use hyphens, but the Dart package name in `pubspec.yaml` stays `splitleague_flutter` — Dart package names cannot contain hyphens, so every `package:splitleague_flutter/...` import is unaffected. `package.json` name is now `splitleague-server`.

**Done:**
- [x] `docs/` created, all documentation and assets moved in, `splitleague_library/` removed
- [x] Folders renamed to hyphens; references updated in `CLAUDE.md`, `.gitignore`, `deploy.txt`, `package.json`
- [x] `node_modules` untracked — tracked file count went from 917 to 318
- [x] CLAUDE.md no longer points at a schema file; it points at the live database

**Still to do:**
- [ ] Trim `CLAUDE.md` further — cut the API-rules boilerplate down to the conventions that actually differ from default: POST-only, `return_code`, one-to-one route↔api file naming, extensive comments
- [ ] Delete `docs/archive/` once we are confident nothing in it is needed

---

## 8. The plan, in shippable steps

Each phase stands alone and can go to the stores independently.

### Phase 0 — Groundwork (no user-visible change)
- [x] `docs/` folder created, docs moved, archive set up
- [x] Full `pg_dump` backup taken 2026-08-29 — both formats in `~/Downloads`: `splitleague.sql` (custom `PGDMP`, for `pg_restore`) and `splitleague-text.sql` (plain SQL). Verified by content, not by restore: all 7 tables present with data, row counts match production exactly (app_user 397, app_version_requirement 2, deletion_log 11, fixture 1113, league 188, league_members 388, league_points 188). **Deliberately not committed** — they hold real emails and password hashes. Keep them somewhere safe off this machine
- [x] Untrack `node_modules` (§5.5) — done in commit `efb73bc`; 0 tracked, repo down to 320 files
- [x] Trim `CLAUDE.md` (§7) — 334 lines to 121
- [x] Unblock the Android build — Gradle/AGP/Kotlin floors (§6.0)
- [x] Version gate reads the real app version (§5.4) — moved up from Phase 4, because forcing existing users onto the rebuild depends on it
- [x] Lower both `app_version_requirement` rows to `1.00` (§5.4) — defuses the iOS update-wall landmine
- [x] ~~Convert `minimum_version` to `text`~~ — deferred to Phase 4 (§5.4); not needed for the `2.0.0` force
- [x] Fix the guest login hole (§5.1) — urgent, and independent of the guest model decision
- [x] Remove the DDL-on-hot-path (§5.6)
- [x] **Verified on a real device 2026-08-29** — logged in, reset a password, created a competition. Covers the three things Phase 0 could have broken: the app reads its real version at startup without tripping the update dialog, login still works through the modified guest-excluding query, and the reset flow still works through `forgot_password`. (This is Phase 0 sign-off, not the §9 Phase 1 test pass — that one re-runs after the email-verification change.)
- [x] ~~Data cleanup (§3.4)~~ — **moved to Phase 4**. Deleting dead leagues now would corrupt the very baseline Phase 1 is measured against (§2.3, §2.5)

### Phase 1 — The funnel (the whole ballgame)
- [x] **Email verification mimicked away** (§4.1) — recovers 30% of signups. Done 2026-08-29

  Server: `register_user.js` creates the account with `email_verified = true`, no token, no email send (the now-unused `email_utils` require went too). `login_user.js` no longer has the `EMAIL_NOT_VERIFIED` gate, and it is off the return-code list.

  App: removed the `EMAIL_NOT_VERIFIED` dialog and the raw `http.post` to `/resend_verification` from `login_user_screen.dart` — with those gone the screen no longer bypasses `lib/api/`, and its `http`, `dart:convert` and `Config` imports went with them. **The bigger fix was in `register_user_screen.dart`:** registration has always returned a JWT, but the app threw it away, showed "check your email to verify your account" and dropped the user back at the login screen. It now saves the token and goes straight to the dashboard, exactly as login does. That dialog *was* the funnel leak, as much as the server gate.

  Data: `UPDATE app_user SET email_verified = true` — **75 rows**, matching §2.3 exactly. Those are 75 real people who signed up and could never log in. Verified afterwards that `verification_token` / `verification_expires` were untouched (74 rows still populated) — password reset shares those two columns.

  **End-to-end tested against production data on a local server:**

  | Step | Result |
  |---|---|
  | Register a fresh account | `SUCCESS`, token returned |
  | Row state on insert | `email_verified=true`, both token columns `NULL` |
  | Log straight in | `SUCCESS` — this was `EMAIL_NOT_VERIFIED` before |
  | `forgot_password` | `SUCCESS`, writes `verification_token` |
  | `reset_password` with that token | `SUCCESS` |
  | Log in with the new password | `SUCCESS` |
  | Log in with the old password | `INVALID_CREDENTIALS` |

  No verification email is attempted anywhere in the flow. The throwaway test account was checked for references and deleted; `app_user` is back to 397.

  Left in place as the plan specifies: `verify_email.js`, `verify_web_email.js`, `resend_verification.js` are unreferenced but not deleted, and `lib/api/resend_verification_api.dart` with them. Tidy later.
- [x] **Lift the 2-guest cap** (§4.2) — done 2026-08-29. Removed the count check in `add_guest_player.js`, dropped `GUEST_LIMIT_REACHED` from the route header and return codes, and left a comment recording *why* the cap went so nobody reinstates it. The Flutter branch handling that code in `player_list_screen.dart:256` is now dead but harmless, and is left in place so older installs still talking to this server behave sanely. **Not yet device-tested**
- [x] **Public read-only league page** at `splitleague.noodev8.com/l/<code>` — standings and fixtures, no login, shareable by any means (WhatsApp, text, pinned in the pub). Decided in §4.2. Built 2026-08-29, **server side only — not yet deployed, and the in-app share button is still to do**

  **✅ DECIDED — the 4-digit code is the URL key.** Considered a separate unguessable share slug and an opt-in `allow_code_share` gate, and rejected both: the code is the thing people already say out loud, and a second identifier or a dark-by-default rollout undercuts the point. The trade accepted knowingly: 4 digits is a 9,000 value space, so the pages are enumerable and every league is publicly readable by anyone who walks it. Content is a pub league table of nicknames and scores. Mitigated with `noindex` + `X-Robots-Tag`, and a strict 4-digit check so a scraper never reaches a query on rubbish. **Nothing sensitive goes on this page** — no emails, no real names beyond the chosen nickname.

  **Prerequisite done first:** unique index `league_public_code_key` on `league.public_code` (from §5.2, pulled forward — the URL is ambiguous without it). Pre-checked for collisions: none of the 189 codes were duplicated. `create_league.js` now checks codes against *every* league rather than only active ones, and catches Postgres `23505` on insert so the create-race returns `CODE_GENERATION_FAILED` instead of a 500. That race silently produced duplicate codes before.

  **Scoring lives in one place now.** Extracted the ~180-line standings algorithm out of `get_league_table.js` into `utils/standings_utils.js`, which both the app route and the public page call — so the table on a shared link can never drift from the table in the app. **Verified byte-identical:** ran the old inline algorithm and the extracted util against all 189 production leagues (41 with played fixtures, covering all three scoring types — 75 PTS, 75 WDL, 39 WIN). Zero mismatches.

  **Verified locally against production data:** all three scoring types render (PTS/WDL/WIN); `0000`, `abcd`, `12345`, `<script>` and an SQL-injection-shaped code all 404; `X-Robots-Tag` present; guest names show as `Nadir (g)` exactly as the app displays them, with the `guest_` prefix stripped and not leaking anywhere into the HTML. Every user-supplied value is HTML-escaped on the way out — league names and nicknames are untrusted input.
- [x] Share button in the app that copies/sends that link — done 2026-08-29. `share_plus` 12.0.2 (v13 needs a newer Dart than our constraints allow), opening the native share sheet with "<league name> - live table and results:" and the URL. Built from `Config.baseUrl`, so a debug build pointed at the test VPS shares a test link rather than a production one.

  **Placed deliberately outside the `!hasFixtures` block** in `details_tab_content.dart`. The join code is hidden once a league starts — but that is exactly when people want the table, so sharing has to keep working for the life of the league. Getting this wrong would have made the feature useless for every league that is actually running.

  Verified on a real device: share sheet opens with `Ver 2 Test - live table and results: https://splitleague.noodev8.com/l/5374`, with WhatsApp, Gmail and Copy offered.

- [x] Guest players no longer get a ` (g)` suffix baked into the stored nickname (`add_guest_player.js`). The `guest_` prefix stays — it is how guests are identified — but it was already stripped for display, whereas ` (g)` was not, so every guest read as "Dave (g)". **147 of 149 existing guests still carry the old suffix**, so leagues will show a mix until those rows are updated. Safe to strip: nothing parses it.
- [x] Removed the success toast after adding a guest — the player appearing in the list is the confirmation.
- [x] **Delete "Take a look around"** and the 1,238 lines behind it (§5.7) — the real league page replaces the fake demo. Done 2026-08-29: **1,299 lines removed, 4 added**

  Gone: `models/sample_league.dart` (239), `screens/sample_fixtures_screen.dart` (491), `screens/sample_standings_screen.dart` (508), the "Take a look around" button and `_handleGuestAccess` on the login screen, and the "View Sample League" button, `_showSampleLeague` and the Guest-branch ternaries in the dashboard empty state.

  **Deliberately left:** the remaining unauthenticated-session plumbing — `_userData = {'nickname': 'Guest'}` when no token is found (`dashboard_screen.dart:145`), the `isGuest` checks that show a login prompt, and the `userData == null || nickname == 'Guest'` guards in `create_league_screen.dart:74` and `join_league_screen.dart:50`. With the entry point gone this is unreachable via the old browse mode, but the `userData == null` half still guards a genuine broken-session state (token expired mid-use), so ripping it out is a behaviour change rather than a deletion. Worth a separate tidy later; it is not sample data.

  Verified: `flutter analyze` 0 errors, 0 new warnings (the 4 that remain are the pre-existing §5.7 ones in other files), debug APK builds, installed on a real device and the app launches to the dashboard with the session intact and no update dialog. The login screen change is verified by compile and grep rather than visually — confirming it on screen means logging the account out.
- [ ] Keep the 4-digit code as the manual join fallback — it works, it is just not the front door

**Then stop and feel it.** Get it in front of real people before deciding anything else. The guest model (§4.2) and whether we ever need app links at all are both decisions to make on evidence after this ships.

**Success measure:** re-run §2.3 and §2.5. Numbers to move: "leagues with exactly 1 member" (currently 47%) and "all real leagues reaching fixtures" (currently 21%).

### Phase 2 — Guests done properly
- [ ] **Decide the model** (§4.2) — informed by what Phase 1 does to the numbers
- [ ] Migrate the 146 existing guest rows
- [ ] Remove `nickname LIKE 'guest_%'` identification and the `(g)` mangling
- [ ] Decide whether `convert_guest_to_user` is worth keeping at all — it has never once been used (§2.5)
- [ ] Revisit `FIXTURES_EXIST` blocking joins (§5.8)

### Phase 3 — Flutter and theme modernisation
- [ ] Everything in §6

### Phase 4 — Hardening
- [ ] FKs, unique indexes, indexes (§5.2)
- [ ] Rate limiting, helmet, CORS allowlist (§5.3)
- [x] ~~Version gate from real package version (§5.4)~~ — done in Phase 0
- [ ] Convert `app_version_requirement.minimum_version` from `numeric(4,2)` to `text` (§5.4). **Precondition: the `2.0.0` forced update has landed and legacy installs are off `1.10`** — until then the change could affect live users, so it waits. Afterwards it is a type change only: the route already calls `.toString()`, and the client parser handles both formats
- [ ] Real tests — `test/` currently holds one widget test for `FixtureCard` from April 2025
- [ ] **Data cleanup (§3.4)** — moved here from Phase 0. It waits until the Phase 1 success measure has been re-run, because deleting dead leagues changes the numbers we are measuring against. Still to be reviewed together before anything is deleted
- [ ] Scramble `password_hash` on the 146 existing guest rows (§5.1) — defence in depth

---

## 9. Test accounts and test pass

Known accounts in production:

| id | Name | Email | Note |
|---|---|---|---|
| 2 | Andreas Andreou | `aandreou25@gmail.com` | **note: 25, not 24** |
| 9 | Dimitri | `dimitriandreou1511@hotmail.co.uk` | chess league opponent |
| 11 | Carol | `carolandreou2712@hotmail.com` | |

Also available for testing: `brookfieldcomfort@gmail.com` (no account yet — good as the fresh-registration case).

**Test pass for Phase 1 auth changes:**

- [ ] Register brand new with `brookfieldcomfort@gmail.com` → lands straight in the app, no email sent, no verification screen
- [ ] Log out, log back in with the new account
- [ ] Existing account `aandreou25@gmail.com` still logs in normally
- [ ] **Password reset end-to-end** on `aandreou25@gmail.com` — request, receive email, click link, set new password, log in with it. This shares the `verification_token` columns and is the flow most likely to break
- [ ] Password reset for an address that does not exist → no crash, no user enumeration
- [ ] `change_password` from inside the app still works
- [ ] Confirm no verification emails are being sent from Resend after the change
- [ ] Chess league (id 13) still loads with its 6 played fixtures intact

---

## Appendix — how the numbers were obtained

Read-only queries against the production database on 2026-08-29, run through throwaway node scripts using the server's existing `pg` dependency and `DATABASE_URL`. Not committed. Definitions:

- "Real user" = `app_user` where `email IS DISTINCT FROM 'guest'`
- "Active member" = `league_members.active = true`
- "Completed league" = `bool_and(fixture.played)` over that league's fixtures
- "Score entered" uses `fixture.updated_at`, which `update_fixture_score.js:153` sets to `NOW()` — the most reliable real-usage signal in the database
- Members-per-league percentages are against the 157 leagues with at least one active member, not all 188

Re-run after Phase 0 cleanup and after Phase 1 ships; record both baselines here.
