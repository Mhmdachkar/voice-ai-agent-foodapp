import type { CartItem } from './Cart';

export interface GroupMember {
  id: string;
  name: string;
  items: CartItem[];
  subtotal: number;
}

export interface GroupOrder {
  id: string;
  hostId: string;
  hostName: string;
  members: GroupMember[];
  isOpen: boolean;
  shareCode: string;
  createdAt: string;
}

export const generateShareCode = (): string => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 6; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  return code;
};
