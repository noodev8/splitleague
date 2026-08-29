/*
=======================================================================================================================================
Utility: share_slug_utils
=======================================================================================================================================
Purpose: Generates and normalises league.share_slug - the identifier in a shared link, https://.../l/<slug>.

Why this exists at all, when leagues already have a 4-digit public_code:

  The 4-digit code and the share link were the same identifier, and they are two different jobs
  with different requirements:

    public_code  is SAID OUT LOUD. "Join with 1231." Four digits is exactly right for that, and
                 lengthening it would spoil the one thing it is good at. It is also rotated by
                 reset_league_fixtures, which means it is not stable over the life of a league.

    share_slug   is NEVER read aloud - it is pasted, tapped, forwarded. Nobody types it, so it can
                 be long. It has to be stable forever, because a link sent in a group chat last
                 month is still a live link today.

  And 189 leagues inside a 9,000 value space is a 1-in-48 hit rate on a random guess, with the
  whole space walkable in minutes. Ten characters of base32 is 50 bits - it is not walkable.

Rules that must not be broken:

  GENERATED ONCE.  A slug is written when the league is created and never touched again. Rotating
                   it would silently break every link already shared.
  NEVER REUSED.    No code path ever hands a slug back to be given to a different league. This is
                   precisely the defect public_code has: reset_league_fixtures rotates a league's
                   code and frees the old value, which create_league can then hand to somebody
                   else - so a link shared last month can quietly resolve to a stranger's league.
                   The only way a slug leaves the table at all is the league itself being deleted
                   (delete_account removes a user's leagues outright), and even then the chance of
                   the generator picking that exact value again is one in a thousand million
                   million. It is not a recycling scheme, which is what makes the difference.

The alphabet is Crockford base32: the digits and the letters, with I, L, O and U left out. I and L
look like 1, O looks like 0, and U is dropped so a random string is unlikely to spell anything
unfortunate. Slugs are stored lowercase because that is what reads well in a URL.
=======================================================================================================================================
*/

const crypto = require('crypto');


// The Crockford base32 alphabet, lowercase. No i, l, o or u - see the header.
const ALPHABET = '0123456789abcdefghjkmnpqrstvwxyz';

// How long a slug is. Ten characters of a 32 character alphabet is 50 bits.
const SLUG_LENGTH = 10;

// What a valid slug looks like. This is the ALPHABET written as a character range:
// 0-9, a-h, j, k, m, n, p-t, v-z. Keep the two in step if either ever changes.
const SLUG_PATTERN = /^[0-9a-hjkmnp-tv-z]{10}$/;


// Make a new random slug
//
// crypto.randomInt is used rather than Math.random: this is an identifier whose whole
// purpose is being unguessable, so it must not come out of a predictable generator.
// randomInt also picks evenly across the alphabet, where the usual "random byte modulo 32"
// trick would quietly favour some characters over others.
const generateShareSlug = () => {
  let slug = '';

  for (let i = 0; i < SLUG_LENGTH; i++) {
    slug += ALPHABET[crypto.randomInt(0, ALPHABET.length)];
  }

  return slug;
};


// Tidy up a slug that arrived from outside - a URL, a request body, somebody retyping a link
//
// Crockford base32 is deliberately forgiving about the characters it left out, because they are
// the ones people get wrong: I and L are read back as 1, O is read back as 0. Case is ignored.
// Anything that is not a slug shape after that comes back as null, so a caller can treat null
// as "this is not a slug" without any further checking.
const normaliseShareSlug = (value) => {
  if (value === null || value === undefined) {
    return null;
  }

  const cleaned = String(value)
    .trim()
    .toLowerCase()
    .replace(/[il]/g, '1')
    .replace(/o/g, '0');

  return SLUG_PATTERN.test(cleaned) ? cleaned : null;
};


// Is this string a slug, exactly as stored?
//
// Used where a value must be a slug and nothing else - the public page guard, for example -
// as opposed to normaliseShareSlug, which is used where a near miss should be repaired.
const isShareSlug = (value) => {
  return typeof value === 'string' && SLUG_PATTERN.test(value);
};


// Pick a slug that no league is using yet
//
// The unique index on league.share_slug is the real guarantee - this just avoids losing an
// insert to a collision that we could have seen coming. A collision is close to impossible in
// a 50-bit space with a few hundred leagues, so a handful of attempts is generous.
//
// Takes a client (or the pool) so it can run inside a caller's transaction.
const generateUniqueShareSlug = async (client) => {
  const maxAttempts = 10;

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const slug = generateShareSlug();

    const existing = await client.query(
      'SELECT id FROM league WHERE share_slug = $1',
      [slug]
    );

    if (existing.rows.length === 0) {
      return slug;
    }
  }

  throw new Error('Failed to generate a unique share slug after multiple attempts');
};


// Work out which column an identifier from the app should be looked up against
//
// The app can hand a route either shape, and the route should not have to care which:
//
//   ten slug characters  -> league.share_slug, e.g. somebody who followed an invite link and
//                           never saw a code at all
//   four digits          -> league.public_code, e.g. somebody typing in a code they were told,
//                           and every older install that only knows about codes
//
// Returns { column, value } ready to drop into a parameterised query, or null when the value is
// neither shape - which callers should treat as "no such league", exactly as they would a code
// that matched nothing. The column name comes from this function and never from the request, so
// there is nothing here for a caller to interpolate unsafely.
const resolveLeagueKey = (value) => {
  const slug = normaliseShareSlug(value);

  if (slug !== null) {
    return { column: 'share_slug', value: slug };
  }

  const code = String(value === null || value === undefined ? '' : value).trim();

  if (/^\d{4}$/.test(code)) {
    return { column: 'public_code', value: code };
  }

  return null;
};


module.exports = {
  ALPHABET,
  SLUG_LENGTH,
  SLUG_PATTERN,
  generateShareSlug,
  normaliseShareSlug,
  isShareSlug,
  resolveLeagueKey,
  generateUniqueShareSlug
};
