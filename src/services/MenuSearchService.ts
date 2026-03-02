import type { MenuItem } from '../models/MenuItem';

export interface MenuIndexEntry {
  id: string;
  name: string;
  category: string;
  tags: string[];
  price: number;
  calories: number;
  protein: number;
  prepTime: number;
  isAvailable: boolean;
  ingredients: string[];
  keywords: string[];
}

export interface MenuSearchFilters {
  maxPrice?: number;
  maxCalories?: number;
  minProtein?: number;
  category?: string;
  tags?: string[];
  excludeIngredients?: string[];
}

export class MenuSearchService {
  private index: MenuIndexEntry[] = [];

  buildIndex(items: MenuItem[]): void {
    this.index = items.map(item => {
      const keywords: string[] = [];
      keywords.push(item.name.toLowerCase());
      keywords.push(item.category.toLowerCase());
      keywords.push(...item.tags.map(t => t.toLowerCase()));
      keywords.push(...item.ingredients.map(i => i.toLowerCase()));

      return {
        id: item.id,
        name: item.name,
        category: item.category,
        tags: item.tags,
        price: item.price,
        calories: item.calories,
        protein: item.nutritionInfo.protein,
        prepTime: item.prepTimeMinutes,
        isAvailable: item.isAvailable,
        ingredients: item.ingredients.map(i => i.toLowerCase()),
        keywords,
      };
    });
  }

  search(
    query: string,
    filters: MenuSearchFilters = {},
    maxResults = 10,
  ): MenuIndexEntry[] {
    const terms = query
      .toLowerCase()
      .split(/\s+/)
      .filter(Boolean);

    let candidates = this.index.filter(e => e.isAvailable);

    if (filters.maxPrice != null) {
      candidates = candidates.filter(e => e.price <= filters.maxPrice!);
    }
    if (filters.maxCalories != null) {
      candidates = candidates.filter(e => e.calories <= filters.maxCalories!);
    }
    if (filters.minProtein != null) {
      candidates = candidates.filter(e => e.protein >= filters.minProtein!);
    }
    if (filters.category) {
      const cat = filters.category.toLowerCase();
      candidates = candidates.filter(
        e => e.category.toLowerCase() === cat,
      );
    }
    if (filters.tags && filters.tags.length > 0) {
      const tagsLower = filters.tags.map(t => t.toLowerCase());
      candidates = candidates.filter(entry =>
        tagsLower.some(t =>
          entry.tags.some(et => et.toLowerCase() === t),
        ),
      );
    }
    if (filters.excludeIngredients && filters.excludeIngredients.length > 0) {
      const excludes = filters.excludeIngredients.map(e => e.toLowerCase());
      candidates = candidates.filter(entry =>
        excludes.every(ex => !entry.ingredients.includes(ex)),
      );
    }

    if (terms.length === 0) {
      return candidates.slice(0, maxResults);
    }

    const scored = candidates
      .map(entry => {
        let score = 0;
        for (const term of terms) {
          if (entry.name.toLowerCase().includes(term)) score += 10;
          if (entry.category.toLowerCase().includes(term)) score += 5;
          for (const kw of entry.keywords) {
            if (kw.includes(term)) score += 3;
          }
          if (
            term.includes('cheap') ||
            term.includes('budget') ||
            term.includes('affordable')
          ) {
            if (entry.price < 15) score += 5;
          }
          if (
            term.includes('healthy') ||
            term.includes('light') ||
            term.includes('diet')
          ) {
            if (entry.calories < 500) score += 5;
          }
          if (
            term.includes('protein') ||
            term.includes('muscle') ||
            term.includes('gym')
          ) {
            if (entry.protein > 25) score += 5;
          }
          if (
            term.includes('quick') ||
            term.includes('fast')
          ) {
            if (entry.prepTime < 10) score += 5;
          }
          if (term.includes('spicy') || term.includes('hot')) {
            if (
              entry.tags.some(t => t.toLowerCase() === 'spicy')
            ) {
              score += 5;
            }
          }
          if (
            term.includes('comfort') ||
            term.includes('hearty') ||
            term.includes('warm')
          ) {
            if (
              entry.tags.some(t => t.toLowerCase() === 'comfort')
            ) {
              score += 5;
            }
          }
        }
        return { entry, score };
      })
      .filter(pair => pair.score > 0)
      .sort((a, b) => b.score - a.score);

    return scored.slice(0, maxResults).map(pair => pair.entry);
  }

  findItemByName(name: string): MenuIndexEntry | undefined {
    const lowered = name.toLowerCase();
    return (
      this.index.find(e => e.name.toLowerCase() === lowered) ??
      this.index.find(
        e =>
          e.name.toLowerCase().includes(lowered) ||
          lowered.includes(e.name.toLowerCase()),
      )
    );
  }

  findItemById(id: string): MenuIndexEntry | undefined {
    return this.index.find(e => e.id === id);
  }

  contextString(entries: MenuIndexEntry[]): string {
    if (entries.length === 0) return 'No matching items found.';
    return entries
      .map(entry => {
        return `- ${entry.name} (${entry.category}) $${entry.price.toFixed(
          2,
        )}, ${entry.calories}cal, ${entry.protein}g protein, ~${entry.prepTime}min, tags: ${entry.tags.join(
          ', ',
        )}, ingredients: ${entry.ingredients.join(', ')}`;
      })
      .join('\n');
  }

  /**
   * Build a rich context string from full MenuItem objects (includes descriptions,
   * allergens, modifiers, and availability info from the Supabase database).
   */
  richContextString(items: MenuItem[]): string {
    if (items.length === 0) return 'No menu items available.';
    const available = items.filter(i => i.isAvailable);
    const unavailable = items.filter(i => !i.isAvailable);

    let ctx = available
      .map(item => {
        let line = `- ${item.name} (${item.category}) $${item.price.toFixed(2)}`;
        if (item.description) line += ` — ${item.description}`;
        const ni = item.nutritionInfo;
        line += ` | ${item.calories}cal, ${ni.protein}g protein, ${ni.carbs}g carbs, ${ni.fat}g fat`;
        if (ni.fiber > 0) line += `, ${ni.fiber}g fiber`;
        line += ` | ~${item.prepTimeMinutes}min`;
        if (item.rating) line += `, ${item.rating}★ (${item.reviewCount} reviews)`;
        if (item.tags.length > 0) line += ` | tags: ${item.tags.join(', ')}`;
        if (item.allergens.length > 0) line += ` | allergens: ${item.allergens.join(', ')}`;
        if (item.ingredients.length > 0) line += ` | ingredients: ${item.ingredients.join(', ')}`;
        if (item.modifierGroups.length > 0) {
          const mods = item.modifierGroups.map(g => {
            const opts = g.options.map(o =>
              o.priceAdjustment ? `${o.name} (+$${o.priceAdjustment.toFixed(2)})` : o.name
            ).join(', ');
            return `${g.name}${g.required ? '*' : ''}: ${opts}`;
          }).join('; ');
          line += ` | customize: ${mods}`;
        }
        if (item.isLimitedTime) {
          line += ' [LIMITED TIME';
          if (item.limitedTimeEnd) {
            line += ` until ${new Date(item.limitedTimeEnd).toLocaleDateString()}`;
          }
          line += ']';
        }
        return line;
      })
      .join('\n');

    if (unavailable.length > 0) {
      ctx += `\n\nCurrently unavailable: ${unavailable.map(i => i.name).join(', ')}`;
    }

    return ctx;
  }

  fullContextString(limit = 50): string {
    const available = this.index.filter(e => e.isAvailable);
    return this.contextString(available.slice(0, limit));
  }
}

export const menuSearchService = new MenuSearchService();

