# Backend Backup And Recovery Strategy

This app stores user-owned nutrition data in Supabase. The goal is to keep recovery simple enough for early production while avoiding accidental cross-user restore.

## Data To Protect

Critical tables:

```text
profiles
nutrition_goals
custom_foods
diary_entries
water_logs
weight_logs
auth.users
```

High-value data:

```text
profile and onboarding data
custom foods
diary entries
weight history
water history
```

Food search provider results are not critical because they can be fetched again.

## Current Recovery Model

Supabase is the source of truth after a user has logged in and synced.

The iOS app keeps local SwiftData for offline usage, but local data should not be considered a backup because it can disappear when the user deletes the app.

## Manual Export Before Risky Changes

Before schema changes or destructive migrations:

1. Open Supabase Dashboard.
2. Go to Table Editor.
3. Export each critical table as CSV.
4. Store exports outside the repo.
5. Label the folder with date and project name.

Suggested folder naming:

```text
new-calories-tracker-backup-YYYY-MM-DD
```

Never commit exported user data to git.

## Restore Rules

Restore must keep `user_id` unchanged.

Do not restore rows from one user into another user. User isolation depends on:

```text
auth.users.id
table.user_id
RLS policies
backend req.user.id
```

If restoring one user's data manually:

```text
1. Identify auth.users.id for that email.
2. Filter exported rows by that user_id.
3. Restore only matching rows.
4. Verify the user can log in and see only their data.
```

## Recommended Upgrade Path

When the app has real users, upgrade from manual export to scheduled database backups.

Minimum production target:

```text
daily database backups
7-30 day retention
documented restore test every release cycle
```

## Incident Checklist

If user data looks missing:

```text
1. Confirm the user is logged into the expected email.
2. Check Supabase auth.users for the user id.
3. Query user-owned tables by user_id.
4. Check Render logs for sync errors.
5. Check iOS app logs for auth_invalid_token or sync failures.
6. Do not delete local app data until server data has been inspected.
```

If duplicate data appears:

```text
1. Check client_id uniqueness.
2. Check whether the same local record was recreated with a new client_id.
3. Check pending deletes.
4. Prefer fixing sync mapping before manually deleting rows.
```

## Release Gate

Before public release:

```text
Run one manual backup export.
Run one single-user restore rehearsal on a test user.
Confirm restore does not leak another user's data.
```
