# Server-Side Fix for allow_code_share Parameter

The issue is that the server-side implementation of the create_league route doesn't handle the `allow_code_share` parameter. Here's what needs to be changed in the server code:

## 1. Update the INSERT statement in the create_league route

In the file `splitleague_server\routes\create_league.js`, modify the INSERT statement for the league table to include the `allow_code_share` column:

```javascript
// Insert the new league into the league table
const leagueInsertResult = await client.query(
  `INSERT INTO league (
    name,
    created_by,
    public_code,
    active,
    start_date,
    end_date,
    allow_code_share
  ) VALUES ($1, $2, $3, $4, $5, $6, $7)
  RETURNING *`,
  [
    name,
    userId,
    publicCode,
    true, // Set active to true
    start_date || null,
    end_date || null,
    req.body.allow_code_share !== undefined ? req.body.allow_code_share : true // Default to true if not provided
  ]
);
```

## 2. Update the request body extraction

In the same file, update the extraction of parameters from the request body to include `allow_code_share`:

```javascript
// Extract league details from request body
const {
  name,
  win_type,
  points_for_win,
  points_for_draw,
  points_for_win_margin,
  points_for_close_loss,
  win_margin_threshold,
  play_each_other,
  start_date,
  end_date,
  allow_code_share
} = req.body;
```

## 3. Ensure the database schema has the column

Make sure the `league` table in the database has an `allow_code_share` column of type BOOLEAN with a default value of TRUE.

If the column doesn't exist, you'll need to add it with an ALTER TABLE statement:

```sql
ALTER TABLE league ADD COLUMN allow_code_share BOOLEAN DEFAULT TRUE;
```

## Implementation Steps

1. Connect to the server where the SplitLeague Express.js application is running
2. Make the changes to the `create_league.js` file as described above
3. If needed, run the ALTER TABLE statement on the PostgreSQL database
4. Restart the Express.js server to apply the changes

After these changes, the `allow_code_share` parameter should be properly processed and saved in the database.
