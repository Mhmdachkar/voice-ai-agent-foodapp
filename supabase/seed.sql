-- ============================================================
-- SmartFood Delivery App — Full Seed Data
-- Run this in your Supabase SQL Editor to populate all tables
-- with interconnected mock data for Customer, Driver & Admin.
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 0. SCHEMA (create tables if they don't exist)
-- ────────────────────────────────────────────────────────────

-- Profiles (extends Supabase auth.users)
-- Drop FK to auth.users if it exists (allows direct seeding without auth entries)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'profiles_id_fkey'
    AND table_name = 'profiles'
  ) THEN
    ALTER TABLE profiles DROP CONSTRAINT profiles_id_fkey;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS profiles (
  id         UUID PRIMARY KEY,
  role       TEXT NOT NULL DEFAULT 'customer' CHECK (role IN ('customer','admin','driver')),
  full_name  TEXT NOT NULL DEFAULT '',
  email      TEXT,
  phone      TEXT,
  avatar_url TEXT,
  food_memory JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, role, full_name, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'role', 'customer'),
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Categories
CREATE TABLE IF NOT EXISTS categories (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  icon       TEXT,
  sort_order INT DEFAULT 0
);

-- Menu Items
CREATE TABLE IF NOT EXISTS menu_items (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id      UUID REFERENCES categories(id),
  name             TEXT NOT NULL,
  description      TEXT,
  price            NUMERIC(8,2) NOT NULL DEFAULT 0,
  image_url        TEXT,
  tags             TEXT[] DEFAULT '{}',
  calories         INT DEFAULT 0,
  prep_time_minutes INT DEFAULT 15,
  rating           NUMERIC(2,1) DEFAULT 4.0,
  review_count     INT DEFAULT 0,
  is_available     BOOLEAN DEFAULT TRUE,
  is_limited_time  BOOLEAN DEFAULT FALSE,
  limited_time_end TIMESTAMPTZ,
  nutrition_info   JSONB DEFAULT '{}',
  ingredients      TEXT[] DEFAULT '{}',
  allergens        TEXT[] DEFAULT '{}'
);

-- Modifier Groups
CREATE TABLE IF NOT EXISTS modifier_groups (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name       TEXT NOT NULL,
  min_select INT DEFAULT 0,
  max_select INT DEFAULT 1,
  required   BOOLEAN DEFAULT FALSE
);

-- Modifier Options
CREATE TABLE IF NOT EXISTS modifier_options (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id     UUID REFERENCES modifier_groups(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  price_delta  NUMERIC(8,2) DEFAULT 0,
  is_available BOOLEAN DEFAULT TRUE
);

-- Item ↔ Modifier Group join table
CREATE TABLE IF NOT EXISTS item_modifier_groups (
  item_id  UUID REFERENCES menu_items(id) ON DELETE CASCADE,
  group_id UUID REFERENCES modifier_groups(id) ON DELETE CASCADE,
  PRIMARY KEY (item_id, group_id)
);

-- Orders
CREATE TABLE IF NOT EXISTS orders (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES profiles(id),
  customer_name    TEXT,
  delivery_method  TEXT DEFAULT 'delivery',
  status           TEXT NOT NULL DEFAULT 'PLACED'
                     CHECK (status IN ('PLACED','ACCEPTED','PREPARING','READY','OUT_FOR_DELIVERY','DELIVERED','CANCELED')),
  payment_method   TEXT DEFAULT 'card',
  subtotal         NUMERIC(8,2) DEFAULT 0,
  delivery_fee     NUMERIC(8,2) DEFAULT 3.99,
  tax              NUMERIC(8,2) DEFAULT 0,
  discount         NUMERIC(8,2) DEFAULT 0,
  tip              NUMERIC(8,2) DEFAULT 0,
  total            NUMERIC(8,2) DEFAULT 0,
  address_snapshot JSONB DEFAULT '{}',
  notes            TEXT,
  promo_code       TEXT,
  assigned_driver_id UUID REFERENCES profiles(id),
  driver_name      TEXT,
  created_at       TIMESTAMPTZ DEFAULT now(),
  updated_at       TIMESTAMPTZ DEFAULT now()
);

-- Order Lines
CREATE TABLE IF NOT EXISTS order_lines (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id           UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  item_id            UUID REFERENCES menu_items(id),
  name_snapshot      TEXT NOT NULL,
  image_url_snapshot TEXT,
  qty                INT DEFAULT 1,
  unit_price         NUMERIC(8,2) DEFAULT 0,
  notes              TEXT
);

-- Order Status Events (timeline)
CREATE TABLE IF NOT EXISTS order_status_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
  status          TEXT NOT NULL,
  note            TEXT,
  changed_by      UUID,
  changed_by_role TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

-- Driver Status
CREATE TABLE IF NOT EXISTS driver_status (
  driver_id        UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  is_online        BOOLEAN DEFAULT FALSE,
  current_order_id UUID,
  last_seen        TIMESTAMPTZ DEFAULT now()
);

-- Saved Addresses
CREATE TABLE IF NOT EXISTS addresses (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID REFERENCES profiles(id) ON DELETE CASCADE,
  label        TEXT,
  address_text TEXT,
  street       TEXT,
  city         TEXT,
  state        TEXT,
  zip          TEXT,
  notes        TEXT
);

-- Enable realtime on key tables (drop first to avoid "already member" errors)
DO $$
BEGIN
  -- Try to drop tables from publication, ignore errors if not present
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE orders;
  EXCEPTION
    WHEN undefined_object THEN NULL;
    WHEN others THEN NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE order_status_events;
  EXCEPTION
    WHEN undefined_object THEN NULL;
    WHEN others THEN NULL;
  END;
  
  BEGIN
    ALTER PUBLICATION supabase_realtime DROP TABLE driver_status;
  EXCEPTION
    WHEN undefined_object THEN NULL;
    WHEN others THEN NULL;
  END;
END $$;

ALTER PUBLICATION supabase_realtime ADD TABLE orders;
ALTER PUBLICATION supabase_realtime ADD TABLE order_status_events;
ALTER PUBLICATION supabase_realtime ADD TABLE driver_status;

-- ────────────────────────────────────────────────────────────
-- 1. AUTH USERS + PROFILES
-- ────────────────────────────────────────────────────────────
-- Insert into auth.users first so the FK constraint is satisfied,
-- then insert profiles (trigger may also auto-create them, ON CONFLICT handles that).

INSERT INTO auth.users (
  id, instance_id, email, encrypted_password, email_confirmed_at,
  created_at, updated_at, raw_user_meta_data, role, aud
) VALUES
  ('11111111-1111-1111-1111-111111111111',
   '00000000-0000-0000-0000-000000000000',
   'sarah@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Sarah Johnson","role":"customer"}'::jsonb, 'authenticated', 'authenticated'),

  ('22222222-2222-2222-2222-222222222222',
   '00000000-0000-0000-0000-000000000000',
   'mike@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Mike Chen","role":"customer"}'::jsonb, 'authenticated', 'authenticated'),

  ('33333333-3333-3333-3333-333333333333',
   '00000000-0000-0000-0000-000000000000',
   'emily@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Emily Davis","role":"customer"}'::jsonb, 'authenticated', 'authenticated'),

  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
   '00000000-0000-0000-0000-000000000000',
   'admin@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Alex Martinez","role":"admin"}'::jsonb, 'authenticated', 'authenticated'),

  ('dddddddd-dddd-dddd-dddd-dddddddddddd',
   '00000000-0000-0000-0000-000000000000',
   'james@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"James Wilson","role":"driver"}'::jsonb, 'authenticated', 'authenticated'),

  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
   '00000000-0000-0000-0000-000000000000',
   'lisa@demo.com', crypt('Demo1234!', gen_salt('bf')), now(), now(), now(),
   '{"full_name":"Lisa Park","role":"driver"}'::jsonb, 'authenticated', 'authenticated')

ON CONFLICT (id) DO NOTHING;

-- Customer 1: Sarah Johnson
INSERT INTO profiles (id, role, full_name, email, phone, food_memory) VALUES
  ('11111111-1111-1111-1111-111111111111', 'customer', 'Sarah Johnson', 'sarah@demo.com', '+1-555-0101',
   '{"disliked_ingredients": ["cilantro","anchovies"], "spice_level": "medium", "default_drink": "Iced Latte", "common_notes": "Extra napkins please", "preferred_cuisines": ["Italian","Japanese"]}'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone, food_memory = EXCLUDED.food_memory;

-- Customer 2: Mike Chen
INSERT INTO profiles (id, role, full_name, email, phone, food_memory) VALUES
  ('22222222-2222-2222-2222-222222222222', 'customer', 'Mike Chen', 'mike@demo.com', '+1-555-0102',
   '{"disliked_ingredients": ["mushrooms"], "spice_level": "hot", "default_drink": "Mango Lassi", "common_notes": null, "preferred_cuisines": ["Thai","Indian"]}'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone, food_memory = EXCLUDED.food_memory;

-- Customer 3: Emily Davis
INSERT INTO profiles (id, role, full_name, email, phone, food_memory) VALUES
  ('33333333-3333-3333-3333-333333333333', 'customer', 'Emily Davis', 'emily@demo.com', '+1-555-0103',
   '{"disliked_ingredients": [], "spice_level": "mild", "default_drink": "Green Tea", "common_notes": "Ring doorbell", "preferred_cuisines": ["Mexican","American"]}'::jsonb
  )
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone, food_memory = EXCLUDED.food_memory;

-- Admin: Alex Martinez
INSERT INTO profiles (id, role, full_name, email, phone) VALUES
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'admin', 'Alex Martinez', 'admin@demo.com', '+1-555-0200')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone;

-- Driver 1: James Wilson
INSERT INTO profiles (id, role, full_name, email, phone) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'driver', 'James Wilson', 'james@demo.com', '+1-555-0301')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone;

-- Driver 2: Lisa Park
INSERT INTO profiles (id, role, full_name, email, phone) VALUES
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', 'driver', 'Lisa Park', 'lisa@demo.com', '+1-555-0302')
ON CONFLICT (id) DO UPDATE SET role = EXCLUDED.role, full_name = EXCLUDED.full_name, email = EXCLUDED.email, phone = EXCLUDED.phone;


-- ────────────────────────────────────────────────────────────
-- 2. CATEGORIES
-- ────────────────────────────────────────────────────────────

INSERT INTO categories (id, name, icon, sort_order) VALUES
  ('d4000001-0000-0000-0000-000000000000', 'Burgers',   '🍔', 1),
  ('d4000002-0000-0000-0000-000000000000', 'Pizza',     '🍕', 2),
  ('d4000003-0000-0000-0000-000000000000', 'Sushi',     '🍣', 3),
  ('d4000004-0000-0000-0000-000000000000', 'Salads',    '🥗', 4),
  ('d4000005-0000-0000-0000-000000000000', 'Pasta',     '🍝', 5),
  ('d4000006-0000-0000-0000-000000000000', 'Chicken',   '🍗', 6),
  ('d4000007-0000-0000-0000-000000000000', 'Seafood',   '🦐', 7),
  ('d4000008-0000-0000-0000-000000000000', 'Desserts',  '🍰', 8),
  ('d4000009-0000-0000-0000-000000000000', 'Drinks',    '🥤', 9),
  ('d400000a-0000-0000-0000-000000000000', 'Sides',     '🍟', 10),
  ('d400000b-0000-0000-0000-000000000000', 'Breakfast', '🥞', 11),
  ('d400000c-0000-0000-0000-000000000000', 'Bowls',     '🍜', 12)
ON CONFLICT (id) DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 3. MENU ITEMS (24 items across categories)
-- ────────────────────────────────────────────────────────────

INSERT INTO menu_items (id, category_id, name, description, price, image_url, tags, calories, prep_time_minutes, rating, review_count, is_available, nutrition_info, ingredients, allergens) VALUES

('a1000001-0000-0000-0000-000000000000', 'd4000001-0000-0000-0000-000000000000',
 'Classic Smash Burger', 'Double smashed patties, American cheese, pickles, special sauce on brioche bun',
 12.99, NULL, ARRAY['popular','beef'], 650, 12, 4.7, 234, TRUE,
 '{"calories":650,"protein":38,"carbs":42,"fat":35,"fiber":2,"sugar":8}',
 ARRAY['beef patty','American cheese','brioche bun','pickles','special sauce','lettuce','tomato'],
 ARRAY['gluten','dairy']::text[]),

('a1000002-0000-0000-0000-000000000000', 'd4000001-0000-0000-0000-000000000000',
 'Truffle Mushroom Burger', 'Angus beef, truffle aioli, sauteed mushrooms, gruyere cheese, arugula',
 16.99, NULL, ARRAY['premium','truffle'], 720, 15, 4.9, 187, TRUE,
 '{"calories":720,"protein":42,"carbs":38,"fat":40,"fiber":3,"sugar":6}',
 ARRAY['angus beef','truffle aioli','mushrooms','gruyere','arugula','brioche bun'],
 ARRAY['gluten','dairy']),

('a1000003-0000-0000-0000-000000000000', 'd4000002-0000-0000-0000-000000000000',
 'Margherita Neapolitan', 'San Marzano tomatoes, fresh mozzarella, basil, EVOO, wood-fired',
 14.99, NULL, ARRAY['vegetarian','classic'], 540, 18, 4.8, 312, TRUE,
 '{"calories":540,"protein":22,"carbs":62,"fat":20,"fiber":4,"sugar":6}',
 ARRAY['pizza dough','San Marzano tomatoes','fresh mozzarella','basil','olive oil'],
 ARRAY['gluten','dairy']),

('a1000004-0000-0000-0000-000000000000', 'd4000002-0000-0000-0000-000000000000',
 'Spicy Pepperoni', 'Calabrian chili, pepperoni, mozzarella, hot honey drizzle',
 15.99, NULL, ARRAY['spicy','popular'], 680, 18, 4.6, 278, TRUE,
 '{"calories":680,"protein":28,"carbs":60,"fat":32,"fiber":3,"sugar":5}',
 ARRAY['pizza dough','pepperoni','mozzarella','Calabrian chili','hot honey'],
 ARRAY['gluten','dairy']),

('a1000005-0000-0000-0000-000000000000', 'd4000003-0000-0000-0000-000000000000',
 'Dragon Roll', 'Shrimp tempura, avocado, eel sauce, tobiko, cucumber',
 18.99, NULL, ARRAY['signature','seafood'], 420, 20, 4.9, 198, TRUE,
 '{"calories":420,"protein":18,"carbs":52,"fat":16,"fiber":4,"sugar":8}',
 ARRAY['shrimp tempura','avocado','cucumber','eel sauce','tobiko','sushi rice','nori'],
 ARRAY['shellfish','soy','gluten']),

('a1000006-0000-0000-0000-000000000000', 'd4000003-0000-0000-0000-000000000000',
 'Salmon Sashimi Platter', '12 pieces of premium Norwegian salmon sashimi with wasabi and ginger',
 22.99, NULL, ARRAY['premium','low-carb'], 320, 10, 4.8, 156, TRUE,
 '{"calories":320,"protein":40,"carbs":2,"fat":16,"fiber":0,"sugar":0}',
 ARRAY['Norwegian salmon','wasabi','pickled ginger','soy sauce'],
 ARRAY['fish','soy']),

('a1000007-0000-0000-0000-000000000000', 'd4000004-0000-0000-0000-000000000000',
 'Grilled Caesar', 'Romaine hearts, grilled chicken, parmesan crisps, house caesar dressing, croutons',
 13.99, NULL, ARRAY['healthy','protein'], 380, 10, 4.5, 167, TRUE,
 '{"calories":380,"protein":32,"carbs":18,"fat":22,"fiber":4,"sugar":3}',
 ARRAY['romaine','grilled chicken','parmesan','croutons','caesar dressing'],
 ARRAY['dairy','gluten','eggs']),

('a1000008-0000-0000-0000-000000000000', 'd4000004-0000-0000-0000-000000000000',
 'Thai Mango Crunch', 'Mixed greens, mango, edamame, crispy wontons, peanuts, sesame ginger dressing',
 14.49, NULL, ARRAY['vegan-option','fresh'], 340, 8, 4.7, 143, TRUE,
 '{"calories":340,"protein":12,"carbs":38,"fat":16,"fiber":6,"sugar":18}',
 ARRAY['mixed greens','mango','edamame','wontons','peanuts','sesame ginger dressing'],
 ARRAY['peanuts','soy','gluten']),

('a1000009-0000-0000-0000-000000000000', 'd4000005-0000-0000-0000-000000000000',
 'Truffle Carbonara', 'Spaghetti, guanciale, pecorino, egg yolk, black truffle, black pepper',
 17.99, NULL, ARRAY['premium','classic'], 720, 15, 4.8, 201, TRUE,
 '{"calories":720,"protein":28,"carbs":68,"fat":36,"fiber":3,"sugar":2}',
 ARRAY['spaghetti','guanciale','pecorino romano','egg yolk','black truffle','black pepper'],
 ARRAY['gluten','dairy','eggs']),

('a1000010-0000-0000-0000-000000000000', 'd4000005-0000-0000-0000-000000000000',
 'Spicy Vodka Rigatoni', 'Rigatoni, spicy tomato vodka cream sauce, fresh basil, parmesan',
 15.99, NULL, ARRAY['spicy','popular'], 640, 14, 4.6, 245, TRUE,
 '{"calories":640,"protein":22,"carbs":72,"fat":28,"fiber":4,"sugar":10}',
 ARRAY['rigatoni','tomato','vodka','cream','basil','parmesan','chili flakes'],
 ARRAY['gluten','dairy']),

('a1000011-0000-0000-0000-000000000000', 'd4000006-0000-0000-0000-000000000000',
 'Nashville Hot Chicken', 'Crispy brined chicken, cayenne glaze, pickles, coleslaw, brioche',
 14.99, NULL, ARRAY['spicy','popular'], 580, 18, 4.7, 289, TRUE,
 '{"calories":580,"protein":35,"carbs":42,"fat":28,"fiber":2,"sugar":6}',
 ARRAY['chicken breast','cayenne','pickles','coleslaw','brioche bun'],
 ARRAY['gluten','eggs']),

('a1000012-0000-0000-0000-000000000000', 'd4000006-0000-0000-0000-000000000000',
 'Lemon Herb Grilled Chicken', 'Marinated chicken breast, roasted vegetables, herb chimichurri, quinoa',
 15.49, NULL, ARRAY['healthy','high-protein'], 420, 20, 4.5, 178, TRUE,
 '{"calories":420,"protein":42,"carbs":28,"fat":16,"fiber":5,"sugar":4}',
 ARRAY['chicken breast','lemon','herbs','roasted vegetables','quinoa','chimichurri'],
 ARRAY[]::text[]),

('a1000013-0000-0000-0000-000000000000', 'd4000007-0000-0000-0000-000000000000',
 'Garlic Butter Shrimp', 'Tiger shrimp, garlic butter, white wine, crusty bread, lemon',
 19.99, NULL, ARRAY['premium','seafood'], 380, 14, 4.8, 134, TRUE,
 '{"calories":380,"protein":28,"carbs":22,"fat":20,"fiber":1,"sugar":2}',
 ARRAY['tiger shrimp','garlic','butter','white wine','bread','lemon','parsley'],
 ARRAY['shellfish','gluten','dairy']),

('a1000014-0000-0000-0000-000000000000', 'd4000007-0000-0000-0000-000000000000',
 'Fish Tacos', 'Beer-battered cod, cabbage slaw, chipotle crema, lime, corn tortillas',
 13.99, NULL, ARRAY['popular','fresh'], 440, 15, 4.6, 212, TRUE,
 '{"calories":440,"protein":24,"carbs":38,"fat":22,"fiber":4,"sugar":5}',
 ARRAY['cod','cabbage','chipotle crema','lime','corn tortillas','cilantro'],
 ARRAY['fish','gluten']),

('a1000015-0000-0000-0000-000000000000', 'd4000008-0000-0000-0000-000000000000',
 'Molten Lava Cake', 'Dark chocolate fondant, vanilla bean ice cream, raspberry coulis',
 10.99, NULL, ARRAY['indulgent','chocolate'], 520, 12, 4.9, 267, TRUE,
 '{"calories":520,"protein":8,"carbs":58,"fat":30,"fiber":3,"sugar":42}',
 ARRAY['dark chocolate','butter','eggs','flour','vanilla ice cream','raspberries'],
 ARRAY['gluten','dairy','eggs']),

('a1000016-0000-0000-0000-000000000000', 'd4000008-0000-0000-0000-000000000000',
 'Matcha Tiramisu', 'Layers of matcha cream, mascarpone, ladyfingers, white chocolate shavings',
 11.99, NULL, ARRAY['unique','matcha'], 460, 5, 4.7, 189, TRUE,
 '{"calories":460,"protein":10,"carbs":48,"fat":26,"fiber":1,"sugar":32}',
 ARRAY['matcha','mascarpone','ladyfingers','white chocolate','cream'],
 ARRAY['gluten','dairy','eggs']),

('a1000017-0000-0000-0000-000000000000', 'd4000009-0000-0000-0000-000000000000',
 'Mango Passion Smoothie', 'Mango, passion fruit, banana, coconut milk, honey',
 7.99, NULL, ARRAY['fresh','tropical'], 280, 5, 4.6, 198, TRUE,
 '{"calories":280,"protein":4,"carbs":52,"fat":8,"fiber":4,"sugar":38}',
 ARRAY['mango','passion fruit','banana','coconut milk','honey'],
 ARRAY[]::text[]),

('a1000018-0000-0000-0000-000000000000', 'd4000009-0000-0000-0000-000000000000',
 'Cold Brew Caramel Latte', 'Slow-dripped cold brew, caramel, oat milk, vanilla',
 6.49, NULL, ARRAY['caffeine','popular'], 180, 3, 4.5, 234, TRUE,
 '{"calories":180,"protein":2,"carbs":28,"fat":6,"fiber":1,"sugar":24}',
 ARRAY['cold brew coffee','caramel syrup','oat milk','vanilla'],
 ARRAY[]::text[]),

('a1000019-0000-0000-0000-000000000000', 'd400000a-0000-0000-0000-000000000000',
 'Truffle Parmesan Fries', 'Crispy fries, truffle oil, grated parmesan, fresh herbs',
 8.99, NULL, ARRAY['popular','truffle'], 420, 10, 4.7, 312, TRUE,
 '{"calories":420,"protein":8,"carbs":48,"fat":22,"fiber":4,"sugar":1}',
 ARRAY['potatoes','truffle oil','parmesan','herbs','sea salt'],
 ARRAY['dairy']),

('a1000020-0000-0000-0000-000000000000', 'd400000a-0000-0000-0000-000000000000',
 'Korean Fried Cauliflower', 'Crispy cauliflower, gochujang glaze, sesame seeds, scallions',
 9.49, NULL, ARRAY['vegan','spicy'], 280, 12, 4.6, 167, TRUE,
 '{"calories":280,"protein":6,"carbs":32,"fat":14,"fiber":4,"sugar":12}',
 ARRAY['cauliflower','gochujang','sesame seeds','scallions','rice flour'],
 ARRAY['soy','gluten']),

('a1000021-0000-0000-0000-000000000000', 'd400000b-0000-0000-0000-000000000000',
 'Avocado Benedict', 'Poached eggs, smashed avocado, hollandaise, sourdough, microgreens',
 14.99, NULL, ARRAY['breakfast','healthy'], 480, 15, 4.8, 198, TRUE,
 '{"calories":480,"protein":22,"carbs":32,"fat":30,"fiber":6,"sugar":3}',
 ARRAY['eggs','avocado','hollandaise','sourdough','microgreens'],
 ARRAY['gluten','dairy','eggs']),

('a1000022-0000-0000-0000-000000000000', 'd400000b-0000-0000-0000-000000000000',
 'Fluffy Pancake Stack', 'Three buttermilk pancakes, maple syrup, whipped butter, mixed berries',
 11.99, NULL, ARRAY['sweet','classic'], 620, 12, 4.6, 245, TRUE,
 '{"calories":620,"protein":12,"carbs":82,"fat":28,"fiber":3,"sugar":38}',
 ARRAY['buttermilk','flour','eggs','maple syrup','butter','mixed berries'],
 ARRAY['gluten','dairy','eggs']),

('a1000023-0000-0000-0000-000000000000', 'd400000c-0000-0000-0000-000000000000',
 'Poke Power Bowl', 'Ahi tuna, sushi rice, avocado, edamame, mango, ponzu, sesame',
 16.99, NULL, ARRAY['healthy','fresh'], 480, 10, 4.8, 213, TRUE,
 '{"calories":480,"protein":32,"carbs":52,"fat":16,"fiber":6,"sugar":8}',
 ARRAY['ahi tuna','sushi rice','avocado','edamame','mango','ponzu','sesame seeds','seaweed salad'],
 ARRAY['fish','soy']),

('a1000024-0000-0000-0000-000000000000', 'd400000c-0000-0000-0000-000000000000',
 'Korean BBQ Bowl', 'Bulgogi beef, kimchi, pickled daikon, jasmine rice, gochujang, fried egg',
 15.99, NULL, ARRAY['spicy','popular'], 580, 15, 4.7, 189, TRUE,
 '{"calories":580,"protein":35,"carbs":58,"fat":22,"fiber":4,"sugar":12}',
 ARRAY['bulgogi beef','kimchi','daikon','jasmine rice','gochujang','fried egg','scallions'],
 ARRAY['soy','eggs'])

ON CONFLICT (id) DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 4. MODIFIER GROUPS & OPTIONS
-- ────────────────────────────────────────────────────────────

INSERT INTO modifier_groups (id, name, min_select, max_select, required) VALUES
  ('b2000001-0000-0000-0000-000000000000', 'Protein Add-on', 0, 1, FALSE),
  ('b2000002-0000-0000-0000-000000000000', 'Spice Level',    1, 1, TRUE),
  ('b2000003-0000-0000-0000-000000000000', 'Drink Size',     1, 1, TRUE),
  ('b2000004-0000-0000-0000-000000000000', 'Extra Toppings',  0, 3, FALSE)
ON CONFLICT (id) DO NOTHING;

INSERT INTO modifier_options (id, group_id, name, price_delta) VALUES
  ('c3000001-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000', 'Grilled Chicken', 3.99),
  ('c3000002-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000', 'Salmon',          5.99),
  ('c3000003-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000', 'Tofu',            2.49),
  ('c3000004-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000', 'Mild',            0),
  ('c3000005-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000', 'Medium',          0),
  ('c3000006-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000', 'Hot',             0),
  ('c3000007-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000', 'Extra Hot',       0.50),
  ('c3000008-0000-0000-0000-000000000000', 'b2000003-0000-0000-0000-000000000000', 'Regular (16oz)',  0),
  ('c3000009-0000-0000-0000-000000000000', 'b2000003-0000-0000-0000-000000000000', 'Large (24oz)',    1.50),
  ('c300000a-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000', 'Avocado',         1.99),
  ('c300000b-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000', 'Bacon',           2.49),
  ('c300000c-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000', 'Extra Cheese',    1.49),
  ('c300000d-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000', 'Fried Egg',       1.99)
ON CONFLICT (id) DO NOTHING;

-- Link some items to modifier groups
INSERT INTO item_modifier_groups (item_id, group_id) VALUES
  ('a1000001-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000'), -- burger + toppings
  ('a1000002-0000-0000-0000-000000000000', 'b2000004-0000-0000-0000-000000000000'),
  ('a1000007-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000'), -- salad + protein
  ('a1000008-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000'),
  ('a1000011-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000'), -- chicken + spice
  ('a1000017-0000-0000-0000-000000000000', 'b2000003-0000-0000-0000-000000000000'), -- drink + size
  ('a1000018-0000-0000-0000-000000000000', 'b2000003-0000-0000-0000-000000000000'),
  ('a1000023-0000-0000-0000-000000000000', 'b2000001-0000-0000-0000-000000000000'), -- bowl + protein
  ('a1000024-0000-0000-0000-000000000000', 'b2000002-0000-0000-0000-000000000000')  -- bowl + spice
ON CONFLICT DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 5. DRIVER STATUS
-- ────────────────────────────────────────────────────────────

INSERT INTO driver_status (driver_id, is_online, current_order_id, last_seen) VALUES
  ('dddddddd-dddd-dddd-dddd-dddddddddddd', TRUE,  NULL, now()),
  ('eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee', TRUE,  NULL, now())
ON CONFLICT (driver_id) DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 6. SAVED ADDRESSES
-- ────────────────────────────────────────────────────────────

INSERT INTO addresses (user_id, label, street, city, state, zip, notes) VALUES
  ('11111111-1111-1111-1111-111111111111', 'Home',   '123 Oak Street',    'Springfield', 'IL', '62701', 'Ground floor, blue door'),
  ('11111111-1111-1111-1111-111111111111', 'Work',   '456 Tech Park Ave', 'Springfield', 'IL', '62702', 'Lobby entrance'),
  ('22222222-2222-2222-2222-222222222222', 'Home',   '789 Maple Drive',   'Springfield', 'IL', '62703', 'Apt 4B'),
  ('33333333-3333-3333-3333-333333333333', 'Home',   '321 Pine Road',     'Springfield', 'IL', '62704', NULL)
ON CONFLICT DO NOTHING;


-- ────────────────────────────────────────────────────────────
-- 7. SAMPLE ORDERS (various statuses — interconnected)
-- ────────────────────────────────────────────────────────────

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


-- Update driver_status with current order for James
UPDATE driver_status SET current_order_id = '00000004-0000-0000-0000-000000000000'
WHERE driver_id = 'dddddddd-dddd-dddd-dddd-dddddddddddd';

UPDATE driver_status SET current_order_id = '00000002-0000-0000-0000-000000000000'
WHERE driver_id = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';


-- ────────────────────────────────────────────────────────────
-- 8. ROW LEVEL SECURITY (basic policies)
-- ────────────────────────────────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_lines ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_status_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE menu_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_modifier_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE addresses ENABLE ROW LEVEL SECURITY;

-- Everyone can read profiles (needed for driver names, customer info)
DROP POLICY IF EXISTS "Profiles are viewable by everyone" ON profiles;
CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT USING (true);

-- Users can update their own profile
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE USING (auth.uid() = id);

-- Menu items are publicly readable
DROP POLICY IF EXISTS "Menu items are viewable by everyone" ON menu_items;
CREATE POLICY "Menu items are viewable by everyone"
  ON menu_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Categories are viewable by everyone" ON categories;
CREATE POLICY "Categories are viewable by everyone"
  ON categories FOR SELECT USING (true);

DROP POLICY IF EXISTS "Modifier groups are viewable by everyone" ON modifier_groups;
CREATE POLICY "Modifier groups are viewable by everyone"
  ON modifier_groups FOR SELECT USING (true);

DROP POLICY IF EXISTS "Modifier options are viewable by everyone" ON modifier_options;
CREATE POLICY "Modifier options are viewable by everyone"
  ON modifier_options FOR SELECT USING (true);

DROP POLICY IF EXISTS "Item modifier groups are viewable by everyone" ON item_modifier_groups;
CREATE POLICY "Item modifier groups are viewable by everyone"
  ON item_modifier_groups FOR SELECT USING (true);

-- Orders: customers see their own, admins and drivers see all
DROP POLICY IF EXISTS "Customers see own orders" ON orders;
CREATE POLICY "Customers see own orders"
  ON orders FOR SELECT USING (
    auth.uid() = user_id
    OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
  );

DROP POLICY IF EXISTS "Customers can create orders" ON orders;
CREATE POLICY "Customers can create orders"
  ON orders FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins and drivers can update orders" ON orders;
CREATE POLICY "Admins and drivers can update orders"
  ON orders FOR UPDATE USING (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR auth.uid() = user_id
  );

-- Order lines follow order access
DROP POLICY IF EXISTS "Order lines follow order access" ON order_lines;
CREATE POLICY "Order lines follow order access"
  ON order_lines FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_lines.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );

DROP POLICY IF EXISTS "Order lines insertable by order owner" ON order_lines;
CREATE POLICY "Order lines insertable by order owner"
  ON order_lines FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM orders WHERE orders.id = order_lines.order_id AND orders.user_id = auth.uid())
  );

-- Status events follow order access
DROP POLICY IF EXISTS "Status events viewable by relevant users" ON order_status_events;
CREATE POLICY "Status events viewable by relevant users"
  ON order_status_events FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id
      AND (orders.user_id = auth.uid()
           OR (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver'))
    )
  );

DROP POLICY IF EXISTS "Status events insertable by admin/driver" ON order_status_events;
CREATE POLICY "Status events insertable by admin/driver"
  ON order_status_events FOR INSERT WITH CHECK (
    (auth.jwt() -> 'user_metadata' ->> 'role') IN ('admin','driver')
    OR EXISTS (SELECT 1 FROM orders WHERE orders.id = order_status_events.order_id AND orders.user_id = auth.uid())
  );

-- Driver status
DROP POLICY IF EXISTS "Driver status viewable by everyone" ON driver_status;
CREATE POLICY "Driver status viewable by everyone"
  ON driver_status FOR SELECT USING (true);

DROP POLICY IF EXISTS "Drivers can update own status" ON driver_status;
CREATE POLICY "Drivers can update own status"
  ON driver_status FOR UPDATE USING (auth.uid() = driver_id);

DROP POLICY IF EXISTS "Drivers can insert own status" ON driver_status;
CREATE POLICY "Drivers can insert own status"
  ON driver_status FOR INSERT WITH CHECK (auth.uid() = driver_id);

-- Addresses
DROP POLICY IF EXISTS "Users see own addresses" ON addresses;
CREATE POLICY "Users see own addresses"
  ON addresses FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can manage own addresses" ON addresses;
CREATE POLICY "Users can manage own addresses"
  ON addresses FOR ALL USING (auth.uid() = user_id);


-- ────────────────────────────────────────────────────────────
-- Done! Your database is now seeded with:
--   • 3 customers, 1 admin, 2 drivers
--   • 12 categories, 24 menu items
--   • 4 modifier groups, 13 modifier options
--   • 6 orders in various statuses with timelines
--   • Driver statuses with active assignments
--   • Saved addresses for customers
--   • RLS policies for secure access
-- ────────────────────────────────────────────────────────────
