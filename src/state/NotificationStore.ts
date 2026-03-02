import { create } from 'zustand';
import type { AppNotification, NotificationType } from '../models/Notification';

export interface NotificationState {
  notifications: AppNotification[];
  unreadCount: () => number;
  addNotification: (title: string, body: string, type: NotificationType, orderId?: string) => void;
  markAsRead: (id: string) => void;
  markAllAsRead: () => void;
  clearAll: () => void;
}

const SEED_NOTIFICATIONS: AppNotification[] = [
  {
    id: 'n1',
    title: 'Welcome to SmartFood!',
    body: 'Your account is all set up. Explore our menu and place your first order!',
    type: 'system',
    isRead: false,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'n2',
    title: 'New: Truffle Carbonara',
    body: 'A rich and creamy pasta with truffle oil has been added to our Italian collection. Try it today!',
    type: 'promotion',
    isRead: false,
    createdAt: new Date(Date.now() - 4 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'n3',
    title: 'Order Delivered',
    body: 'Your order #00000001 has been delivered. Enjoy your meal! Leave feedback to earn loyalty points.',
    type: 'orderUpdate',
    isRead: true,
    createdAt: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
    orderId: '00000001-0000-0000-0000-000000000000',
  },
  {
    id: 'n4',
    title: 'Loyalty Reward Unlocked',
    body: 'You earned 50 points from your last order! You are 150 points away from Silver tier.',
    type: 'promotion',
    isRead: false,
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'n5',
    title: 'Weekend Special',
    body: 'Use code SAVE10 for 10% off your next order this weekend. Valid until Sunday!',
    type: 'promotion',
    isRead: false,
    createdAt: new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'n6',
    title: 'New Feature: Group Orders',
    body: 'Order together with friends! Create a group, share the link, and everyone picks their items.',
    type: 'system',
    isRead: false,
    createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'n7',
    title: 'Order Out for Delivery',
    body: 'Your order #00000004 is on its way! James Wilson is delivering. ETA 10 minutes.',
    type: 'orderUpdate',
    isRead: false,
    createdAt: new Date(Date.now() - 10 * 60 * 1000).toISOString(),
    orderId: '00000004-0000-0000-0000-000000000000',
  },
];

export const useNotificationStore = create<NotificationState>((set, get) => ({
  notifications: SEED_NOTIFICATIONS,

  unreadCount: () => get().notifications.filter(n => !n.isRead).length,

  addNotification: (title, body, type, orderId) =>
    set(state => ({
      notifications: [
        {
          id: `n-${Date.now()}`,
          title,
          body,
          type,
          isRead: false,
          createdAt: new Date().toISOString(),
          orderId: orderId ?? null,
        },
        ...state.notifications,
      ],
    })),

  markAsRead: (id) =>
    set(state => ({
      notifications: state.notifications.map(n =>
        n.id === id ? { ...n, isRead: true } : n,
      ),
    })),

  markAllAsRead: () =>
    set(state => ({
      notifications: state.notifications.map(n => ({ ...n, isRead: true })),
    })),

  clearAll: () => set({ notifications: [] }),
}));
