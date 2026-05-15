# Backend Production Checklist

Use this checklist before every production deploy that changes auth, sync, or environment configuration.

## 1. Required Environment

Render service: `new-calories-food-api`

Required variables:

```text
SPOONACULAR_API_KEY
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
PASSWORD_RESET_REDIRECT_URL=narutocalories://password-reset
```

Do not put real values in git.

## 2. Supabase Auth Configuration

Supabase project must allow this redirect URL:

```text
narutocalories://password-reset
```

Expected behavior:

```text
Forgot password -> email link -> iOS app opens -> new password screen appears
```

If Safari opens `localhost:3000`, check:

```text
PASSWORD_RESET_REDIRECT_URL on Render
Supabase Redirect URLs
Render latest deploy status
Whether the email link is from a newly sent email
```

## 3. Database Schema

Run these files in Supabase SQL Editor after schema changes:

```text
backend/supabase/schema.sql
backend/supabase/backend_hardening.sql
```

Expected protections:

```text
RLS enabled on all user-owned tables
user_id scoped policies on all user-owned tables
unique(user_id, client_id) for custom_foods, diary_entries, weight_logs
unique(user_id, log_date) for water_logs
updated_at triggers enabled
```

## 4. Pre-Deploy Checks

From repo root:

```bash
cd /Users/justndq42/Downloads/workspace/xcodenew/TheNewCaloriesTracker
find backend/src -name '*.js' -exec node --check {} \;
xcodebuild -project TheNewCaloriesTracker.xcodeproj -scheme TheNewCaloriesTracker -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath /private/tmp/TheNewCaloriesTrackerDerivedData build
git status --short
```

Do not deploy if syntax/build fails.

## 5. Deploy

Push to GitHub:

```bash
git push origin main
```

Then in Render:

```text
Manual Deploy -> Deploy latest commit
```

Wait until status is `Live`.

## 6. Post-Deploy Smoke Tests

Production health:

```bash
curl https://new-calories-food-api.onrender.com/health
curl https://new-calories-food-api.onrender.com/health/deep
```

Expected:

```json
{"ok":true}
```

Auth smoke test:

```text
sign up
login
forgot password
change password
logout
login again
```

Data sync smoke test:

```text
create profile
create custom food
log diary entry
add water
update weight
logout
login again
verify data returns
```

## 7. Log Review

Open Render Logs and check for structured JSON log events:

```text
server_started
http_request
auth_token_verification_failed
food_search_failed
profile_save_failed
```

No log line should contain access tokens, refresh tokens, passwords, service role keys, or API keys.
