-- ============================================================
-- Schema additions for 10 new features
-- Run this AFTER fix_rls_policies.sql in Supabase SQL Editor
-- ============================================================

-- 1. Loyalty / Streak system
CREATE TABLE IF NOT EXISTS loyalty_profiles (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  points INTEGER NOT NULL DEFAULT 0,
  tier TEXT NOT NULL DEFAULT 'bronze' CHECK (tier IN ('bronze', 'silver', 'gold')),
  total_orders INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  longest_streak INTEGER NOT NULL DEFAULT 0,
  free_delivery_earned BOOLEAN NOT NULL DEFAULT FALSE,
  last_order_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE loyalty_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own loyalty" ON loyalty_profiles;
CREATE POLICY "Users can view own loyalty"
  ON loyalty_profiles FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can update own loyalty" ON loyalty_profiles;
CREATE POLICY "Users can update own loyalty"
  ON loyalty_profiles FOR UPDATE USING (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can insert own loyalty" ON loyalty_profiles;
CREATE POLICY "Users can insert own loyalty"
  ON loyalty_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 2. Order Feedback
CREATE TABLE IF NOT EXISTS order_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  food_rating INTEGER NOT NULL CHECK (food_rating BETWEEN 1 AND 5),
  driver_rating INTEGER CHECK (driver_rating BETWEEN 1 AND 5),
  temperature TEXT CHECK (temperature IN ('hot', 'warm', 'cold')),
  packaging_quality TEXT CHECK (packaging_quality IN ('excellent', 'good', 'poor')),
  missing_items TEXT[] DEFAULT '{}',
  photo_url TEXT,
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE order_feedback ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own feedback" ON order_feedback;
CREATE POLICY "Users can view own feedback"
  ON order_feedback FOR SELECT USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
DROP POLICY IF EXISTS "Users can insert own feedback" ON order_feedback;
CREATE POLICY "Users can insert own feedback"
  ON order_feedback FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 3. Order Incidents
CREATE TABLE IF NOT EXISTS order_incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('missing_item', 'wrong_order', 'cold_food', 'late_delivery', 'damaged', 'other')),
  description TEXT NOT NULL,
  photo_url TEXT,
  status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'in_review', 'resolved')),
  resolution TEXT CHECK (resolution IN ('refund_item', 'resend_item', 'apply_credit', 'full_refund', 'none')),
  resolution_note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

ALTER TABLE order_incidents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own incidents" ON order_incidents;
CREATE POLICY "Users can view own incidents"
  ON order_incidents FOR SELECT USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );
DROP POLICY IF EXISTS "Users can insert incidents" ON order_incidents;
CREATE POLICY "Users can insert incidents"
  ON order_incidents FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Admins can update incidents" ON order_incidents;
CREATE POLICY "Admins can update incidents"
  ON order_incidents FOR UPDATE USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') = 'admin'
  );

-- 4. Scheduled Orders
CREATE TABLE IF NOT EXISTS scheduled_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  item_ids TEXT[] DEFAULT '{}',
  delivery_time TEXT NOT NULL,
  recurrence TEXT NOT NULL DEFAULT 'once' CHECK (recurrence IN ('once', 'daily', 'weekly')),
  day_of_week INTEGER CHECK (day_of_week BETWEEN 0 AND 6),
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE scheduled_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can manage own schedules" ON scheduled_orders;
CREATE POLICY "Users can manage own schedules"
  ON scheduled_orders FOR ALL USING (auth.uid() = user_id);

-- 5. Group Orders
CREATE TABLE IF NOT EXISTS group_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  host_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  share_code TEXT NOT NULL UNIQUE,
  is_open BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE group_orders ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Group orders visible to all authenticated" ON group_orders;
CREATE POLICY "Group orders visible to all authenticated"
  ON group_orders FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Host can manage group" ON group_orders;
CREATE POLICY "Host can manage group"
  ON group_orders FOR UPDATE USING (auth.uid() = host_id);
DROP POLICY IF EXISTS "Any authenticated user can create group" ON group_orders;
CREATE POLICY "Any authenticated user can create group"
  ON group_orders FOR INSERT WITH CHECK (auth.uid() = host_id);

CREATE TABLE IF NOT EXISTS group_order_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES group_orders(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  items JSONB DEFAULT '[]',
  subtotal NUMERIC(10,2) DEFAULT 0,
  UNIQUE(group_id, user_id)
);

ALTER TABLE group_order_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Members visible to group participants" ON group_order_members;
CREATE POLICY "Members visible to group participants"
  ON group_order_members FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Users can manage own membership" ON group_order_members;
CREATE POLICY "Users can manage own membership"
  ON group_order_members FOR ALL USING (auth.uid() = user_id);

-- 6. Kitchen Queue (admin-managed)
CREATE TABLE IF NOT EXISTS kitchen_queue (
  order_id UUID PRIMARY KEY REFERENCES orders(id) ON DELETE CASCADE,
  position INTEGER NOT NULL DEFAULT 0,
  stage TEXT NOT NULL DEFAULT 'queued' CHECK (stage IN ('queued', 'preparing', 'cooking', 'plating', 'ready')),
  estimated_minutes INTEGER NOT NULL DEFAULT 20,
  started_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE kitchen_queue ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Kitchen queue visible to all authenticated" ON kitchen_queue;
CREATE POLICY "Kitchen queue visible to all authenticated"
  ON kitchen_queue FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Admin/driver can manage kitchen queue" ON kitchen_queue;
CREATE POLICY "Admin/driver can manage kitchen queue"
  ON kitchen_queue FOR ALL USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin', 'driver')
  );

-- Done!
-- All new feature tables created with proper RLS policies.
