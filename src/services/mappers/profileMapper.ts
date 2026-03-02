import type { DBProfile, FoodMemoryJSON } from '../../models/SupabaseModels';
import type { AppUser, DeliveryAddress } from '../../models/AppUser';
import {
  defaultFoodMemory,
  type FoodMemory,
  type SpiceLevel,
} from '../../models/FoodMemory';
import type { UserRole } from '../../models/UserRole';

export const mapFoodMemoryJSON = (src: FoodMemoryJSON | null): FoodMemory => {
  if (!src) return defaultFoodMemory;
  const spiceStr = src.spice_level ?? 'Medium';
  const normalizedSpice = spiceStr.toLowerCase();
  let spice: SpiceLevel = 'medium';
  if (normalizedSpice.includes('none')) spice = 'none';
  else if (normalizedSpice.includes('mild')) spice = 'mild';
  else if (normalizedSpice.includes('hot') && normalizedSpice.includes('extra'))
    spice = 'extraHot';
  else if (normalizedSpice.includes('hot')) spice = 'hot';

  return {
    dietaryRestrictions: (src as any).dietary_restrictions ?? [],
    dislikedIngredients: src.disliked_ingredients ?? [],
    spiceLevel: spice,
    defaultDrink: src.default_drink ?? null,
    commonNotes: src.common_notes ?? null,
    preferredCuisines: src.preferred_cuisines ?? [],
  };
};

export const mapProfileToAppUser = (profile: DBProfile): AppUser => {
  const role = (profile.role as UserRole) ?? 'customer';
  const memory = mapFoodMemoryJSON(profile.food_memory);
  return {
    id: profile.id,
    name: profile.full_name,
    email: profile.email ?? '',
    phone: profile.phone ?? '',
    role,
    avatarUrl: profile.avatar_url,
    address: null,
    foodMemory: memory,
    createdAt: profile.created_at ?? new Date().toISOString(),
  };
};

