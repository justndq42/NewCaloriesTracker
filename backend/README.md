# TheNewCaloriesTracker Food API

Small API proxy used by the iOS app to keep food-provider keys out of the app binary.

## Local Development

```bash
npm install
npm run dev
```

Health check:

```bash
curl http://localhost:8787/health
```

Food search:

```bash
curl "http://localhost:8787/foods/search?query=chicken"
```

## Auth

The iOS app should authenticate through this backend, then use the returned `access_token` when calling `/me/...` sync endpoints.

Sign up:

```bash
curl -X POST http://localhost:8787/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "12345678",
    "display_name": "Test User"
  }'
```

Log in:

```bash
curl -X POST http://localhost:8787/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "12345678"
  }'
```

Refresh an expired access token:

```bash
curl -X POST http://localhost:8787/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refresh_token": "YOUR_REFRESH_TOKEN"
  }'
```

## Environment

Copy `.env.example` to `.env` locally and fill in the real values.

```env
PORT=8787
SPOONACULAR_API_KEY=your_spoonacular_key_here
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your_supabase_anon_key_here
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key_here
PASSWORD_RESET_REDIRECT_URL=narutocalories://password-reset
```

Do not commit `.env`.

The backend validates user bearer tokens with `SUPABASE_ANON_KEY` and performs trusted server-side database work with `SUPABASE_SERVICE_ROLE_KEY`.

`PASSWORD_RESET_REDIRECT_URL` must match a Supabase Auth redirect URL. If it is missing or not deployed, password reset emails can fall back to the Supabase Site URL, commonly `http://localhost:3000`.

## Production Checks

Deep health check:

```bash
curl http://localhost:8787/health/deep
```

The API emits structured JSON logs with request IDs. Logs must not include passwords, access tokens, refresh tokens, Supabase service role keys, or provider API keys.

Production checklist:

```text
docs/backend-production-checklist.md
docs/backend-backup-recovery.md
docs/e2e-release-test.md
```

Database hardening SQL:

```text
backend/supabase/backend_hardening.sql
```

## Supabase Auth/Profile Smoke Test

Authenticated routes expect a Supabase access token:

```bash
curl http://localhost:8787/me/profile \
  -H "Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN"
```

Save or update a profile:

```bash
curl -X POST http://localhost:8787/me/profile \
  -H "Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "display_name": "Test User",
    "gender": "male",
    "age": 25,
    "height_cm": 170,
    "current_weight_kg": 70,
    "target_weight_kg": 65,
    "goal_type": "lose",
    "activity_level": "moderate"
  }'
```

## Authenticated Sync Endpoints

All sync endpoints require:

```bash
Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN
```

Available endpoints:

```text
GET  /me/nutrition-goals
POST /me/nutrition-goals

GET    /me/custom-foods
POST   /me/custom-foods
PUT    /me/custom-foods/:id
DELETE /me/custom-foods/:id

GET    /me/diary-entries?from=2026-05-08T00:00:00Z&to=2026-05-08T23:59:59Z
POST   /me/diary-entries
PUT    /me/diary-entries/:id
DELETE /me/diary-entries/:id

GET    /me/water-logs?date=2026-05-08
POST   /me/water-logs
DELETE /me/water-logs/:id

GET    /me/weight-logs
POST   /me/weight-logs
DELETE /me/weight-logs/:id
```

Example custom food:

```bash
curl -X POST http://localhost:8787/me/custom-foods \
  -H "Authorization: Bearer YOUR_SUPABASE_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Ức gà",
    "calories": 165,
    "protein_g": 31,
    "carbs_g": 0,
    "fat_g": 3.6,
    "unit": "100g"
  }'
```
