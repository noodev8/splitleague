/*
 * The login screen. One form, one admin, no sign-up and no password reset.
 *
 * The credentials live in splitleague-server/routes/admin_login.js, and the plaintext
 * password is written in that file's header comment so it cannot be lost.
 */

'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';

export default function LoginPage() {
  const router = useRouter();

  const [email, set_email] = useState('');
  const [password, set_password] = useState('');
  const [error, set_error] = useState<string | null>(null);
  const [busy, set_busy] = useState(false);

  async function submit(event: React.FormEvent) {
    event.preventDefault();
    set_busy(true);
    set_error(null);

    const response = await fetch('/api/session', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password }),
    });

    const data = await response.json();

    if (data.return_code !== 'SUCCESS') {
      set_error(data.message || 'Sign in failed');
      set_busy(false);
      return;
    }

    // The cookie is set. refresh() makes the server re-render with it, then the middleware
    // lets the dashboard through.
    router.push('/');
    router.refresh();
  }

  return (
    <div className="mx-auto mt-24 max-w-sm">
      <div className="mb-6 text-center">
        <h1 className="text-xl font-semibold tracking-tight text-slate-900">
          SplitLeague <span className="text-slate-400">admin</span>
        </h1>
        <p className="mt-1 text-sm text-slate-500">Sign in to continue</p>
      </div>

      <form onSubmit={submit} className="card space-y-4 p-6">
        <div>
          <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-700">
            Email
          </label>
          <input
            id="email"
            type="email"
            value={email}
            onChange={(e) => set_email(e.target.value)}
            autoComplete="username"
            required
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-slate-900 focus:ring-1 focus:ring-slate-900"
          />
        </div>

        <div>
          <label htmlFor="password" className="mb-1 block text-sm font-medium text-slate-700">
            Password
          </label>
          <input
            id="password"
            type="password"
            value={password}
            onChange={(e) => set_password(e.target.value)}
            autoComplete="current-password"
            required
            className="w-full rounded-md border border-slate-300 px-3 py-2 text-sm outline-none focus:border-slate-900 focus:ring-1 focus:ring-slate-900"
          />
        </div>

        {error && (
          <p className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">{error}</p>
        )}

        <button
          type="submit"
          disabled={busy}
          className="btn w-full bg-slate-900 text-white hover:bg-slate-800"
        >
          {busy ? 'Signing in…' : 'Sign in'}
        </button>
      </form>
    </div>
  );
}
