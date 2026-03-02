import { create } from 'zustand';
import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = '@smartfood_schedules';

export interface ScheduledOrder {
  id: string;
  label: string;
  itemIds: string[];
  deliveryTime: string;
  recurrence: 'once' | 'daily' | 'weekly';
  dayOfWeek?: number;
  isActive: boolean;
  createdAt: string;
}

export interface ScheduleOrderState {
  schedules: ScheduledOrder[];
  isLoaded: boolean;
  load: () => Promise<void>;
  addSchedule: (schedule: Omit<ScheduledOrder, 'id' | 'createdAt' | 'isActive'>) => void;
  removeSchedule: (id: string) => void;
  toggleSchedule: (id: string) => void;
  getUpcoming: () => ScheduledOrder[];
}

export const useScheduleOrderStore = create<ScheduleOrderState>((set, get) => ({
  schedules: [],
  isLoaded: false,

  load: async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (raw) set({ schedules: JSON.parse(raw), isLoaded: true });
      else set({ isLoaded: true });
    } catch {
      set({ isLoaded: true });
    }
  },

  addSchedule: (schedule) => {
    const entry: ScheduledOrder = {
      ...schedule,
      id: `sched-${Date.now()}`,
      isActive: true,
      createdAt: new Date().toISOString(),
    };
    set(state => {
      const updated = [...state.schedules, entry];
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
      return { schedules: updated };
    });
  },

  removeSchedule: (id) => {
    set(state => {
      const updated = state.schedules.filter(s => s.id !== id);
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
      return { schedules: updated };
    });
  },

  toggleSchedule: (id) => {
    set(state => {
      const updated = state.schedules.map(s =>
        s.id === id ? { ...s, isActive: !s.isActive } : s,
      );
      AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
      return { schedules: updated };
    });
  },

  getUpcoming: () => {
    return get().schedules.filter(s => s.isActive);
  },
}));
