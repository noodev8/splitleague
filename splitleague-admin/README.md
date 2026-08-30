# splitleague-admin

Internal admin tool for SplitLeague. Read the numbers, browse the leagues and users, and
clear out the redundant leagues.

Next.js 15 (App Router) + Tailwind v4 + TypeScript. It holds no database connection of its
own — everything comes from `admin_*` endpoints on the existing SplitLeague API.

---

## The password

There is one administrator, no sign-up, and no password reset. The credentials are **not in
this repository** — the server reads `ADMIN_EMAIL` and `ADMIN_PASSWORD_HASH` from
`splitleague-server/.env`, which is gitignored, and `admin_login.js` has no fallback: if
they are unset, every login is refused.

`ADMIN_PASSWORD_HASH` is a bcrypt hash, so the password itself is written down nowhere in
this project. **Keep it in a password manager** — losing it means setting a new hash.

To set or change it:

```bash
cd splitleague-server
node -e "console.log(require('bcrypt').hashSync('your new password', 10))"
```

Paste the output into `ADMIN_PASSWORD_HASH` in `splitleague-server/.env`, set the same
variable wherever the server is hosted, and restart the server.

> An earlier version of this README and of `admin_login.js` carried the plaintext password
> in the file. It is in the git history, so that password must be treated as public and
> replaced with a new one.

---

## Running it locally

The admin tool talks to `splitleague-server`, so that has to be running too.

```bash
# terminal 1 - the API
cd splitleague-server
npm run dev                      # port 3000 by default

# terminal 2 - the admin tool
cd splitleague-admin
npm install
npm run dev                      # http://localhost:3001
```

`.env.local` holds the one setting:

```
SPLITLEAGUE_API_URL=http://localhost:3000
```

Point it at the live API instead if you want local pages against production data.

---

## Deploying

**The server has to go out first.** The admin endpoints are new route files in
`splitleague-server`, and until they are live on the API host, the deployed admin tool has
nothing to talk to.

```bash
# on the server, the usual routine from docs/deploy.txt
cd /apps/splitleague/ && git pull
rsync ... /apps/production/splitleague-server/
cd /apps/production/splitleague-server && npm install
pm2 restart splitleague_prod
```

Then Vercel:

1. New project, root directory `splitleague-admin`.
2. Set `SPLITLEAGUE_API_URL` to the live API base URL, no trailing slash.
3. Deploy.

Nothing else is needed — the framework, build command and output are all detected.

### One thing to know about deploying this

The admin endpoints are on the public API, reachable by anyone who knows the URL. They are
protected by an admin JWT that ordinary user tokens cannot satisfy (see
`middleware/admin_middleware.js`), so the protection is the password — which is why it is a
long random one. If that ever feels too thin, the next step is IP-restricting the `/admin_*`
paths at the reverse proxy in front of the API.

---

## What each page shows

| Page | What it answers |
|---|---|
| **Dashboard** | Is anybody using this? Totals, stage breakdown, 12 months of growth. The top row is recent activity, because that is the real question. |
| **Leagues** | Every league — organiser, members, stage, fixture progress, last activity. Sortable, searchable, filterable. |
| **League detail** | Members with join and last-opened dates, every fixture and score, the scoring config, and the archive/delete controls. |
| **Users** | Everyone. Guests hidden by default. Shows who organises, who joined, who signed up and never did anything. |
| **User detail** | One person's leagues and playing record. |
| **Cleanup** | The redundant-league shortlist, with the reason for each, and bulk archive/delete. |

### League stage

Straight from the app's own rule (`lib/helpers/league_stage.dart`): **no fixtures → Setting
up**, **fixtures exist → In play**. The admin tool adds a third, **Complete** — fixtures
exist and every one is played — which the app does not model but which is the difference
between a league that finished and one that stalled.

### Cleanup reasons

| Reason | Means |
|---|---|
| Never started | No fixtures, one member or fewer. The biggest bucket by far. |
| Abandoned in setup | Players added, fixtures never generated, gone quiet. |
| Stalled, no scores | Fixtures generated, not one score ever entered, gone quiet. |
| Dormant | Was genuinely played, then stopped. **Real data in here — be slower to delete.** |
| Duplicate name | Same name and organiser as another league. Usually a `copy_league` artefact. |
| No organiser | `created_by` points at an account that no longer exists. |

Thresholds are in the URL: `/cleanup?idle=90&age=30`. Leagues younger than `age` days are
excluded entirely, so a league created last week never shows up as junk. Dormant leagues use
twice `idle` before they count.

---

## Archiving vs deleting

**Archive** sets `league.active = false`. Reversible with Restore. Reach for this first.

> Nothing in the Flutter app reads `league.active` today — it is written here and read here.
> An archived league still appears for its members. Treat archiving as "marked for
> clearing", not "hidden from users". Making the app honour it means adding `AND l.active`
> to `get_user_leagues.js`.

**Delete** is permanent, in one transaction: fixtures → scoring config → memberships →
stranded guests → the league. A guest is removed only if that was the last league they
belonged to; a guest in two leagues survives, and a real account is never touched. Deleting
requires typing the league's name (or the count, in bulk).

---

## The server side

Eight new route files in `splitleague-server/routes/`, all registered in `server.js`,
following the house conventions — POST-only, at `/function_name`, every response carrying a
`return_code`, every file opening with a header block.

| Route | Purpose |
|---|---|
| `admin_login.js` | The one credential check. Issues a 7-day admin token. |
| `admin_stats.js` | Dashboard numbers. |
| `admin_leagues.js` | Every league with counts, stage and activity. |
| `admin_league_detail.js` | One league in full. |
| `admin_users.js` | Everybody, with leagues created/joined. |
| `admin_user_detail.js` | One person in full. |
| `admin_cleanup.js` | Redundant-league candidates with reasons. |
| `admin_league_action.js` | Archive, restore, delete. **The only one that writes.** |

`middleware/admin_middleware.js` guards all but `admin_login`.

Every list route returns its whole table in one response — 192 leagues and 405 users, which
is nothing. Sorting and filtering happen in the browser. If either grows into the low
thousands, add a `LIMIT` there and paging in `components/data_table.tsx`.
