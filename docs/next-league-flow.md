# Next task: league flow and navigation

Do the slug work (`docs/next-share-slug.md`) first, or in parallel — they barely overlap.

## The two problems

**1. Back navigation is broken, and it is not subtle.**
`dashboard_screen.dart:189` opens a league with `Navigator.pushReplacement`, and
`league_details_screen.dart:326` does the same into the player list / fixtures.
`pushReplacement` destroys the screen you came from, so Back cannot return to it. The user
reports "creating a league then checking detail and going back doesn't go where I expect" —
this is why. Audit every `pushReplacement` in `lib/screens/`; most should be `push`.

Related, already fixed, same class: the splash screen's `pushReplacement` used to swallow a
screen pushed by a deep link. See `deep_link_helper.dart`.

**2. A league has stages, and the app never says which one you are in.**
`hasFixtures` is already the de facto state machine — it gates joining, adding guests,
showing the code, the share wording, and which public landing page renders. It is real
everywhere except on screen.

Make it explicit. The user's words: *getting players → settings → in play. Simple as that.*

- **Setup** (no fixtures): add/invite players, change scoring, generate fixtures
- **In play** (fixtures exist): enter scores, view table. No joining — `join_league.js`
  returns `FIXTURES_EXIST`, deliberately, and that is staying.

Generating fixtures is the one-way door between them. It should look like one.

## Worth knowing

- 18 screens in `lib/screens/`; only ~8 are on this path.
- `_checkFixtures()` in `player_list_screen.dart` falls back to `_hasFixtures = false` when
  `has_fixtures` is missing from the league map. Correct today only because both callers
  route to `FixturesScreen` when fixtures exist. A stage model should not rest on that.
- The theme is a Material 2/3 hybrid (`main.dart` mixes `primarySwatch` with a hand-built
  `ColorScheme`). Rebuilding it onto `ColorScheme.fromSeed` is §6.1 of the rebuild plan and
  is the change that actually makes the app look current. Decide whether that belongs in
  this session or its own — the user has not committed to a visual redesign yet.

## Scope note

The user is not sure yet whether this needs a full UI redesign. Fix the navigation and make
the stage obvious first; that may be enough. Do not start a visual overhaul without asking.
