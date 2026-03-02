import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';
import type { Order } from '../models/Order';
import type { MenuItem } from '../models/MenuItem';

const STORAGE_KEY = '@smartfood_reorder';

export interface ReorderPattern {
  itemId: string;
  itemName: string;
  count: number;
  lastOrdered: string;
  dayOfWeek: number;
  hourOfDay: number;
  avgQuantity: number;
  commonSides: string[];
}

export interface ReorderSuggestion {
  item: MenuItem;
  reason: string;
  adjustedQuantity: number;
  suggestedSides: MenuItem[];
}

export interface SmartReorderState {
  patterns: ReorderPattern[];
  isLoaded: boolean;
  load: () => Promise<void>;
  analyzeOrders: (orders: Order[]) => void;
  getSuggestions: (menuItems: MenuItem[], now?: Date) => ReorderSuggestion[];
}

export const useSmartReorderStore = create<SmartReorderState>((set, get) => ({
  patterns: [],
  isLoaded: false,

  load: async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (raw) set({ patterns: JSON.parse(raw), isLoaded: true });
      else set({ isLoaded: true });
    } catch {
      set({ isLoaded: true });
    }
  },

  analyzeOrders: (orders: Order[]) => {
    const itemMap: Record<string, {
      count: number;
      name: string;
      lastOrdered: string;
      days: number[];
      hours: number[];
      quantities: number[];
      coItems: string[];
    }> = {};

    for (const order of orders) {
      const d = new Date(order.createdAt);
      const itemIds = order.items.map(i => i.menuItem.id);

      for (const ci of order.items) {
        const id = ci.menuItem.id;
        if (!itemMap[id]) {
          itemMap[id] = {
            count: 0,
            name: ci.menuItem.name,
            lastOrdered: order.createdAt,
            days: [],
            hours: [],
            quantities: [],
            coItems: [],
          };
        }
        const entry = itemMap[id];
        entry.count++;
        entry.days.push(d.getDay());
        entry.hours.push(d.getHours());
        entry.quantities.push(ci.quantity);
        if (entry.lastOrdered < order.createdAt) entry.lastOrdered = order.createdAt;
        entry.coItems.push(...itemIds.filter(x => x !== id));
      }
    }

    const patterns: ReorderPattern[] = Object.entries(itemMap)
      .filter(([, v]) => v.count >= 2)
      .map(([id, v]) => {
        const modeDay = mode(v.days);
        const modeHour = mode(v.hours);
        const avgQty = v.quantities.reduce((a, b) => a + b, 0) / v.quantities.length;
        const sideFreq: Record<string, number> = {};
        for (const s of v.coItems) {
          sideFreq[s] = (sideFreq[s] || 0) + 1;
        }
        const commonSides = Object.entries(sideFreq)
          .sort((a, b) => b[1] - a[1])
          .slice(0, 3)
          .map(([k]) => k);

        return {
          itemId: id,
          itemName: v.name,
          count: v.count,
          lastOrdered: v.lastOrdered,
          dayOfWeek: modeDay,
          hourOfDay: modeHour,
          avgQuantity: Math.round(avgQty),
          commonSides,
        };
      })
      .sort((a, b) => b.count - a.count);

    set({ patterns });
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(patterns)).catch(() => {});
  },

  getSuggestions: (menuItems: MenuItem[], now = new Date()) => {
    const { patterns } = get();
    const day = now.getDay();
    const hour = now.getHours();
    const isWeekend = day === 0 || day === 6;
    const isLunch = hour >= 11 && hour <= 14;

    const menuMap: Record<string, MenuItem> = {};
    for (const m of menuItems) menuMap[m.id] = m;

    return patterns
      .slice(0, 5)
      .map(p => {
        const item = menuMap[p.itemId];
        if (!item || !item.isAvailable) return null;

        let reason = `You've ordered this ${p.count} times`;
        const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
        if (p.dayOfWeek === day) {
          reason = `You usually order this on ${dayNames[day]}s`;
        }

        let adjustedQty = p.avgQuantity;
        if (isWeekend && p.avgQuantity > 1) adjustedQty = Math.ceil(p.avgQuantity * 1.2);
        if (isLunch) adjustedQty = Math.max(1, Math.floor(p.avgQuantity * 0.8));

        const suggestedSides = p.commonSides
          .map(id => menuMap[id])
          .filter((m): m is MenuItem => !!m && m.isAvailable)
          .slice(0, 2);

        return {
          item,
          reason,
          adjustedQuantity: Math.max(1, adjustedQty),
          suggestedSides,
        } as ReorderSuggestion;
      })
      .filter((s): s is ReorderSuggestion => s !== null);
  },
}));

function mode(arr: number[]): number {
  const freq: Record<number, number> = {};
  let maxCount = 0;
  let maxVal = arr[0] ?? 0;
  for (const v of arr) {
    freq[v] = (freq[v] || 0) + 1;
    if (freq[v] > maxCount) {
      maxCount = freq[v];
      maxVal = v;
    }
  }
  return maxVal;
}
