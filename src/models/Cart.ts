import type { MenuItem } from './MenuItem';

export interface CartItem {
  id: string;
  menuItem: MenuItem;
  quantity: number;
  /**
   * Map of modifierGroupId -> array of optionIds
   */
  selectedModifiers: Record<string, string[]>;
  specialInstructions: string;
}

export type Mood =
  | 'comfort'
  | 'light'
  | 'energizing'
  | 'spicy'
  | 'healthy'
  | 'indulgent';

