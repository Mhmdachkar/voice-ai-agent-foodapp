import AsyncStorage from '@react-native-async-storage/async-storage';
import {
  defaultFoodMemory,
  type FoodMemory,
  type SpiceLevel,
} from '../models/FoodMemory';

const STORAGE_KEY = 'food_memory_v1';

export class FoodMemoryService {
  memory: FoodMemory = defaultFoodMemory;

  async load(): Promise<void> {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (!raw) {
        this.memory = defaultFoodMemory;
        return;
      }
      this.memory = { ...defaultFoodMemory, ...(JSON.parse(raw) as FoodMemory) };
    } catch {
      this.memory = defaultFoodMemory;
    }
  }

  private async save(): Promise<void> {
    try {
      await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(this.memory));
    } catch {
      // ignore for now
    }
  }

  async addDislikedIngredient(ingredient: string): Promise<void> {
    const normalized = ingredient.toLowerCase().trim();
    if (this.memory.dislikedIngredients.includes(normalized)) return;
    this.memory.dislikedIngredients.push(normalized);
    await this.save();
  }

  async removeDislikedIngredient(ingredient: string): Promise<void> {
    const normalized = ingredient.toLowerCase();
    this.memory.dislikedIngredients = this.memory.dislikedIngredients.filter(
      x => x !== normalized,
    );
    await this.save();
  }

  async setSpiceLevel(level: SpiceLevel): Promise<void> {
    this.memory.spiceLevel = level;
    await this.save();
  }

  async setDefaultDrink(drink: string | null): Promise<void> {
    this.memory.defaultDrink = drink ?? null;
    await this.save();
  }

  async setCommonNotes(notes: string | null): Promise<void> {
    this.memory.commonNotes = notes ?? null;
    await this.save();
  }

  contextString(): string {
    const parts: string[] = [];
    if (this.memory.dislikedIngredients.length > 0) {
      parts.push(
        `Dislikes: ${this.memory.dislikedIngredients.join(', ')}`,
      );
    }
    parts.push(`Spice level: ${this.memory.spiceLevel}`);
    if (this.memory.defaultDrink) {
      parts.push(`Default drink: ${this.memory.defaultDrink}`);
    }
    if (this.memory.commonNotes) {
      parts.push(`Usual notes: ${this.memory.commonNotes}`);
    }
    if (this.memory.preferredCuisines.length > 0) {
      parts.push(
        `Preferred cuisines: ${this.memory.preferredCuisines.join(', ')}`,
      );
    }
    return parts.length === 0
      ? 'No preferences saved yet.'
      : parts.join('\n');
  }
}

export const foodMemoryService = new FoodMemoryService();

