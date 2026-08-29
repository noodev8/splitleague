# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## ⚠️ Read this first: current work

**`docs/rebuild-plan.md` is the active working document.** Read it before doing anything
substantial. It holds the assessment of the codebase, the production usage analysis, the
decisions already made, the defect register, and the phased plan we are working through.

Decisions already settled (do not re-litigate):
- **Fix in place — not a rewrite, and not a "SplitLeague 2" store listing.**
- Email verification is being mimicked away: mark verified on signup, send no email,
  keep the pipeline and the `verification_token` columns (password reset shares them).
- Phase 1 is a **public read-only league page** at `/l/<code>` plus lifting the 2-guest cap
  — not universal join links. Then stop and test with real people before deciding more.
- The guest data model is deliberately still open; decide it after Phase 1 ships.

**Querying production:** there is no schema file to trust. Connect directly using
`DATABASE_URL` from `splitleague-server/.env`. A throwaway node script placed in
`splitleague-server/` (so it resolves `pg` and `dotenv`) is the quickest way to run
read-only queries. `fixture.updated_at` is the most reliable real-usage signal in the DB.

## Project Overview

SplitLeague is a sports league management application consisting of:
- **Frontend**: Flutter mobile app (cross-platform for Android, iOS, Web, Windows, macOS, Linux)
- **Backend**: Node.js Express REST API server
- **Database**: PostgreSQL (direct queries via `pg` package, no ORM)

## Essential Commands

### Flutter App Development (run from `splitleague-flutter/`)
```bash
# Install dependencies
flutter pub get

# Run in development mode
flutter run

# Run tests
flutter test
flutter test test/widget_test.dart  # Run specific test

# Build for production
flutter build apk       # Android
flutter build ios       # iOS
flutter build web       # Web
flutter build windows   # Windows
flutter build macos     # macOS

# Regenerate app icons after changes
flutter pub run flutter_launcher_icons

# Analyze code
flutter analyze
```

### Backend Server Development (run from `splitleague-server/`)
```bash
# Install dependencies
npm install

# Run in development mode with auto-reload
npm run dev

# Run in production mode
npm start
```

**Required Environment Variables** (in `splitleague-server/.env`):
- `DATABASE_URL` - PostgreSQL connection string
- `PORT` - Server port (default: 3000)
- `JWT_SECRET` - Secret for signing JWTs
- `RESEND_API_KEY` - Email service API key
- `FRONTEND_URL` - Frontend URL for CORS
- `EMAIL_VERIFICATION_URL` - Base URL for email verification links
- `EMAIL_FROM` - Sender email address
- `EMAIL_NAME` - Sender display name

## Architecture Overview

### Frontend Architecture (Flutter)

**State Management**:
- **Pattern**: Provider (`provider` package v6.1.2)
- **Key Providers**:
  - `LeagueProvider` - Manages league data, fixtures, standings, members
  - `AccessibilityProvider` - Handles text scaling and high contrast mode
- All global state managed through providers in `lib/providers/`

**API Layer**:
- **Location**: `lib/api/` (33+ API files)
- **Pattern**: Static methods in dedicated API classes
- **Naming**: One-to-one mapping with backend routes (e.g., `login_user.js` → `login_user_api.dart`)
- **HTTP Client**: `http` package v1.3.0
- **Base URL**: Configured in `lib/helpers/config.dart` and `runtime_config.dart`

**Authentication**:
- **Storage**: Flutter Secure Storage (encrypted local storage)
- **Token**: JWT stored securely, attached as `Authorization: Bearer <token>` header
- **Helper**: `AuthHelper` class in `lib/helpers/auth_helper.dart`

**Error Handling**:
- **Centralized**: `error_helper.dart` and `error_handler.dart`
- **Display**: Toast messages via `fluttertoast` package, `error_display.dart` widget
- **Pattern**: All API responses checked for `return_code` field

**Directory Structure**:
- `lib/api/` - API client functions (POST requests to backend)
- `lib/helpers/` - Auth, config, error handling utilities
- `lib/models/` - Data models (minimal usage)
- `lib/providers/` - State management providers
- `lib/screens/` - UI screens (19+ screens)
- `lib/styles/` - Shared styles and app theme (Material Design 3)
- `lib/widgets/` - Reusable UI components

### Backend Architecture (Express)

**API Pattern**:
- **Method**: All endpoints use POST only
- **Response Format**: Always JSON with `return_code` field
  ```json
  {
    "return_code": "SUCCESS" | "ERROR_CODE",
    "message": "...",
    ... other data ...
  }
  ```
- **URL Pattern**: `/function_name` (e.g., `/login_user`, `/create_league`)
- **Route Registration**: All routes registered in `server.js`

**Authentication**:
- **Method**: JWT (JSON Web Tokens)
- **Library**: `jsonwebtoken` v9.0.2
- **Password**: Bcrypt hashing (`bcrypt` v5.1.1)
- **Middleware**: `middleware/auth_middleware.js` - verifies JWT on protected routes
- **Token Expiry**: 180 days
- **Pattern**: Middleware adds `userId` to `req` object for protected routes

**Database Access**:
- **Library**: `pg` package v8.14.1 (no ORM)
- **Connection**: Connection pool in `db.js`
- **Query Style**: Parameterized queries with `$1, $2, ...` placeholders to prevent SQL injection
- **Example**:
  ```javascript
  const result = await pool.query(
    'SELECT * FROM app_user WHERE email = $1',
    [email]
  );
  ```

**Email System**:
- **Service**: Resend API (`resend` package v4.3.0)
- **Utility**: `utils/email_utils.js`
- **Features**: Email verification, password reset, HTML templates

**Directory Structure**:
- `routes/` - API endpoint handlers (37 route files, one per endpoint)
- `middleware/` - Auth middleware (JWT verification)
- `utils/` - Email utilities
- `server.js` - Entry point, route registration
- `db.js` - PostgreSQL connection pool
- `.env` - Environment variables (gitignored)

### Key Architectural Decisions

1. **Procedural Code Style**: Extensive comments, procedural style over OOP, readable for PowerBuilder developers
2. **File Naming**: All lowercase with underscores (e.g., `league_api.dart`, `login_user.js`)
3. **API Consistency**: All endpoints POST-only, consistent `/function_name` pattern, `return_code` in all responses
4. **One-to-One Naming**: Backend route files match Flutter API files (e.g., `routes/login_user.js` ↔ `api/login_user_api.dart`)
5. **Error Handling**: Centralized on both frontend and backend
6. **Accessibility**: Text scaling (normal/large/extra large) and high contrast mode
7. **Security**: JWT auth, bcrypt password hashing, parameterized SQL queries, secure token storage

## Database Schema

**Source of truth**: the live PostgreSQL database. We connect directly with the credentials in
`splitleague-server/.env` (`DATABASE_URL`) rather than keeping a schema file in the repo.
There is a stale `pg_dump` at `docs/archive/db-schema.sql` from July 2025 — do not trust it.

**Key Tables**:
- `app_user` - User accounts with email verification status
  - Fields: id, name, nickname, email, password_hash, email_verified, verification_token, accessed

- `league` - League definitions
  - Fields: id, name, created_by, start_date, end_date, public_code (4-digit join code), active, allow_code_share

- `league_members` - League membership (many-to-many)
  - Fields: id, league_id, user_id, joined_at, active, last_accessed, organiser_notes
  - Links users to leagues; supports guest players (users without accounts)

- `fixture` - Match fixtures between players
  - Fields: id, league_id, player_1_id, player_2_id, scheduled_date, played, player_1_score, player_2_score

- `league_points` - Scoring configuration per league
  - Fields: points_for_win, points_for_draw, points_for_win_margin, points_for_close_loss, win_margin_threshold, play_each_other, win_type
  - Supports: Points-based, Win-only, Win/Draw/Loss scoring systems

- `app_version_requirement` - Forces app updates
  - Platform-specific minimum version checking

- `deletion_log` - Audit trail for account deletions

**Key Relationships**:
- User creates leagues (1:many)
- Users join leagues via league_members (many:many)
- Fixtures belong to leagues and reference two players (many:1)
- League points configure league scoring (1:1 with league)

## Development Guidelines

### Code Style Requirements (from Project Guidelines.txt)
1. **Comments**: Extensive comments explaining functionality - written for PowerBuilder developers
2. **Code Style**: Procedural style with lots of spacing (not heavily object-oriented)
3. **File Naming**: All lowercase with underscores (e.g., `login_user_screen.dart`, `create_league.js`)
4. **Material Design**: Use Material Design 3 with styles from `lib/styles/app_styles.dart`

### File Headers

**Backend Routes** (`splitleague-server/routes/`):
```javascript
/*
=======================================================================================================================================
API Route: login_user
=======================================================================================================================================
Method: POST
Purpose: Authenticates a user using their email and password. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "email": "user@example.com",         // string, required
  "password": "securepassword123"      // string, required
}

Success Response:
{
  "return_code": "SUCCESS"
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth
  "user": {
    "id": 123,                         // integer, unique user ID
    "name": "Andreas",                 // string, user's name
    "email": "user@example.com",       // string, user's email
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CREDENTIALS"
"SERVER_ERROR"
=======================================================================================================================================
*/
```

**Flutter Screens** (`splitleague-flutter/lib/screens/`):
```dart
/*
Show the login screen allowing users to log into the application
This screen also has an option to Register if the user is not already registered
Once logged in, it goes straight to the dashboard
*/
```

### API Development Pattern

When creating/modifying endpoints, always update both sides:

1. **Backend** (`splitleague-server/routes/function_name.js`):
   ```javascript
   const express = require('express');
   const router = express.Router();

   router.post('/', async (req, res) => {
     // Implementation with return_code in response
   });

   module.exports = router;
   ```

2. **Register in server.js**:
   ```javascript
   const function_name = require('./routes/function_name');
   app.use('/function_name', function_name);
   ```

3. **Frontend API** (`splitleague-flutter/lib/api/function_name_api.dart`):
   ```dart
   class FunctionNameApi {
     static Future<Map<String, dynamic>> functionName(params) async {
       final url = Uri.parse('${Config.baseUrl}/function_name');
       final response = await http.post(url, ...);
       return jsonDecode(response.body);
     }
   }
   ```

### Key Development Rules

1. **API Changes**: When modifying endpoints, update both the route handler AND the corresponding Flutter API function
2. **State Management**: Use providers for any data that needs to persist across screens
3. **Database Changes**: Apply directly to PostgreSQL. There is no schema file to keep in sync.
4. **Testing**: Add widget tests for new UI components in `test/`
5. **Accessibility**: Ensure all UI components work with accessibility provider settings (text scaling, high contrast)
6. **Authentication**: Protected routes must use `auth_middleware.js` and check `req.userId`
7. **Security**: Always use parameterized queries (`$1, $2, ...`) - never string concatenation in SQL

### Adding a New Feature

Complete workflow from database to UI:

1. **Database** (if needed):
   - Add table/columns directly to PostgreSQL

2. **Backend Route**:
   - Create `splitleague-server/routes/function_name.js` with detailed header
   - Add auth middleware if needed: `const verifyToken = require('../middleware/auth_middleware');`
   - Use parameterized queries for database access
   - Return JSON with `return_code` field
   - Register route in `server.js`

3. **Frontend API**:
   - Create `splitleague-flutter/lib/api/function_name_api.dart`
   - Match naming exactly with backend route
   - Handle JWT token attachment if authenticated endpoint

4. **Frontend UI**:
   - Create models in `lib/models/` if needed
   - Add screen in `lib/screens/function_name_screen.dart` with header comment
   - Update navigation in `main.dart` if adding routes
   - Add shared state to providers if needed
   - Use Material Design 3 styles from `lib/styles/app_styles.dart`

5. **Testing**:
   - Add widget tests in `test/`