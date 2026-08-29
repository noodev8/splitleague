/*
 * The top bar. Present on every page except the login screen.
 *
 * A client component only because it highlights the current section, which needs the
 * pathname. The Log out button posts to /api/session, which clears the cookie.
 */

'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { useState } from 'react';

const SECTIONS = [
  { href: '/', label: 'Dashboard' },
  { href: '/leagues', label: 'Leagues' },
  { href: '/users', label: 'Users' },
  { href: '/cleanup', label: 'Cleanup' },
];

export default function Nav() {
  const pathname = usePathname();
  const router = useRouter();
  const [signing_out, set_signing_out] = useState(false);

  // The login screen has no navigation - there is nowhere to go until you are signed in.
  // Hiding it here rather than in the layout keeps the layout to one shape for every page.
  if (pathname === '/login') return null;

  // A section is current if the path is it, or sits underneath it. The dashboard is the
  // exception - "/" is a prefix of everything, so it only matches exactly.
  const is_current = (href: string) =>
    href === '/' ? pathname === '/' : pathname.startsWith(href);

  async function log_out() {
    set_signing_out(true);
    await fetch('/api/session', { method: 'DELETE' });

    // refresh() as well as push(), so the server components re-render without the cookie
    // instead of the browser showing a cached signed-in page.
    router.push('/login');
    router.refresh();
  }

  return (
    <header className="bg-shell text-white">
      <div className="mx-auto flex max-w-7xl items-center gap-6 px-4 py-3">
        <Link href="/" className="text-sm font-semibold tracking-tight">
          SplitLeague <span className="text-slate-400">admin</span>
        </Link>

        <nav className="flex flex-1 items-center gap-1">
          {SECTIONS.map((section) => (
            <Link
              key={section.href}
              href={section.href}
              className={`rounded-md px-3 py-1.5 text-sm transition-colors ${
                is_current(section.href)
                  ? 'bg-shell-soft text-white'
                  : 'text-slate-300 hover:bg-shell-soft hover:text-white'
              }`}
            >
              {section.label}
            </Link>
          ))}
        </nav>

        <button
          onClick={log_out}
          disabled={signing_out}
          className="rounded-md px-3 py-1.5 text-sm text-slate-300 transition-colors hover:bg-shell-soft hover:text-white disabled:opacity-50"
        >
          {signing_out ? 'Signing out…' : 'Log out'}
        </button>
      </div>
    </header>
  );
}
