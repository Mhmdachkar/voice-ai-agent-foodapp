import { create } from 'zustand';
import type { KitchenQueueItem, KitchenStage } from '../models/KitchenQueue';

export interface KitchenQueueState {
  queue: KitchenQueueItem[];
  getPositionForOrder: (orderId: string) => KitchenQueueItem | null;
  updateQueue: (items: KitchenQueueItem[]) => void;
  advanceStage: (orderId: string) => void;
  addToQueue: (orderId: string, estimatedMinutes?: number) => void;
  removeFromQueue: (orderId: string) => void;
}

const STAGE_ORDER: KitchenStage[] = ['queued', 'preparing', 'cooking', 'plating', 'ready'];

export const useKitchenQueueStore = create<KitchenQueueState>((set, get) => ({
  queue: [],

  getPositionForOrder: (orderId: string) => {
    const { queue } = get();
    return queue.find(q => q.orderId === orderId) ?? null;
  },

  updateQueue: (items: KitchenQueueItem[]) => {
    set({ queue: items });
  },

  advanceStage: (orderId: string) => {
    set(state => {
      const idx = state.queue.findIndex(q => q.orderId === orderId);
      if (idx < 0) return state;
      const item = state.queue[idx];
      const stageIdx = STAGE_ORDER.indexOf(item.stage);
      if (stageIdx >= STAGE_ORDER.length - 1) return state;

      const newQueue = [...state.queue];
      const newStage = STAGE_ORDER[stageIdx + 1];
      const remainingMinutes = Math.max(1, Math.floor(item.estimatedMinutes * (1 - (stageIdx + 1) / STAGE_ORDER.length)));
      newQueue[idx] = {
        ...item,
        stage: newStage,
        estimatedMinutes: remainingMinutes,
        updatedAt: new Date().toISOString(),
      };
      return { queue: newQueue };
    });
  },

  addToQueue: (orderId: string, estimatedMinutes = 20) => {
    set(state => {
      if (state.queue.some(q => q.orderId === orderId)) return state;
      const position = state.queue.filter(q => q.stage !== 'ready').length + 1;
      const newItem: KitchenQueueItem = {
        orderId,
        position,
        stage: 'queued',
        estimatedMinutes,
        startedAt: null,
        updatedAt: new Date().toISOString(),
      };
      return { queue: [...state.queue, newItem] };
    });
  },

  removeFromQueue: (orderId: string) => {
    set(state => ({
      queue: state.queue.filter(q => q.orderId !== orderId),
    }));
  },
}));
