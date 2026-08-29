/*
 * The archive / restore / delete buttons on a league detail page.
 *
 * Delete asks for the league's name to be typed before it will go. That is deliberate
 * friction: this is the one control in the tool that destroys data with no undo, and an
 * "are you sure?" dialog is something people dismiss without reading.
 */

'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { run_league_action } from '@/app/actions';

export default function LeagueActions({
  league_id,
  league_name,
  active,
}: {
  league_id: number;
  league_name: string;
  active: boolean;
}) {
  const router = useRouter();

  const [busy, set_busy] = useState(false);
  const [message, set_message] = useState<{ ok: boolean; text: string } | null>(null);
  const [confirming, set_confirming] = useState(false);
  const [typed_name, set_typed_name] = useState('');

  async function act(action: 'archive' | 'restore' | 'delete') {
    set_busy(true);
    set_message(null);

    const result = await run_league_action(action, [league_id]);

    // The token expired while the page was open
    if (result.expired) {
      router.push('/login');
      return;
    }

    if (!result.ok) {
      set_message({ ok: false, text: result.message });
      set_busy(false);
      return;
    }

    // A deleted league has no detail page left to show, so go back to the list
    if (action === 'delete') {
      router.push('/leagues');
      router.refresh();
      return;
    }

    set_message({ ok: true, text: result.message });
    set_busy(false);
    router.refresh();
  }

  // The typed name has to match, ignoring case and surrounding spaces - it is a check that
  // you are looking at the right league, not a spelling test.
  const name_matches = typed_name.trim().toLowerCase() === league_name.trim().toLowerCase();

  return (
    <div className="space-y-3 p-4">
      <div className="flex flex-wrap gap-2">
        {active ? (
          <button
            onClick={() => act('archive')}
            disabled={busy}
            className="btn border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
          >
            Archive
          </button>
        ) : (
          <button
            onClick={() => act('restore')}
            disabled={busy}
            className="btn border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
          >
            Restore
          </button>
        )}

        <button
          onClick={() => set_confirming(!confirming)}
          disabled={busy}
          className="btn border border-red-200 bg-white text-red-700 hover:bg-red-50"
        >
          Delete…
        </button>
      </div>

      <p className="text-xs text-slate-500">
        Archiving sets a flag and can be undone. Note that the app does not read that flag
        yet, so an archived league still appears for its members - treat it as &ldquo;marked
        for clearing&rdquo;.
      </p>

      {confirming && (
        <div className="rounded-md border border-red-200 bg-red-50 p-3">
          <p className="text-sm text-red-800">
            This permanently deletes the league, its fixtures, its memberships and its scoring
            settings. Guests who belong to no other league go too. There is no undo.
          </p>

          <label className="mt-3 block text-xs font-medium text-red-800">
            Type <span className="font-mono">{league_name}</span> to confirm
          </label>

          <div className="mt-1 flex gap-2">
            <input
              value={typed_name}
              onChange={(e) => set_typed_name(e.target.value)}
              className="flex-1 rounded-md border border-red-300 px-3 py-1.5 text-sm outline-none focus:border-red-600 focus:ring-1 focus:ring-red-600"
            />
            <button
              onClick={() => act('delete')}
              disabled={busy || !name_matches}
              className="btn bg-red-700 text-white hover:bg-red-800"
            >
              {busy ? 'Deleting…' : 'Delete for good'}
            </button>
          </div>
        </div>
      )}

      {message && (
        <p className={`text-sm ${message.ok ? 'text-green-700' : 'text-red-700'}`}>
          {message.text}
        </p>
      )}
    </div>
  );
}
