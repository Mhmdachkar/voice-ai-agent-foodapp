export type LoyaltyTier = 'bronze' | 'silver' | 'gold';

export interface LoyaltyProfile {
  points: number;
  tier: LoyaltyTier;
  totalOrders: number;
  currentStreak: number;
  longestStreak: number;
  freeDeliveryEarned: boolean;
  lastOrderDate: string | null;
}

export const TIER_THRESHOLDS: Record<LoyaltyTier, number> = {
  bronze: 0,
  silver: 500,
  gold: 1500,
};

export const TIER_LABELS: Record<LoyaltyTier, string> = {
  bronze: 'Bronze',
  silver: 'Silver',
  gold: 'Gold',
};

export const TIER_COLORS: Record<LoyaltyTier, string> = {
  bronze: '#CD7F32',
  silver: '#C0C0C0',
  gold: '#FFD700',
};

export const TIER_PERKS: Record<LoyaltyTier, string[]> = {
  bronze: ['Earn 1 point per $1 spent', 'Birthday reward'],
  silver: ['Earn 1.5x points', 'Free delivery on orders $25+', 'Early access to new items'],
  gold: ['Earn 2x points', 'Free delivery always', 'Priority kitchen queue', 'Exclusive menu items'],
};

export const POINTS_PER_DOLLAR = 10;
export const STREAK_FREE_DELIVERY_WEEKS = 4;

export const defaultLoyaltyProfile: LoyaltyProfile = {
  points: 0,
  tier: 'bronze',
  totalOrders: 0,
  currentStreak: 0,
  longestStreak: 0,
  freeDeliveryEarned: false,
  lastOrderDate: null,
};

export const getTierForPoints = (points: number): LoyaltyTier => {
  if (points >= TIER_THRESHOLDS.gold) return 'gold';
  if (points >= TIER_THRESHOLDS.silver) return 'silver';
  return 'bronze';
};

export const pointsToNextTier = (points: number): { nextTier: LoyaltyTier | null; needed: number } => {
  const current = getTierForPoints(points);
  if (current === 'gold') return { nextTier: null, needed: 0 };
  const next = current === 'bronze' ? 'silver' : 'gold';
  return { nextTier: next, needed: TIER_THRESHOLDS[next] - points };
};
