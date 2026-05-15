# End-To-End Release Test

Run this checklist on a real iPhone before release or before major backend deploys.

## Test Setup

Use:

```text
real iPhone
production backend: https://new-calories-food-api.onrender.com
real email inbox
at least two test users
```

Delete the app before first-run tests if you need a clean install.

## 1. New User Flow

```text
1. Open app after fresh install.
2. Auth screen appears before Nutrition Profile.
3. Register with a real email.
4. Confirm email if Supabase requires it.
5. Log in.
6. Nutrition Profile appears.
7. Complete profile.
8. Main app appears.
```

Pass condition:

```text
Profile is created once and app does not ask for profile again after login.
```

## 2. Existing User Restore

```text
1. Log custom food.
2. Log diary entry.
3. Add water.
4. Update weight.
5. Logout.
6. Login again with the same user.
```

Pass condition:

```text
The user's previous profile and logged data return without duplicate rows.
```

## 3. Multi-User Isolation

```text
1. User A logs one custom food and one diary entry.
2. User A logs out.
3. User B logs in or signs up.
4. User B checks dashboard, diary, custom foods, water, weight.
5. User B logs different data.
6. User B logs out.
7. User A logs in again.
```

Pass condition:

```text
User B never sees User A data.
User A data returns after User A logs back in.
```

## 4. Offline Sync

```text
1. Login while online.
2. Turn off network.
3. Create or delete a diary entry.
4. Create or delete a custom food.
5. Turn network back on.
6. Close and reopen app.
7. Logout and login again.
```

Pass condition:

```text
No data loss.
No duplicate entries.
Deleted remote records do not come back.
```

## 5. Password Reset

```text
1. On login screen, tap forgot password.
2. Enter real email.
3. Open the newest reset email on iPhone.
4. Tap the email link.
5. App opens through narutocalories://password-reset.
6. Set a new password.
7. Login with the new password.
```

Pass condition:

```text
Safari does not open localhost.
App opens the reset password sheet.
Old password no longer logs in.
New password logs in.
```

## 6. Account Security

```text
1. Login.
2. Change password from Account screen.
3. Logout.
4. Login with new password.
5. Try login with old password.
```

Pass condition:

```text
New password works.
Old password fails.
```

## 7. Delete Account

Use a disposable test account.

```text
1. Create test account.
2. Add profile and data.
3. Delete account from app.
4. Try login again.
5. Check Supabase auth.users.
6. Check user-owned tables by user_id if needed.
```

Pass condition:

```text
Login fails after delete.
Server rows are deleted by cascade or no longer accessible.
```

## 8. Production Logs

During the tests, Render logs should show:

```text
http_request
status_code 2xx for success
status_code 4xx for expected invalid password/token cases
no leaked tokens or passwords
```

## Release Decision

Release is blocked if any of these fail:

```text
cross-user data leak
profile appears before auth on fresh install
reset password link opens localhost
offline delete comes back after sync
duplicate diary/custom food rows after re-login
```
