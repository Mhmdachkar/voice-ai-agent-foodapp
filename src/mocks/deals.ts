import type { MenuItem } from '../models/MenuItem';

export interface FlashDeal {
  id: string;
  food: MenuItem;
  originalPrice: number;
  dealPrice: number;
  discountPercent: number;
  endsAt: string;
  soldCount: number;
  totalAvailable: number;
}

export interface PopularNowItem {
  foodId: string;
  ordersInLastHour: number;
}

export const popularNowItems: PopularNowItem[] = [
  { foodId: '1', ordersInLastHour: 47 },
  { foodId: '2', ordersInLastHour: 38 },
  { foodId: '3', ordersInLastHour: 24 },
  { foodId: '5', ordersInLastHour: 31 },
  { foodId: '8', ordersInLastHour: 26 },
];

export const buildFlashDeals = (menuItems: MenuItem[]): FlashDeal[] => {
  const available = menuItems.filter(i => i.isAvailable);
  if (available.length === 0) return [];

  const now = Date.now();
  const dealConfigs = [
    { idx: 0, discount: 33, hours: 2.5, sold: 42, total: 60 },
    { idx: 1, discount: 25, hours: 1.75, sold: 28, total: 50 },
    { idx: 2, discount: 40, hours: 0.75, sold: 85, total: 100 },
    { idx: 3, discount: 20, hours: 3, sold: 15, total: 40 },
    { idx: 4, discount: 50, hours: 0.5, sold: 48, total: 55 },
  ];

  return dealConfigs
    .filter(c => c.idx < available.length)
    .map(c => {
      const food = available[c.idx];
      const dealPrice = +(food.price * (1 - c.discount / 100)).toFixed(2);
      return {
        id: `deal-${food.id}`,
        food,
        originalPrice: food.price,
        dealPrice,
        discountPercent: c.discount,
        endsAt: new Date(now + c.hours * 3600000).toISOString(),
        soldCount: c.sold,
        totalAvailable: c.total,
      };
    });
};
