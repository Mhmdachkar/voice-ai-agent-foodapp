# 🚀 Quick Auth Fix Guide

## The Problem

You're seeing auth errors when trying to sign up. This is almost certainly because **the database migration hasn't been run yet** in your Supabase project.

---

## ✅ The Solution (5 minutes)

### Step 1: Open Supabase Dashboard

1. Go to: https://app.supabase.com
2. Select your project (`oqhtxyzfvwsiyqignikt`)
3. Click **SQL Editor** in the left sidebar

### Step 2: Run the Migration

1. Click **"New Query"**
2. Open this file: `C:\Users\User\OneDrive\Desktop\food app\supabase\migrations\001_initial_schema.sql`
3. Copy **ALL** the contents (it's a long file with ~480 lines)
4. Paste into the Supabase SQL Editor
5. Click **"Run"** (bottom right)

You should see: ✅ **"Success. No rows returned"**

### Step 3: Verify the Trigger

Run this in SQL Editor:

```sql
SELECT 
    trigger_name,
    event_object_table
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
```

Expected result:
```
trigger_name: on_auth_user_created
event_object_table: users
```

### Step 4: Check Auth Settings (Optional but Recommended)

1. Go to **Authentication → Settings** (left sidebar)
2. **Email Confirmations**: Disable for development testing
3. **Auto-confirm users**: Enable for development testing

### Step 5: Test Sign-Up

1. Restart your app: `npm start`
2. Open in Expo Go
3. Try signing up:
   - Email: `test@example.com`
   - Password: `testpass123`
   - Full Name: `Test User`
   - Role: `customer`

4. Watch the console/terminal for `[AUTH]` logs

---

## 🔍 Debug Logs

I've added comprehensive logging to `AuthService.ts`. You'll see:

```
[AUTH] Starting signup: { email: "...", fullName: "...", role: "..." }
[AUTH] Signup response: { userId: "...", error: null, session: true }
[AUTH] Fetching profile for: "..."
[AUTH] Profile fetched: Found
[AUTH] User mapped successfully: Test User customer
```

**If you see "Profile not found"**, the migration definitely hasn't run.

---

## 🎯 What the Migration Does

The migration creates:
1. ✅ All database tables (`profiles`, `orders`, `menu_items`, etc.)
2. ✅ **Critical trigger** that auto-creates profile when user signs up
3. ✅ RLS policies for security
4. ✅ Supabase functions for orders (`create_order`, `update_order_status`, etc.)
5. ✅ Sample menu data (14 items across all categories)
6. ✅ Sample promo codes (`SAVE10`, `FREE5`, `WELCOME20`)

---

## 🚨 Common Errors & Fixes

### Error: "Profile not created. Please ensure database migration is complete."

**Cause:** Migration not run or trigger failed.

**Fix:** Run the migration (Step 2 above).

---

### Error: "Invalid login credentials"

**Cause:** User doesn't exist or wrong password.

**Fix:** 
1. Try signing up first (don't sign in)
2. Or check: Supabase Dashboard → Authentication → Users

---

### Error: "Email rate limit exceeded"

**Cause:** Too many signup attempts.

**Fix:** Wait 1 hour or use different email.

---

### Error: "User already registered"

**Cause:** Email already used.

**Fix:** 
1. Use different email, OR
2. Try signing in instead of signing up, OR
3. Delete user: Supabase Dashboard → Authentication → Users → Delete

---

## ✅ After Migration is Run

Your app will have:

1. ✅ **Working authentication** (sign up, sign in, sign out)
2. ✅ **14 menu items** across all categories
3. ✅ **Profile auto-creation** for new users
4. ✅ **Role-based access** (customer/admin/driver)
5. ✅ **Order creation** via RPC functions
6. ✅ **Promo codes** ready to use
7. ✅ **Realtime subscriptions** configured

---

## 📊 Verify Data After Migration

Run these to see sample data:

```sql
-- Check categories
SELECT * FROM categories ORDER BY sort_order;

-- Check menu items
SELECT name, price, category_id FROM menu_items;

-- Check promo codes
SELECT code, type, value FROM promotions;
```

You should see:
- 12 categories (Burgers, Pizza, Sushi, etc.)
- 14 menu items
- 3 promo codes

---

## 🎉 You're Done!

After running the migration:
1. ✅ Authentication will work perfectly
2. ✅ Full feature parity with Swift app
3. ✅ All services operational
4. ✅ Complete customer ordering flow

Try the app again and signup should work flawlessly!
