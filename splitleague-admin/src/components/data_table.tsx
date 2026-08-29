/*
=======================================================================================================================================
Component: data_table.tsx
=======================================================================================================================================
Purpose: The sortable, searchable, filterable table used by the Leagues and Users pages.
=======================================================================================================================================

Why the sorting happens in the browser
--------------------------------------
The API sends every league and every user in one go - 192 and 405 rows respectively - so the
whole data set is already here. Sorting it in the browser is instant, needs no round trip,
and means the sort state does not have to live in the URL or on the server.

If either table ever grows into the thousands this is the component to revisit, along with a
LIMIT on the matching route. It is nowhere near that.

Sorting rules that are easy to get wrong
----------------------------------------
Nulls always sort last, whichever direction the column is sorted in. A league that has never
been touched has a null last_activity, and it should appear at the bottom of "most recent
first" AND at the bottom of "least recent first" - it is not the oldest date, it is the
absence of one. Mixing those two ideas is how a sort ends up lying.
=======================================================================================================================================
*/

'use client';

import Link from 'next/link';
import { useMemo, useState } from 'react';

export type Column<T> = {
  // Unique key for the column. Also used as the sort key.
  key: string;

  // Header text
  label: string;

  // What to show in the cell. Defaults to the raw value.
  render?: (row: T) => React.ReactNode;

  // What to sort by. Defaults to the raw value; give this when the cell shows something
  // other than the thing you want to order on - a formatted date, say.
  value?: (row: T) => string | number | boolean | null | undefined;

  // Right-align numbers, left-align everything else
  align?: 'left' | 'right';
};

export type Filter<T> = {
  key: string;
  label: string;
  test: (row: T) => boolean;
};

type Props<T> = {
  rows: T[];
  columns: Column<T>[];

  // Free-text search. Return everything about a row that should be searchable, joined up.
  search?: (row: T) => string;
  search_placeholder?: string;

  // Optional chips above the table. Selecting one narrows the rows; selecting it again
  // clears it. Only one at a time - these are "show me only X" questions, not layers.
  filters?: Filter<T>[];

  initial_sort?: { key: string; dir: 'asc' | 'desc' };

  // Makes each row a link to a detail page
  href?: (row: T) => string;

  // The key that uniquely identifies a row, for React
  row_key: (row: T) => string | number;

  empty?: string;
};

export default function DataTable<T>({
  rows,
  columns,
  search,
  search_placeholder = 'Search…',
  filters,
  initial_sort,
  href,
  row_key,
  empty = 'Nothing to show.',
}: Props<T>) {
  const [query, set_query] = useState('');
  const [active_filter, set_active_filter] = useState<string | null>(null);
  const [sort_key, set_sort_key] = useState<string | null>(initial_sort?.key ?? null);
  const [sort_dir, set_sort_dir] = useState<'asc' | 'desc'>(initial_sort?.dir ?? 'asc');

  // Pull the sortable value out of a row for a given column
  function value_of(row: T, key: string) {
    const column = columns.find((c) => c.key === key);
    if (!column) return null;
    if (column.value) return column.value(row);
    return (row as Record<string, unknown>)[key] as string | number | boolean | null;
  }

  const visible = useMemo(() => {
    let result = rows;

    // Filter chip first - it is the coarser cut
    if (active_filter && filters) {
      const filter = filters.find((f) => f.key === active_filter);
      if (filter) result = result.filter(filter.test);
    }

    // Then the search box
    const trimmed = query.trim().toLowerCase();
    if (trimmed && search) {
      result = result.filter((row) => search(row).toLowerCase().includes(trimmed));
    }

    // Then sort. Copied first - sort() mutates, and mutating props is how you get a table
    // that reorders itself when something unrelated re-renders.
    if (sort_key) {
      result = [...result].sort((a, b) => {
        const left = value_of(a, sort_key);
        const right = value_of(b, sort_key);

        // Nulls last in both directions - see the header comment
        const left_null = left === null || left === undefined || left === '';
        const right_null = right === null || right === undefined || right === '';
        if (left_null && right_null) return 0;
        if (left_null) return 1;
        if (right_null) return -1;

        let comparison: number;

        if (typeof left === 'number' && typeof right === 'number') {
          comparison = left - right;
        } else if (typeof left === 'boolean' && typeof right === 'boolean') {
          comparison = Number(left) - Number(right);
        } else {
          // localeCompare so that names sort the way a person would expect, not by code point
          comparison = String(left).localeCompare(String(right), 'en-GB', { numeric: true });
        }

        return sort_dir === 'asc' ? comparison : -comparison;
      });
    }

    return result;
  }, [rows, columns, query, active_filter, filters, search, sort_key, sort_dir]);

  // Clicking a header sorts by it. Clicking the one already sorted flips the direction.
  function sort_by(key: string) {
    if (sort_key === key) {
      set_sort_dir(sort_dir === 'asc' ? 'desc' : 'asc');
    } else {
      set_sort_key(key);

      // A newly chosen column starts descending, because on this data the interesting end
      // is almost always the big one - most members, most fixtures, longest idle.
      set_sort_dir('desc');
    }
  }

  return (
    <div className="card">
      {(search || filters) && (
        <div className="flex flex-wrap items-center gap-2 border-b border-slate-200 p-3">
          {search && (
            <input
              value={query}
              onChange={(e) => set_query(e.target.value)}
              placeholder={search_placeholder}
              className="w-56 rounded-md border border-slate-300 px-3 py-1.5 text-sm outline-none focus:border-slate-900 focus:ring-1 focus:ring-slate-900"
            />
          )}

          {filters?.map((filter) => {
            const on = active_filter === filter.key;
            return (
              <button
                key={filter.key}
                onClick={() => set_active_filter(on ? null : filter.key)}
                className={`pill border transition-colors ${
                  on
                    ? 'border-slate-900 bg-slate-900 text-white'
                    : 'border-slate-300 bg-white text-slate-600 hover:border-slate-400'
                }`}
              >
                {filter.label}
              </button>
            );
          })}

          <span className="ml-auto text-xs text-slate-500">
            {visible.length} of {rows.length}
          </span>
        </div>
      )}

      <div className="table-scroll">
        <table className="w-full border-collapse">
          <thead className="border-b border-slate-200 bg-slate-50">
            <tr>
              {columns.map((column) => (
                <th
                  key={column.key}
                  className={`th cursor-pointer select-none hover:text-slate-900 ${
                    column.align === 'right' ? 'text-right' : ''
                  }`}
                  onClick={() => sort_by(column.key)}
                >
                  {column.label}
                  {sort_key === column.key && (
                    <span className="ml-1 text-slate-400">{sort_dir === 'asc' ? '▲' : '▼'}</span>
                  )}
                </th>
              ))}
            </tr>
          </thead>

          <tbody className="divide-y divide-slate-100">
            {visible.map((row) => (
              <tr key={row_key(row)} className="hover:bg-slate-50">
                {columns.map((column, index) => {
                  const content = column.render
                    ? column.render(row)
                    : String((row as Record<string, unknown>)[column.key] ?? '—');

                  return (
                    <td
                      key={column.key}
                      className={`td ${column.align === 'right' ? 'text-right' : ''}`}
                    >
                      {/*
                        The link is on the first cell only rather than wrapping the row.
                        A table row cannot legally contain an anchor, and stretching one
                        across the row with absolute positioning breaks text selection -
                        which matters here, because copying an email out of the table is
                        something you will want to do.
                      */}
                      {index === 0 && href ? (
                        <Link
                          href={href(row)}
                          className="font-medium text-slate-900 hover:text-blue-700 hover:underline"
                        >
                          {content}
                        </Link>
                      ) : (
                        content
                      )}
                    </td>
                  );
                })}
              </tr>
            ))}

            {visible.length === 0 && (
              <tr>
                <td className="td text-slate-500" colSpan={columns.length}>
                  {empty}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
