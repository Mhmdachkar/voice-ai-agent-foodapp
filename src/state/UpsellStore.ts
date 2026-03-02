import { create } from 'zustand';
import type { MenuItem } from '../models/MenuItem';
import type { CartItem } from '../models/Cart';

export interface UpsellSuggestion {
  item: MenuItem;
  reason: string;
  discount?: number;
}

export interface UpsellState {
  suggestions: UpsellSuggestion[];
  dismissed: string[];
  generateSuggestions: (cartItems: CartItem[], menuItems: MenuItem[], reorderHistory?: string[]) => void;
  dismiss: (itemId: string) => void;
  clearSuggestions: () => void;
}

export const useUpsellStore = create<UpsellState>((set, get) => ({
  suggestions: [],
  dismissed: [],

  generateSuggestions: (cartItems, menuItems, reorderHistory = []) => {
    const { dismissed } = get();
    const cartItemIds = new Set(cartItems.map(c => c.menuItem.id));
    const cartCategories = new Set(cartItems.map(c => c.menuItem.category));
    const cartTags = new Set(cartItems.flatMap(c => c.menuItem.tags.map(t => t.toLowerCase())));
    const subtotal = cartItems.reduce((s, c) => s + c.menuItem.price * c.quantity, 0);

    const suggestions: UpsellSuggestion[] = [];
    const used = new Set<string>();

    const addSuggestion = (item: MenuItem, reason: string, discount?: number) => {
      if (used.has(item.id) || dismissed.includes(item.id) || cartItemIds.has(item.id) || !item.isAvailable) return;
      used.add(item.id);
      suggestions.push({ item, reason, discount });
    };

    // Spicy food → cooling drink
    if (cartTags.has('spicy') || cartTags.has('hot')) {
      const coolDrink = menuItems.find(m =>
        m.category === 'drinks' &&
        m.isAvailable &&
        !cartItemIds.has(m.id) &&
        (m.tags.some(t => t.toLowerCase().includes('cool') || t.toLowerCase().includes('smooth') || t.toLowerCase().includes('lassi')))
      );
      if (coolDrink) addSuggestion(coolDrink, 'Perfect to cool down with your spicy order');
    }

    // No dessert + order > $25
    if (subtotal >= 25 && !cartCategories.has('desserts')) {
      const dessert = menuItems
        .filter(m => m.category === 'desserts' && m.isAvailable && !cartItemIds.has(m.id))
        .sort((a, b) => b.rating - a.rating)[0];
      if (dessert) addSuggestion(dessert, 'Add a sweet finish to your meal', 10);
    }

    // No drink in cart
    if (!cartCategories.has('drinks')) {
      const drink = menuItems
        .filter(m => m.category === 'drinks' && m.isAvailable && !cartItemIds.has(m.id))
        .sort((a, b) => b.rating - a.rating)[0];
      if (drink) addSuggestion(drink, 'Don\'t forget a drink!');
    }

    // Previously ordered items not in cart
    for (const histId of reorderHistory.slice(0, 3)) {
      const item = menuItems.find(m => m.id === histId);
      if (item) addSuggestion(item, 'You\'ve enjoyed this before — want it again?');
    }

    // Complementary sides
    if (!cartCategories.has('sides') && subtotal >= 15) {
      const side = menuItems
        .filter(m => m.category === 'sides' && m.isAvailable && !cartItemIds.has(m.id))
        .sort((a, b) => b.rating - a.rating)[0];
      if (side) addSuggestion(side, 'A tasty side to complete your meal');
    }

    set({ suggestions: suggestions.slice(0, 3) });
  },

  dismiss: (itemId) => {
    set(state => ({
      dismissed: [...state.dismissed, itemId],
      suggestions: state.suggestions.filter(s => s.item.id !== itemId),
    }));
  },

  clearSuggestions: () => set({ suggestions: [], dismissed: [] }),
}));
