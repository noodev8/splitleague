/*
=======================================================================================================================================
Library: format.ts
=======================================================================================================================================
Purpose: Small display helpers - dates, relative ages, stage labels. Shared so that every
         screen renders the same value the same way.
=======================================================================================================================================

A note on dates and time zones
------------------------------
Timestamps come out of Postgres as ISO strings in UTC. They are formatted here with the
en-GB locale and an explicit UTC time zone, deliberately, so that the admin tool shows the
same instant no matter which machine it is opened on. An admin comparing two leagues wants
the two numbers to be comparable; whether a fixture was edited at 21:48 local or 22:48 local
is not a question this tool is trying to answer.
=======================================================================================================================================
*/

import type { Stage } from './api';

// "29 Aug 2026" - for a date where the time of day does not matter
export function format_date(value: string | null | undefined): string {
  if (!value) return '—';

  const date = new Date(value);
  if (isNaN(date.getTime())) return '—';

  return date.toLocaleDateString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    timeZone: 'UTC',
  });
}

// "29 Aug 2026, 21:48" - for activity, where the time is part of the point
export function format_datetime(value: string | null | undefined): string {
  if (!value) return '—';

  const date = new Date(value);
  if (isNaN(date.getTime())) return '—';

  return date.toLocaleString('en-GB', {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    timeZone: 'UTC',
  });
}

/*
 * "3 days ago", "today", "never".
 *
 * Takes the day count the API already worked out rather than recomputing it from a
 * timestamp, so the text and any sorting on that column can never disagree.
 */
export function format_idle(days: number | null | undefined): string {
  if (days === null || days === undefined) return 'never';
  if (days === 0) return 'today';
  if (days === 1) return 'yesterday';
  if (days < 30) return `${days} days ago`;

  if (days < 365) {
    const months = Math.floor(days / 30);
    return months === 1 ? 'a month ago' : `${months} months ago`;
  }

  const years = Math.floor(days / 365);
  return years === 1 ? 'over a year ago' : `${years} years ago`;
}

// The label for a league stage. Setup and In play are the app's own words - see
// lib/helpers/league_stage.dart - and they should stay identical to what users see.
export function stage_label(stage: Stage): string {
  if (stage === 'setup') return 'Setting up';
  if (stage === 'in_play') return 'In play';
  return 'Complete';
}

// Plain-English name for each cleanup reason, so the page never shows a raw code
export const REASON_LABELS: Record<string, string> = {
  empty: 'Never started',
  abandoned_setup: 'Abandoned in setup',
  stalled: 'Stalled, no scores',
  dormant: 'Dormant',
  duplicate: 'Duplicate name',
  orphaned: 'No organiser',
};

// One-line explanation of each reason, for the tooltip / legend on the cleanup page
export const REASON_HELP: Record<string, string> = {
  empty: 'No fixtures and one member or fewer - created and never used.',
  abandoned_setup: 'Players were added but fixtures were never generated, and it has gone quiet.',
  stalled: 'Fixtures exist but not one score was ever entered, and it has gone quiet.',
  dormant: 'It was genuinely played, then stopped. There is real data in here.',
  duplicate: 'Another league has the same name and the same organiser.',
  orphaned: 'The organiser account no longer exists, so nobody can run it from the app.',
};
