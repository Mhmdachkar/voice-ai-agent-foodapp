import type { FoodMemory } from './FoodMemory';
import type { UserRole } from './UserRole';
import type { MenuItem } from './MenuItem';
import type { Order, OrderStatus, OrderTimelineEvent } from './Order';
import type { CartItem } from './Cart';
import type { DeliveryAddress, AppUser } from './AppUser';

// These types mirror the Supabase row structures and JSON snapshots
// defined in the Swift `SupabaseModels.swift` file and the SQL schema.

export interface DBProfile {
  id: string;
  role: string;
  full_name: string;
  email: string | null;
  phone: string | null;
  avatar_url: string | null;
  food_memory: FoodMemoryJSON | null;
  created_at: string | null;
}

export interface FoodMemoryJSON {
  disliked_ingredients?: string[] | null;
  spice_level?: string | null;
  default_drink?: string | null;
  common_notes?: string | null;
  preferred_cuisines?: string[] | null;
}

export interface DBCategory {
  id: string;
  name: string;
  icon: string | null;
  sort_order: number | null;
}

export interface DBMenuItem {
  id: string;
  category_id: string | null;
  name: string;
  description: string | null;
  price: number;
  image_url: string | null;
  tags: string[] | null;
  calories: number | null;
  prep_time_minutes: number | null;
  rating: number | null;
  review_count: number | null;
  is_available: boolean | null;
  is_limited_time: boolean | null;
  limited_time_end: string | null; // ISO8601
  nutrition_info: NutritionInfoJSON | null;
  ingredients: string[] | null;
  allergens: string[] | null;
}

export interface NutritionInfoJSON {
  calories?: number | null;
  protein?: number | null;
  carbs?: number | null;
  fat?: number | null;
  fiber?: number | null;
  sugar?: number | null;
}

export interface DBModifierGroup {
  id: string;
  name: string;
  min_select: number | null;
  max_select: number | null;
  required: boolean | null;
}

export interface DBModifierOption {
  id: string;
  group_id: string;
  name: string;
  price_delta: number | null;
  is_available: boolean | null;
}

export interface DBItemModifierGroup {
  item_id: string;
  group_id: string;
}

export interface AddressSnapshotJSON {
  street?: string | null;
  city?: string | null;
  state?: string | null;
  zip?: string | null;
  notes?: string | null;
}

export interface DBOrder {
  id: string;
  user_id: string;
  customer_name: string | null;
  delivery_method: string | null;
  status: string;
  payment_method: string | null;
  subtotal: number | null;
  delivery_fee: number | null;
  tax: number | null;
  discount: number | null;
  tip: number | null;
  total: number | null;
  address_snapshot: AddressSnapshotJSON | null;
  notes: string | null;
  promo_code: string | null;
  assigned_driver_id: string | null;
  driver_name: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export interface DBOrderLine {
  id: string;
  order_id: string;
  item_id: string | null;
  name_snapshot: string;
  image_url_snapshot: string | null;
  qty: number | null;
  unit_price: number | null;
  notes: string | null;
}

export interface DBOrderStatusEvent {
  id: string;
  order_id: string;
  status: string;
  note: string | null;
  changed_by: string | null;
  changed_by_role: string | null;
  created_at: string | null;
}

export interface DBDriverStatus {
  driver_id: string;
  is_online: boolean | null;
  current_order_id: string | null;
  last_seen: string | null;
}

export interface DBAddress {
  id: string;
  user_id: string | null;
  label: string | null;
  address_text: string | null;
  street: string | null;
  city: string | null;
  state: string | null;
  zip: string | null;
  notes: string | null;
}

export interface CreateOrderModifierJSON {
  name: string;
  price_delta: number;
}

export interface CreateOrderItemJSON {
  item_id: string;
  name: string;
  image_url: string;
  qty: number;
  notes: string;
  modifiers?: CreateOrderModifierJSON[] | null;
}

