/*
 * The small shared pieces: stat tiles, stage badges, section headings and the guest flag.
 *
 * All server components - none of them are interactive, so none of them need to be shipped
 * to the browser as JavaScript.
 */

import type { Stage } from '@/lib/api';
import { stage_label } from '@/lib/format';

/* ------------------------------------------------------------------------------------- */

// A single headline number, with an optional line of context under it.
export function Stat({
  label,
  value,
  hint,
  tone = 'plain',
}: {
  label: string;
  value: string | number;
  hint?: string;
  tone?: 'plain' | 'good' | 'warn' | 'bad';
}) {
  const tones = {
    plain: 'text-slate-900',
    good: 'text-green-700',
    warn: 'text-amber-700',
    bad: 'text-red-700',
  };

  return (
    <div className="card p-4">
      <div className="text-xs font-medium uppercase tracking-wide text-slate-500">{label}</div>
      <div className={`mt-1 text-2xl font-semibold tabular-nums ${tones[tone]}`}>{value}</div>
      {hint && <div className="mt-1 text-xs text-slate-500">{hint}</div>}
    </div>
  );
}

/* ------------------------------------------------------------------------------------- */

/*
 * The league stage badge.
 *
 * The same three colours are used everywhere in the tool, and the two names the app itself
 * uses - "Setting up" and "In play" - are kept word for word. "Complete" is admin-only.
 */
export function StageBadge({ stage }: { stage: Stage }) {
  const styles: Record<Stage, string> = {
    setup: 'bg-amber-50 text-amber-800 ring-1 ring-amber-200',
    in_play: 'bg-green-50 text-green-800 ring-1 ring-green-200',
    complete: 'bg-blue-50 text-blue-800 ring-1 ring-blue-200',
  };

  return <span className={`pill ${styles[stage]}`}>{stage_label(stage)}</span>;
}

/* ------------------------------------------------------------------------------------- */

// A neutral pill, for anything that is just a label
export function Pill({
  children,
  tone = 'slate',
}: {
  children: React.ReactNode;
  tone?: 'slate' | 'amber' | 'green' | 'blue' | 'red' | 'violet';
}) {
  const tones = {
    slate: 'bg-slate-100 text-slate-700',
    amber: 'bg-amber-50 text-amber-800',
    green: 'bg-green-50 text-green-800',
    blue: 'bg-blue-50 text-blue-800',
    red: 'bg-red-50 text-red-700',
    violet: 'bg-violet-50 text-violet-800',
  };

  return <span className={`pill ${tones[tone]}`}>{children}</span>;
}

/* ------------------------------------------------------------------------------------- */

// Page heading, with an optional line of explanation
export function PageTitle({ title, subtitle }: { title: string; subtitle?: string }) {
  return (
    <div className="mb-5">
      <h1 className="text-lg font-semibold tracking-tight text-slate-900">{title}</h1>
      {subtitle && <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p>}
    </div>
  );
}

// Heading inside a card
export function SectionTitle({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="border-b border-slate-200 px-4 py-3 text-sm font-semibold text-slate-900">
      {children}
    </h2>
  );
}

/* ------------------------------------------------------------------------------------- */

// A label and value on one line, for the detail pages
export function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div className="flex items-baseline gap-3 px-4 py-2 text-sm">
      <span className="w-36 shrink-0 text-slate-500">{label}</span>
      <span className="text-slate-900">{children}</span>
    </div>
  );
}

/* ------------------------------------------------------------------------------------- */

/*
 * The bar showing how far through its fixtures a league is.
 *
 * A league with no fixtures gets no bar at all rather than an empty one - it has not failed
 * to play its fixtures, it does not have any yet, and an empty progress bar reads as the
 * former.
 */
export function Progress({ played, total }: { played: number; total: number }) {
  if (total === 0) return <span className="text-slate-400">—</span>;

  const percent = Math.round((played / total) * 100);

  return (
    <div className="flex items-center gap-2">
      <div className="h-1.5 w-20 overflow-hidden rounded-full bg-slate-200">
        <div
          className={`h-full rounded-full ${percent === 100 ? 'bg-blue-600' : 'bg-green-600'}`}
          style={{ width: `${percent}%` }}
        />
      </div>
      <span className="tabular-nums text-xs text-slate-600">
        {played}/{total}
      </span>
    </div>
  );
}

/* ------------------------------------------------------------------------------------- */

// Shown when a page has nothing to render
export function Empty({ children }: { children: React.ReactNode }) {
  return <div className="px-4 py-6 text-sm text-slate-500">{children}</div>;
}
