export type SpiceLevel = 'none' | 'mild' | 'medium' | 'hot' | 'extraHot';

export interface FoodMemory {
  dietaryRestrictions: string[];
  dislikedIngredients: string[];
  spiceLevel: SpiceLevel;
  defaultDrink?: string | null;
  commonNotes?: string | null;
  preferredCuisines: string[];
}

export const defaultFoodMemory: FoodMemory = {
  dietaryRestrictions: [],
  dislikedIngredients: [],
  spiceLevel: 'medium',
  defaultDrink: null,
  commonNotes: null,
  preferredCuisines: [],
};

