import { create } from 'zustand';
import type {
  LoyaltyProfile,
  LoyaltyTier,
} from '../models/Loyalty';
import {
  defaultLoyaltyProfile,
  getTierForPoints,
  pointsToNextTier,
  POINTS_PER_DOLLAR,
  STREAK_FREE_DELIVERY_WEEKS,
  TIER_THRESHOLDS,
} from '../models/Loyalty';
import AsyncStorage from '@react-native-async-storage/async-storage';

const STORAGE_KEY = '@smartfood_loyalty';

export interface LoyaltyState {
  profile: LoyaltyProfile;
  isLoaded: boolean;
  load: () => Promise<void>;
  addPoints: (orderTotal: number) => void;
  recordOrder: () => void;
  redeemPoints: (amount: number) => boolean;
  getProgress: () => { percent: number; nextTier: LoyaltyTier | null; needed: number };
}

export const useLoyaltyStore = create<LoyaltyState>((set, get) => ({
  profile: defaultLoyaltyProfile,
  isLoaded: false,

  load: async () => {
    try {
      const raw = await AsyncStorage.getItem(STORAGE_KEY);
      if (raw) {
        const parsed = JSON.parse(raw) as LoyaltyProfile;
        set({ profile: parsed, isLoaded: true });
      } else {
        set({ isLoaded: true });
      }
    } catch {
      set({ isLoaded: true });
    }
  },

  addPoints: (orderTotal: number) => {
    const { profile } = get();
    const tierMultiplier = profile.tier === 'gold' ? 2 : profile.tier === 'silver' ? 1.5 : 1;
    const earned = Math.floor(orderTotal * POINTS_PER_DOLLAR * tierMultiplier);
    const newPoints = profile.points + earned;
    const newTier = getTierForPoints(newPoints);
    const updated: LoyaltyProfile = {
      ...profile,
      points: newPoints,
      tier: newTier,
    };
    set({ profile: updated });
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
  },

  recordOrder: () => {
    const { profile } = get();
    const now = new Date();
    const lastDate = profile.lastOrderDate ? new Date(profile.lastOrderDate) : null;
    const daysSinceLast = lastDate
      ? Math.floor((now.getTime() - lastDate.getTime()) / (1000 * 60 * 60 * 24))
      : 999;

    const streakContinued = daysSinceLast <= 10;
    const newStreak = streakContinued ? profile.currentStreak + 1 : 1;
    const freeDelivery =
      newStreak >= STREAK_FREE_DELIVERY_WEEKS || profile.tier === 'gold';

    const updated: LoyaltyProfile = {
      ...profile,
      totalOrders: profile.totalOrders + 1,
      currentStreak: newStreak,
      longestStreak: Math.max(profile.longestStreak, newStreak),
      freeDeliveryEarned: freeDelivery,
      lastOrderDate: now.toISOString(),
    };
    set({ profile: updated });
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
  },

  redeemPoints: (amount: number) => {
    const { profile } = get();
    if (profile.points < amount) return false;
    const updated: LoyaltyProfile = {
      ...profile,
      points: profile.points - amount,
      tier: getTierForPoints(profile.points - amount),
    };
    set({ profile: updated });
    AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(updated)).catch(() => {});
    return true;
  },

  getProgress: () => {
    const { profile } = get();
    const { nextTier, needed } = pointsToNextTier(profile.points);
    if (!nextTier) return { percent: 1, nextTier: null, needed: 0 };
    const currentThreshold =
      TIER_THRESHOLDS[profile.tier];
    const nextThreshold = TIER_THRESHOLDS[nextTier];
    const range = nextThreshold - currentThreshold;
    const progress = profile.points - currentThreshold;
    return {
      percent: Math.min(1, Math.max(0, progress / range)),
      nextTier,
      needed,
    };
  },
}));
