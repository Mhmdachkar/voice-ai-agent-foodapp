-- ============================================================
-- NUCLEAR RLS FIX: Drop ALL policies on ALL tables, then
-- recreate them without any profiles subqueries.
--
-- This fixes the "infinite recursion detected in policy for
-- relation 'profiles'" error once and for all.
--
-- Run this in Supabase SQL Editor (Dashboard → SQL Editor).
-- ============================================================

-- ─── Step 1: Drop EVERY policy on every table ───────────────

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN (
    SELECT schemaname, tablename, policyname
    FROM pg_policies
    WHERE schemaname = 'public'
  ) LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I',
      r.policyname, r.schemaname, r.tablename);
  END LOOP;
END $$;

-- ─── Step 2: Recreate all policies cleanly ──────────────────

-- profiles
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- categories
CREATE POLICY "Categories are viewable by everyone"
  ON categories FOR SELECT USING (true);

-- menu_items
CREATE POLICY "Menu items are viewable by everyone"
  ON menu_items FOR SELECT USING (true);

-- modifier_groups
CREATE POLICY "Modifier groups are viewable by everyone"
  ON modifier_groups FOR SELECT USING (true);

-- modifier_options
CREATE POLICY "Modifier options are viewable by everyone"
  ON modifier_options FOR SELECT USING (true);

-- item_modifier_groups
CREATE POLICY "Item modifier groups are viewable by everyone"
  ON item_modifier_groups FOR SELECT USING (true);

-- orders
CREATE POLICY "Customers see own orders"
  ON orders FOR SELECT USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
  );
CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins and drivers can update orders"
  ON orders FOR UPDATE USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR auth.uid() = user_id
  );

-- order_lines
CREATE POLICY "Order lines follow order access"
  ON order_lines FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_lines.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );
CREATE POLICY "Order lines insertable by order owner"
  ON order_lines FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_lines.order_id AND orders.user_id = auth.uid())
  );

-- order_status_events
CREATE POLICY "Status events viewable by relevant users"
  ON order_status_events FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );
CREATE POLICY "Status events insertable by admin/driver"
  ON order_status_events FOR INSERT WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR EXISTS (SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id AND orders.user_id = auth.uid())
  );

-- driver_status
CREATE POLICY "Driver status viewable by everyone"
  ON driver_status FOR SELECT USING (true);
CREATE POLICY "Drivers can update own status"
  ON driver_status FOR UPDATE USING (auth.uid() = driver_id);
CREATE POLICY "Drivers can insert own status"
  ON driver_status FOR INSERT WITH CHECK (auth.uid() = driver_id);

-- addresses
CREATE POLICY "Users see own addresses"
  ON addresses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own addresses"
  ON addresses FOR ALL USING (auth.uid() = user_id);

-- ─── Step 3: Verify ─────────────────────────────────────────
-- This query should return rows without error:
SELECT id, name FROM menu_items LIMIT 1;
