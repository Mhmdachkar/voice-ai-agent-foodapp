export type MenuCategory =
  | 'burgers'
  | 'pizza'
  | 'sushi'
  | 'salads'
  | 'pasta'
  | 'chicken'
  | 'seafood'
  | 'desserts'
  | 'drinks'
  | 'sides'
  | 'breakfast'
  | 'bowls';

export interface NutritionInfo {
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  sugar: number;
}

export interface ModifierOption {
  id: string;
  name: string;
  priceAdjustment: number;
}

export interface ModifierGroup {
  id: string;
  name: string;
  required: boolean;
  maxSelections: number;
  options: ModifierOption[];
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  imageUrl: string;
  category: MenuCategory;
  tags: string[];
  calories: number;
  prepTimeMinutes: number;
  rating: number;
  reviewCount: number;
  isAvailable: boolean;
  isLimitedTime: boolean;
  limitedTimeEnd?: string | null; // ISO8601
  modifierGroups: ModifierGroup[];
  nutritionInfo: NutritionInfo;
  ingredients: string[];
  allergens: string[];
}

