# League flow and navigation — done

Both problems in this document are fixed and tested on a real device (Samsung A42, debug
build against a local server). What follows is what changed and why, so the next person
does not have to re-derive it.

## 1. Back navigation

**The cause.** `pushReplacement` was used for two different things that look the same in
code and are not the same at all:

- *Sideways* moves between the four views of one league — players/fixtures, standings,
  details. These are tabs pretending to be routes, and replacing is correct for them.
- *Downwards* moves into a league from the dashboard, which destroyed the dashboard.

With the dashboard gone the stack was one route deep, so Back had nothing to pop and every
league screen carried a `canPop()` fallback that rebuilt a fresh dashboard from scratch.
Worse, `popUntil((route) => route.isFirst)` — which league details uses after Copy League,
and create-league uses after the PIN dialog — had no first route to find.

**The fix.** `dashboard_screen.dart` opens a league with `push` (`_openLeague`). The
dashboard stays at the bottom of the stack, the sideways swaps stay `pushReplacement`, and
Back now means "leave this league" from anywhere inside it. The `canPop()` fallbacks stay
where they are — they are now genuinely only for deep-link entry.

`league_members_screen.dart` was rebuilding league details three times over instead of
popping; it is pushed, so it now pops. Saving notes pops `true` and details reloads them.

**One trap worth knowing.** `pushReplacement` completes the *replaced* route's popped
future immediately. So `await Navigator.push(...)` on the dashboard returned the instant
the user tapped a tab inside the league, not when they came back out — the dashboard
refreshed far too early and then showed a stale card. The dashboard is now `RouteAware`
via `helpers/route_observer.dart` and refreshes on `didPopNext`. If you ever add another
screen that pushes onto a stack whose top gets replaced, this will bite you the same way.

## 2. The stage is now on screen

`helpers/league_stage.dart` names what `hasFixtures` already meant:

- **Setting up** (amber) — no fixtures. Add players, change scoring, share the code.
- **In play** (green) — fixtures exist. Enter scores. Nobody new can join.

Shown in two places, always in the same words:

- `widgets/league_stage_chip.dart` on the dashboard league cards, so the list answers
  "which of these has actually started?" without opening each one.
- `widgets/league_stage_banner.dart` directly under the tab row on all four league
  screens, with a line saying what you can do in this stage.

The green "Started" badge in `details_tab_content.dart` is gone — the banner above it
already said the same thing in different words, and that was the confusion.

**Generating fixtures now looks like the one-way door it is.** The panel is headed "Start
the league" and says what it shuts off. The confirmation lists the three consequences and
points at Reset League as the way back. That dialog moved out of `LeagueProvider` and onto
the screen: the provider showing UI meant the button underneath read "Generating…" while
the user was still deciding.

### The stage now has a real source

`get_user_leagues.js` returns `has_fixtures`. Before this the dashboard had no idea, and
`player_list_screen._checkFixtures()` fell back to `false` — correct only by accident.
Opening a league is now instant too, with the API call kept only as a fallback.

`LeagueStageInfo` has two readers on purpose: `fromLeague` guesses `setup` when the field
is absent (navigation must decide something), and `knownFromLeague` returns null so a
*badge* shows nothing rather than labelling a league it knows nothing about. That is what
lets the app ship before or after the server change, in either order.

### A bug the stage model exposed

Reset League deletes every fixture — the door swinging back — but it navigated to the
fixtures screen, which was then empty. It now lands on the player list in setup.

## Deployment note

`get_user_leagues.js` must go out for the dashboard chips to appear. Until it does the app
shows no chip there; everything else works, because the stage inside a league is derived
locally. Nothing breaks in either order.

## Not done

The Material 2/3 hybrid theme (§6.1 of the rebuild plan) is untouched. The scope note said
to fix navigation and make the stage obvious first and see whether that is enough, and it
may well be — the app now says where you are without a redesign.
