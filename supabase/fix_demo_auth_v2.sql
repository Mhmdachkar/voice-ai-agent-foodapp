-- ============================================================
-- Fix demo user authentication (v2 - works without trigger disable)
-- The seed.sql inserted into auth.users but missed auth.identities,
-- which GoTrue needs for signInWithPassword to work.
-- 
-- Run this in Supabase SQL Editor AFTER fix_all_rls.sql
-- ============================================================

-- First, clean up all related data in correct order to avoid FK issues
-- 0) NULL out driver_status.current_order_id FK references first
UPDATE driver_status SET current_order_id = NULL WHERE current_order_id IN (
  SELECT id FROM orders WHERE user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
  )
);
-- 1) order_status_events and order_lines (depend on orders)
DELETE FROM order_status_events WHERE order_id IN (
  SELECT id FROM orders WHERE user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
  )
);
DELETE FROM order_lines WHERE order_id IN (
  SELECT id FROM orders WHERE user_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
  )
);
-- 2) orders (depend on profiles)
DELETE FROM orders WHERE user_id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333'
);
-- 3) driver_status, addresses (depend on profiles)
DELETE FROM driver_status WHERE driver_id IN (
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
);
DELETE FROM addresses WHERE user_id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333'
);
-- 4) profiles (depend on auth.users) - DELETE FIRST before auth.users/identities
DELETE FROM profiles WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
);
-- 5) auth.identities and auth.users
DELETE FROM auth.identities WHERE user_id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
);
DELETE FROM auth.users WHERE id IN (
  '11111111-1111-1111-1111-111111111111',
  '22222222-2222-2222-2222-222222222222',
  '33333333-3333-3333-3333-333333333333',
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'dddddddd-dddd-dddd-dddd-dddddddddddd',
  'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee'
);

-- Re-insert auth.users with all required fields
-- The handle_new_user trigger will auto-create basic profiles, which we'll update below
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
  role, aud, confirmation_token, recovery_token, email_change_token_new, email_change
) VALUES
  ('11111111-1111-1111-1111-111111111111',
   '00000000-0000-0000-0000-000000000000',
   'sarah@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Sarah Johnson","role":"customer"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', ''),

  ('22222222-2222-2222-2222-222222222222',
   '00000000-0000-0000-0000-000000000000',
   'mike@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Mike Chen","role":"customer"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', ''),

  ('33333333-3333-3333-3333-333333333333',
   '00000000-0000-0000-0000-000000000000',
   'emily@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Emily Davis","role":"customer"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', ''),

  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '00000000-0000-0000-0000-000000000000',
   'admin@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Alex Martinez","role":"admin"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', ''),

  ('dddddddd-dddd-dddd-dddd-dddddddddddd',
   '00000000-0000-0000-0000-000000000000',
   'james@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"James Wilson","role":"driver"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', ''),

  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
   '00000000-0000-0000-0000-000000000000',
   'lisa@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Lisa Park","role":"driver"}'::jsonb,
   '{"provider":"email","providers":["email"]}'::jsonb,
   'authenticated', 'authenticated', '', '', '', '');

-- Insert the identity records that GoTrue requires for email/password sign-in
INSERT INTO auth.identities (
  id, user_id, identity_data, provider, provider_id, last_sign_in_at, created_at, updated_at
) VALUES
  (gen_random_uuid(), '11111111-1111-1111-1111-111111111111',
   '{"sub":"11111111-1111-1111-1111-111111111111","email":"sarah@demo.com"}'::jsonb,
   'email', '11111111-1111-1111-1111-111111111111', now(), now(), now()),

  (gen_random_uuid(), '22222222-2222-2222-2222-222222222222',
   '{"sub":"22222222-2222-2222-2222-222222222222","email":"mike@demo.com"}'::jsonb,
   'email', '22222222-2222-2222-2222-222222222222', now(), now(), now()),

  (gen_random_uuid(), '33333333-3333-3333-3333-333333333333',
   '{"sub":"33333333-3333-3333-3333-333333333333","email":"emily@demo.com"}'::jsonb,
   'email', '33333333-3333-3333-3333-333333333333', now(), now(), now()),

  (gen_random_uuid(), 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '{"sub":"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa","email":"admin@demo.com"}'::jsonb,
   'email', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', now(), now(), now()),

  (gen_random_uuid(), 'dddddddd-dddd-dddd-dddd-dddddddddddd',
   '{"sub":"dddddddd-dddd-dddd-dddd-dddddddddddd","email":"james@demo.com"}'::jsonb,
   'email', 'dddddddd-dddd-dddd-dddd-dddddddddddd', now(), now(), now()),

  (gen_random_uuid(), 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
   '{"sub":"eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee","email":"lisa@demo.com"}'::jsonb,
   'email', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', now(), now(), now());

-- Update profiles with full data (trigger created basic ones, now we add food_memory and phone)
UPDATE profiles SET phone = '+1-555-0101', food_memory = '{"disliked_ingredients": ["cilantro","anchovies"], "spice_level": "medium", "default_drink": "Iced Latte", "common_notes": "Extra napkins please", "preferred_cuisines": ["Italian","Japanese"]}'::jsonb
WHERE id = '11111111-1111-1111-1111-111111111111';

UPDATE profiles SET phone = '+1-555-0102', food_memory = '{"disliked_ingredients": ["mushrooms"], "spice_level": "hot", "default_drink": "Mango Lassi", "common_notes": null, "preferred_cuisines": ["Thai","Indian"]}'::jsonb
WHERE id = '22222222-2222-2222-2222-222222222222';

UPDATE profiles SET phone = '+1-555-0103', food_memory = '{"disliked_ingredients": [], "spice_level": "mild", "default_drink": "Green Tea", "common_notes": "Ring doorbell", "preferred_cuisines": ["Mexican","American"]}'::jsonb
WHERE id = '33333333-3333-3333-3333-333333333333';

UPDATE profiles SET phone = '+1-555-0200'
WHERE id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

UPDATE profiles SET phone = '+1-555-0301'
WHERE id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

UPDATE profiles SET phone = '+1-555-0302'
WHERE id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';

-- Re-seed driver_status
INSERT INTO driver_status (driver_id, is_online, current_order_id, last_seen) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', true, NULL, now()),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', true, NULL, now())
ON CONFLICT (driver_id) DO UPDATE SET is_online = EXCLUDED.is_online, last_seen = EXCLUDED.last_seen;

-- Re-seed addresses
INSERT INTO addresses (user_id, label, street, city, state, zip, notes) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Home', '123 Oak Street', 'Springfield', 'IL', '62701', 'Ground floor, blue door'),
  ('11111111-1111-1111-1111-111111111111', 'Work', '456 Tech Park Ave', 'Springfield', 'IL', '62702', 'Lobby entrance'),
  ('22222222-2222-2222-2222-222222222222', 'Home', '789 Maple Drive', 'Springfield', 'IL', '62703', 'Apt 4B'),
  ('33333333-3333-3333-3333-333333333333', 'Home', '321 Pine Road', 'Springfield', 'IL', '62704', NULL);

-- Re-seed orders
-- Order 1: Sarah — DELIVERED (assigned to James)
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, assigned_driver_id, driver_name, created_at) VALUES
  ('00000001-0000-0000-0000-000000000000',
   '11111111-1111-1111-1111-111111111111', 'Sarah Johnson', 'DELIVERED',
   29.98, 3.99, 2.97, 5.00, 41.94,
   '{"street":"123 Oak Street","city":"Springfield","state":"IL","zip":"62701","notes":"Ground floor, blue door"}'::jsonb,
   'dddddddd-dddd-dddd-dddd-dddddddddddd', 'James Wilson',
   now() - interval '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000001-0000-0000-0000-000000000000', 'a1000001-0000-0000-0000-000000000000', 'Classic Smash Burger', 1, 12.99),
  ('00000001-0000-0000-0000-000000000000', 'a1000009-0000-0000-0000-000000000000', 'Truffle Carbonara',    1, 17.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, changed_by, changed_by_role, created_at) VALUES
  ('00000001-0000-0000-0000-000000000000', 'PLACED',           '11111111-1111-1111-1111-111111111111', 'customer', now() - interval '2 days'),
  ('00000001-0000-0000-0000-000000000000', 'ACCEPTED',         'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '2 days' + interval '5 minutes'),
  ('00000001-0000-0000-0000-000000000000', 'PREPARING',        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '2 days' + interval '10 minutes'),
  ('00000001-0000-0000-0000-000000000000', 'READY',            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '2 days' + interval '25 minutes'),
  ('00000001-0000-0000-0000-000000000000', 'OUT_FOR_DELIVERY', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'driver',  now() - interval '2 days' + interval '30 minutes'),
  ('00000001-0000-0000-0000-000000000000', 'DELIVERED',        'dddddddd-dddd-dddd-dddd-dddddddddddd', 'driver',  now() - interval '2 days' + interval '50 minutes');

-- Order 2: Mike — PREPARING (assigned to Lisa)
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, assigned_driver_id, driver_name, created_at) VALUES
  ('00000002-0000-0000-0000-000000000000',
   '22222222-2222-2222-2222-222222222222', 'Mike Chen', 'PREPARING',
   35.97, 3.99, 3.52, 7.00, 50.48,
   '{"street":"789 Maple Drive","city":"Springfield","state":"IL","zip":"62703","notes":"Apt 4B"}'::jsonb,
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Lisa Park',
   now() - interval '30 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000002-0000-0000-0000-000000000000', 'a1000005-0000-0000-0000-000000000000', 'Dragon Roll',           1, 18.99),
  ('00000002-0000-0000-0000-000000000000', 'a1000024-0000-0000-0000-000000000000', 'Korean BBQ Bowl',       1, 15.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, changed_by, changed_by_role, created_at) VALUES
  ('00000002-0000-0000-0000-000000000000', 'PLACED',    '22222222-2222-2222-2222-222222222222', 'customer', now() - interval '30 minutes'),
  ('00000002-0000-0000-0000-000000000000', 'ACCEPTED',  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '25 minutes'),
  ('00000002-0000-0000-0000-000000000000', 'PREPARING', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '20 minutes');

-- Order 3: Emily — PLACED (no driver yet)
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, notes, created_at) VALUES
  ('00000003-0000-0000-0000-000000000000',
   '33333333-3333-3333-3333-333333333333', 'Emily Davis', 'PLACED',
   24.48, 3.99, 2.38, 4.00, 34.85,
   '{"street":"321 Pine Road","city":"Springfield","state":"IL","zip":"62704","notes":null}'::jsonb,
   'Ring doorbell please',
   now() - interval '5 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000003-0000-0000-0000-000000000000', 'a1000011-0000-0000-0000-000000000000', 'Nashville Hot Chicken', 1, 14.99),
  ('00000003-0000-0000-0000-000000000000', 'a1000019-0000-0000-0000-000000000000', 'Truffle Parmesan Fries', 1, 8.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, changed_by, changed_by_role, created_at) VALUES
  ('00000003-0000-0000-0000-000000000000', 'PLACED', '33333333-3333-3333-3333-333333333333', 'customer', now() - interval '5 minutes');

-- Order 4: Sarah — OUT_FOR_DELIVERY (assigned to James)
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, assigned_driver_id, driver_name, created_at) VALUES
  ('00000004-0000-0000-0000-000000000000',
   '11111111-1111-1111-1111-111111111111', 'Sarah Johnson', 'OUT_FOR_DELIVERY',
   22.98, 3.99, 2.24, 4.50, 33.71,
   '{"street":"456 Tech Park Ave","city":"Springfield","state":"IL","zip":"62702","notes":"Lobby entrance"}'::jsonb,
   'dddddddd-dddd-dddd-dddd-dddddddddddd', 'James Wilson',
   now() - interval '45 minutes')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000004-0000-0000-0000-000000000000', 'a1000003-0000-0000-0000-000000000000', 'Margherita Neapolitan', 1, 14.99),
  ('00000004-0000-0000-0000-000000000000', 'a1000017-0000-0000-0000-000000000000', 'Mango Passion Smoothie', 1, 7.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, changed_by, changed_by_role, created_at) VALUES
  ('00000004-0000-0000-0000-000000000000', 'PLACED',           '11111111-1111-1111-1111-111111111111', 'customer', now() - interval '45 minutes'),
  ('00000004-0000-0000-0000-000000000000', 'ACCEPTED',         'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '40 minutes'),
  ('00000004-0000-0000-0000-000000000000', 'PREPARING',        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '35 minutes'),
  ('00000004-0000-0000-0000-000000000000', 'READY',            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '15 minutes'),
  ('00000004-0000-0000-0000-000000000000', 'OUT_FOR_DELIVERY', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 'driver',  now() - interval '10 minutes');

-- Order 5: Mike — DELIVERED (assigned to Lisa, yesterday)
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, assigned_driver_id, driver_name, created_at) VALUES
  ('00000005-0000-0000-0000-000000000000',
   '22222222-2222-2222-2222-222222222222', 'Mike Chen', 'DELIVERED',
   31.98, 3.99, 3.12, 6.00, 45.09,
   '{"street":"789 Maple Drive","city":"Springfield","state":"IL","zip":"62703","notes":"Apt 4B"}'::jsonb,
   'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'Lisa Park',
   now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000005-0000-0000-0000-000000000000', 'a1000010-0000-0000-0000-000000000000', 'Spicy Vodka Rigatoni', 1, 15.99),
  ('00000005-0000-0000-0000-000000000000', 'a1000023-0000-0000-0000-000000000000', 'Poke Power Bowl',     1, 16.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, changed_by, changed_by_role, created_at) VALUES
  ('00000005-0000-0000-0000-000000000000', 'PLACED',           '22222222-2222-2222-2222-222222222222', 'customer', now() - interval '1 day'),
  ('00000005-0000-0000-0000-000000000000', 'ACCEPTED',         'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '1 day' + interval '3 minutes'),
  ('00000005-0000-0000-0000-000000000000', 'PREPARING',        'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '1 day' + interval '8 minutes'),
  ('00000005-0000-0000-0000-000000000000', 'READY',            'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin',    now() - interval '1 day' + interval '20 minutes'),
  ('00000005-0000-0000-0000-000000000000', 'OUT_FOR_DELIVERY', 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'driver',  now() - interval '1 day' + interval '25 minutes'),
  ('00000005-0000-0000-0000-000000000000', 'DELIVERED',        'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'driver',  now() - interval '1 day' + interval '45 minutes');

-- Order 6: Emily — CANCELED
INSERT INTO orders (id, user_id, customer_name, status, subtotal, delivery_fee, tax, tip, total, address_snapshot, created_at) VALUES
  ('00000006-0000-0000-0000-000000000000',
   '33333333-3333-3333-3333-333333333333', 'Emily Davis', 'CANCELED',
   10.99, 3.99, 1.07, 0, 16.05,
   '{"street":"321 Pine Road","city":"Springfield","state":"IL","zip":"62704","notes":null}'::jsonb,
   now() - interval '3 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO order_lines (order_id, item_id, name_snapshot, qty, unit_price) VALUES
  ('00000006-0000-0000-0000-000000000000', 'a1000015-0000-0000-0000-000000000000', 'Molten Lava Cake', 1, 10.99)
ON CONFLICT DO NOTHING;

INSERT INTO order_status_events (order_id, status, note, changed_by, changed_by_role, created_at) VALUES
  ('00000006-0000-0000-0000-000000000000', 'PLACED',   NULL,                      '33333333-3333-3333-3333-333333333333', 'customer', now() - interval '3 days'),
  ('00000006-0000-0000-0000-000000000000', 'CANCELED', 'Customer changed mind',   '33333333-3333-3333-3333-333333333333', 'customer', now() - interval '3 days' + interval '2 minutes');

-- Update driver_status with current orders
UPDATE driver_status SET current_order_id = '00000004-0000-0000-0000-000000000000'
WHERE driver_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';
UPDATE driver_status SET current_order_id = '00000002-0000-0000-0000-000000000000'
WHERE driver_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';

-- Verify: should return 6 demo users
SELECT id, email FROM auth.users WHERE email LIKE '%@demo.com' ORDER BY email;
