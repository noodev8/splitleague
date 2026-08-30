# The UI and UX redesign — what changed and why

Branch: `ui-redesign`. Flutter app only, plus one additive field on one server route.

The brief was: the app has a lot of buttons, they all look the same, and it is not clear
where to go next; people register, set a league up, and leave. Make it feel nicer, with
less text and a clearer flow.

This document is what to read before touching the look of the app. It is the reasoning,
not a changelog — the code carries the detail, and every file that changed opens with a
comment saying what it replaced.

---

## 1. What was actually wrong

Four things, and they compounded.

**Three palettes on one screen.** The app bar was a teal gradient taken from the logo, the
tabs and the "primary" buttons were Material indigo (`#3F51B5`), and every button inside
the content was Material blue (`#2196F3`). Three unrelated blues, none of them chosen.

**No hierarchy at all.** Every action in the app was a full-width filled blue rectangle.
On the league Details screen, "Invite players", "Manage League Members", "Reset All
Scores", "Reset League" and "Copy League" were five identical bars — two of which destroy
data. A screen that shouts equally about everything says nothing about what to do next,
and that is precisely the reported symptom.

**Explanation instead of design.** A three-line stage banner on every league screen, a
bordered panel containing a paragraph about what generating fixtures does, an italic note
under it, a heading that repeated the tab name above it. All of it true, none of it read
after the first time.

**The two moments that matter both ended in a dead end.**

- Creating a league ended in a dialog showing the join code; closing it returned you to
  the dashboard. The instant a league exists and needs people, the app put you back on a
  list.
- The dashboard showed each league's name and a player count. A brand new league with one
  player therefore said nothing about what to do with it.

---

## 2. The design

**One colour with one job.** `styles/app_palette.dart`. The teal is the brand, because the
logo is a teal gradient and everything else was an accident. `AppPalette.teal` is spent on
**one filled button per screen**, and that button is the next thing to do. Everything else
is an outline, a plain row, or a text link. If a screen seems to need two filled buttons,
it has two primary actions and the fix is to decide which one it really is.

Colours are named for their role — `ink`, `slate`, `hairline`, `chalk` — not their hue.

**Two typefaces, bundled.** `styles/app_type.dart`, files in `fonts/`.

- **Archivo** for titles, league names and every score. It has a width axis as well as a
  weight axis, and it is set slightly expanded (105–108). That expansion is what makes a
  league name and a scoreline read like lettering on a board rather than a heading in a
  form. It is the one flourish in the app.
- **Instrument Sans** for everything else — sentences, labels, metadata, button text.
  Narrower and quieter on purpose, so the two never compete.

Both are variable fonts, so weight and width come from `fontVariations` rather than a
dozen static files. Use `AppType.t(...)` for display roles and `AppType.b(...)` for body
roles; they apply the axes. Text that skips them still renders, it just loses the
expansion.

**The signature: the scoreline.** `widgets/sl_scoreline.dart`. A league lives on a wall
somewhere, and the artefact in that world is always two names with a score between them.
That shape is the app's content, so it is drawn the same way everywhere: three columns
with the score on a fixed axis, tabular figures, the winner in ink and the loser in slate.

The important part is the unplayed state. A fixture with no result shows a tinted
**Enter** where the score goes, which turns the fixture list into a visible checklist of
what is left. The old list showed `0 - 1` for played games and nothing distinguishable for
unplayed ones, so it never answered the only question anybody opens it with.

**The structural device: the stage.** A league has exactly two states and they were already
the app's real state machine (`helpers/league_stage.dart`); they were just never shown
properly. The three-line banner is now one line in the shared league header — a coloured
dot, the stage name, one clause. Same fixed place on every league screen, five lines of
chrome down to one.

---

## 3. Flow changes

These are behaviour changes, not just paint.

**Creating a league takes you into it.** `create_league_screen.dart` now
`pushReplacement`es to the new league's player list, where "Invite players" is the filled
button. The PIN dialog is gone. The join code did not go anywhere: it is the first thing on
that league's Details tab, at four times the size it had in the dialog.

**The dashboard is a to-do list.** `helpers/league_prompt.dart` turns each league's state
into the next step in words — "Just you so far · invite people", "4 players · ready to
start", "3 results to enter". Leagues that want something sort to the top and carry a
coloured rule; the header says how many need you before you read a single name.

**The bottom navigation bar is gone.** Three of its four items were not tabs — Create, Join
and Profile pushed a screen and the bar snapped back to Home. The app's most prominent
navigation was lying about what it did. Profile is now the avatar in the header, and
"New league" / "Join with a code" are a ranked pair in a fixed bar at the bottom.

**The primary action follows what a league needs.** On the player list, below two players
there is nothing to start, so "Invite players" is the filled button. At two or more, a
"Start with N players" bar appears at the bottom and takes the fill, and the two buttons
above it each step down a rank. That is the rule about one filled button per screen staying
honest on a screen whose most important action changes as it fills up.

**Registration lost two fields.** Confirm-password is replaced by a reveal on the password
itself — it catches the same typo without a second field. Display name now fills itself in
from the first name until the person edits it; two unexplained name fields was the most
confusing thing on the old screen.

**Creating a league lost five.** Scoring settings are behind one disclosure, and a
win/lose league has none at all rather than an empty section. "Times to play each other"
is now Once / Twice / 3 times instead of a text box that would happily accept 40 — which
in a league of eight is 1,120 fixtures.

**Entering a result: you tap whoever won.** The names are the control, so there is nothing
to explain. The old screen needed the word "Winner" printed twice because two identical
cards could not say what they were for.

**Destructive actions are never filled buttons.** They are rows with clay text, at the
bottom of a section headed ORGANISER, with the consequence on the second line. A filled
button invites the tap, and these are the actions we least want tapped by accident.

---

## 4. The shared parts

Everything new is `widgets/sl_*.dart`, and each file opens with what it replaced.

| File | What it is |
|---|---|
| `sl_button.dart` | The three kinds of button. Primary / secondary / quiet. Nothing else. |
| `sl_action_row.dart` | A tappable row, and `SlSection` — a group of them under an eyebrow. |
| `sl_scoreline.dart` | The signature unit. |
| `sl_segmented.dart` | The control that moves between the views of a league. |
| `sl_league_header.dart` | League name, stage, segments. Shared by all four league screens. |
| `sl_empty.dart` | `SlEmpty` and `SlError`. Replaced five near-identical empty states. |
| `sl_dark_field.dart` | A field on the dark ground. Sign in and register only. |

`styles/app_styles.dart` still exists but holds no colours of its own — it is a thin layer
over the palette so the rarely-reached screens (change password, hidden leagues, edit
profile) sit inside the new system without each being rewritten. **Do not add to it.** When
the last of those screens is rewritten it goes away, and the analyzer will say so.

Deleted: `app_logo.dart`, `league_stage_banner.dart`, `league_stage_chip.dart`,
`tab_selector.dart`, `error_display.dart`, `fixture_card.dart`.

---

## 5. Two traps worth knowing

Both cost time, both will bite again.

**A `Scaffold` lays out `bottomNavigationBar` with loose constraints** — max height is the
whole screen. Anything inside it that expands to fill what it is offered fills the display.
A `Center`, or a `Container` with an `alignment`, both do exactly that. `SlButton`
deliberately has neither; see the comment in the file.

**`CrossAxisAlignment.stretch` in a `ListView` is an assertion, not a layout.** A list gives
its children unbounded height, and asking a row's children to stretch into an unbounded
height throws. Wrap the row in `IntrinsicHeight` — it measures the taller child first. This
is what the winner tiles on the score screen do.

---

## 6. Server

One additive change: `get_user_leagues.js` now returns `unplayed_count` per league. It is
what the dashboard turns into "3 results to enter".

**It has not been deployed.** Until it is, the dashboard falls back to the player count —
`helpers/league_prompt.dart` handles a missing field explicitly — so the app is safe to
ship in either order and nothing breaks whichever goes first.

---

## 7. Not done

- **The public web page** at `/l/<slug>` still uses the old look. It is the first thing an
  invited person sees, so it is the obvious next piece.
- **Dark mode.** The app is deliberately light-only. A half-done dark mode over a palette
  this specific would be worse than none.
- **`app_styles.dart` and its remaining callers** — change password, hidden leagues, edit
  profile, accessibility settings, developer. They sit inside the palette but have not been
  designed; they are all low-traffic.
- **Real-device testing beyond one phone.** Everything here was checked on a Samsung A42
  (720×1600) in debug against production. Large text scaling was designed for but not
  exercised.
