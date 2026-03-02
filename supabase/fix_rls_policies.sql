-- ============================================================
-- FIX: Infinite recursion in RLS policies
-- 
-- The old policies used "SELECT FROM profiles" to check roles,
-- but since profiles has RLS enabled, this creates infinite
-- recursion. This fix uses auth.jwt() -> 'user_metadata' ->> 'role'
-- to read the role from the JWT token instead.
--
-- Run this in Supabase SQL Editor to fix the issue.
-- ============================================================

-- 1. Drop and recreate orders SELECT policy
DROP POLICY IF EXISTS "Customers see own orders" ON orders;
CREATE POLICY "Customers see own orders"
  ON orders FOR SELECT USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
  );

-- 2. Drop and recreate orders UPDATE policy
DROP POLICY IF EXISTS "Admins and drivers can update orders" ON orders;
CREATE POLICY "Admins and drivers can update orders"
  ON orders FOR UPDATE USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR auth.uid() = user_id
  );

-- 3. Drop and recreate order_lines SELECT policy
DROP POLICY IF EXISTS "Order lines follow order access" ON order_lines;
CREATE POLICY "Order lines follow order access"
  ON order_lines FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_lines.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );

-- 4. Drop and recreate order_status_events SELECT policy
DROP POLICY IF EXISTS "Status events viewable by relevant users" ON order_status_events;
CREATE POLICY "Status events viewable by relevant users"
  ON order_status_events FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );

-- 5. Drop and recreate order_status_events INSERT policy
DROP POLICY IF EXISTS "Status events insertable by admin/driver" ON order_status_events;
CREATE POLICY "Status events insertable by admin/driver"
  ON order_status_events FOR INSERT WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR EXISTS (SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id AND orders.user_id = auth.uid())
  );

-- Done! The infinite recursion is now fixed.
-- All role checks now use auth.jwt() instead of querying the profiles table.
