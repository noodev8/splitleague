/*
 * Shown when a page could not load its data. Says what the API said, and what to check.
 */

export default function ErrorPanel({ code, message }: { code: string; message: string }) {
  return (
    <div className="card border-red-200 bg-red-50 p-5">
      <h2 className="text-sm font-semibold text-red-800">Could not load this page</h2>
      <p className="mt-1 text-sm text-red-700">{message}</p>

      <p className="mt-3 text-xs text-red-600">
        Return code: <span className="font-mono">{code}</span>
      </p>

      {/*
        The one failure that is worth giving instructions for. Everything else is either a
        bug or a genuine server error, and guessing at those would just be noise.
      */}
      {code === 'NO_CONNECTION' && (
        <ul className="mt-3 list-disc space-y-1 pl-5 text-xs text-red-700">
          <li>Is splitleague-server running?</li>
          <li>
            Does <span className="font-mono">SPLITLEAGUE_API_URL</span> point at it? It is set
            in <span className="font-mono">.env.local</span> locally, and in the project
            settings on Vercel.
          </li>
        </ul>
      )}

      {/*
        The API is up and the URL is right - it simply does not have the route. The fix is a
        restart or a deploy, and saying so is the whole value of separating this from
        NO_CONNECTION.
      */}
      {code === 'ROUTE_NOT_FOUND' && (
        <ul className="mt-3 list-disc space-y-1 pl-5 text-xs text-red-700">
          <li>
            Locally: restart it — <span className="font-mono">cd splitleague-server</span> then{' '}
            <span className="font-mono">npm run dev</span>. A server started before the admin
            routes were written does not pick them up on its own.
          </li>
          <li>
            In production: the <span className="font-mono">admin_*</span> route files and{' '}
            <span className="font-mono">admin_middleware.js</span> need deploying, then{' '}
            <span className="font-mono">pm2 restart splitleague_prod</span>.
          </li>
        </ul>
      )}
    </div>
  );
}
