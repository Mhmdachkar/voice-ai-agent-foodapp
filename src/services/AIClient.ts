import type { MenuItem } from '../models/MenuItem';
import type { Mood } from '../models/Cart';

export type NutritionFilter =
  | 'highProtein'
  | 'lowCalorie'
  | 'lowSugar'
  | 'vegetarian';

export interface AIOrderResponse {
  message: string;
  suggestedItems: MenuItem[];
}

/**
 * Heuristic, local-only recommendation engine.
 * Mirrors the Swift `AIClient` behavior without using any LLM.
 */
export class AIClient {
  isProcessing = false;
  lastResponse = '';

  async processVoiceCommand(
    transcript: string,
    menuItems: MenuItem[],
  ): Promise<AIOrderResponse> {
    this.isProcessing = true;
    try {
      // Simulate a small thinking delay like the Swift version.
      await new Promise(resolve => setTimeout(resolve, 1500));

      const lowered = transcript.toLowerCase();
      let suggestedItems: MenuItem[] = [];

      for (const item of menuItems) {
        if (
          lowered.includes(item.name.toLowerCase()) ||
          lowered.includes(item.category.toLowerCase())
        ) {
          suggestedItems.push(item);
        }
      }

      if (suggestedItems.length === 0) {
        if (lowered.includes('burger') || lowered.includes('hungry')) {
          suggestedItems = menuItems
            .filter(m => m.category === 'burgers')
            .slice(0, 2);
        } else if (
          lowered.includes('healthy') ||
          lowered.includes('light') ||
          lowered.includes('salad')
        ) {
          suggestedItems = menuItems
            .filter(m => m.tags.includes('Healthy'))
            .slice(0, 3);
        } else if (lowered.includes('spicy')) {
          suggestedItems = menuItems
            .filter(
              m =>
                m.tags.includes('Spicy') || m.category === 'sushi',
            )
            .slice(0, 2);
        } else if (
          lowered.includes('comfort') ||
          lowered.includes('warm')
        ) {
          suggestedItems = menuItems
            .filter(
              m =>
                m.tags.includes('Comfort') ||
                m.category === 'pasta',
            )
            .slice(0, 2);
        } else {
          suggestedItems = [...menuItems]
            .sort((a, b) => b.rating - a.rating)
            .slice(0, 3);
        }
      }

      const itemNames = suggestedItems.map(i => i.name).join(', ');
      const message =
        suggestedItems.length > 0
          ? `Based on your request, I suggest: ${itemNames}. Shall I add these to your cart?`
          : `I did not find anything that matches your request.`;

      this.lastResponse = message;
      return { message, suggestedItems };
    } finally {
      this.isProcessing = false;
    }
  }

  getMoodSuggestions(mood: Mood, menuItems: MenuItem[]): MenuItem[] {
    switch (mood) {
      case 'comfort':
        return menuItems.filter(
          m =>
            m.category === 'burgers' ||
            m.category === 'pasta' ||
            m.tags.includes('Comfort'),
        );
      case 'light':
        return menuItems.filter(
          m => m.calories < 500 || m.category === 'salads',
        );
      case 'energizing':
        return menuItems.filter(
          m => m.tags.includes('Energizing') || m.category === 'bowls',
        );
      case 'spicy':
        return menuItems.filter(
          m =>
            m.tags.includes('Spicy') || m.category === 'sushi',
        );
      case 'healthy':
        return menuItems.filter(
          m =>
            m.tags.includes('Healthy') ||
            m.nutritionInfo.protein > 25,
        );
      case 'indulgent':
        return menuItems.filter(
          m =>
            m.tags.includes('Indulgent') ||
            m.category === 'desserts',
        );
      default:
        return [];
    }
  }

  getBudgetSuggestions(maxBudget: number, menuItems: MenuItem[]): MenuItem[] {
    return menuItems
      .filter(m => m.price <= maxBudget)
      .sort((a, b) => b.rating - a.rating);
  }

  getNutritionSuggestions(
    filter: NutritionFilter,
    menuItems: MenuItem[],
  ): MenuItem[] {
    switch (filter) {
      case 'highProtein':
        return menuItems
          .filter(m => m.nutritionInfo.protein >= 25)
          .sort(
            (a, b) =>
              b.nutritionInfo.protein - a.nutritionInfo.protein,
          );
      case 'lowCalorie':
        return menuItems
          .filter(m => m.calories <= 500)
          .sort((a, b) => a.calories - b.calories);
      case 'lowSugar':
        return menuItems
          .filter(m => m.nutritionInfo.sugar <= 10)
          .sort((a, b) => a.nutritionInfo.sugar - b.nutritionInfo.sugar);
      case 'vegetarian':
        return menuItems.filter(m => {
          const ingredients = m.ingredients;
          const animalProteins = [
            'beef',
            'chicken',
            'shrimp',
            'salmon',
            'tuna',
          ];
          return !ingredients.some(ing =>
            animalProteins.includes(ing.toLowerCase()),
          );
        });
      default:
        return [];
    }
  }
}

export const aiClient = new AIClient();

