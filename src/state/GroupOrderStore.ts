import { create } from 'zustand';
import type { GroupOrder, GroupMember } from '../models/GroupOrder';
import type { CartItem } from '../models/Cart';
import { generateShareCode } from '../models/GroupOrder';

export interface GroupOrderState {
  activeGroup: GroupOrder | null;
  createGroup: (hostId: string, hostName: string) => string;
  joinGroup: (shareCode: string, memberId: string, memberName: string) => boolean;
  addItemForMember: (memberId: string, item: CartItem) => void;
  removeItemForMember: (memberId: string, itemId: string) => void;
  closeGroup: () => void;
  leaveGroup: (memberId: string) => void;
  getTotalForMember: (memberId: string) => number;
  getGroupTotal: () => number;
}

export const useGroupOrderStore = create<GroupOrderState>((set, get) => ({
  activeGroup: null,

  createGroup: (hostId, hostName) => {
    const code = generateShareCode();
    const group: GroupOrder = {
      id: `group-${Date.now()}`,
      hostId,
      hostName,
      members: [{ id: hostId, name: hostName, items: [], subtotal: 0 }],
      isOpen: true,
      shareCode: code,
      createdAt: new Date().toISOString(),
    };
    set({ activeGroup: group });
    return code;
  },

  joinGroup: (shareCode, memberId, memberName) => {
    const { activeGroup } = get();
    if (!activeGroup || activeGroup.shareCode !== shareCode || !activeGroup.isOpen) return false;
    if (activeGroup.members.some(m => m.id === memberId)) return true;
    const member: GroupMember = { id: memberId, name: memberName, items: [], subtotal: 0 };
    set({
      activeGroup: {
        ...activeGroup,
        members: [...activeGroup.members, member],
      },
    });
    return true;
  },

  addItemForMember: (memberId, item) => {
    set(state => {
      if (!state.activeGroup) return state;
      const members = state.activeGroup.members.map(m => {
        if (m.id !== memberId) return m;
        const items = [...m.items, item];
        const subtotal = items.reduce((s, i) => s + i.menuItem.price * i.quantity, 0);
        return { ...m, items, subtotal };
      });
      return { activeGroup: { ...state.activeGroup, members } };
    });
  },

  removeItemForMember: (memberId, itemId) => {
    set(state => {
      if (!state.activeGroup) return state;
      const members = state.activeGroup.members.map(m => {
        if (m.id !== memberId) return m;
        const items = m.items.filter(i => i.id !== itemId);
        const subtotal = items.reduce((s, i) => s + i.menuItem.price * i.quantity, 0);
        return { ...m, items, subtotal };
      });
      return { activeGroup: { ...state.activeGroup, members } };
    });
  },

  closeGroup: () => {
    set(state => {
      if (!state.activeGroup) return state;
      return { activeGroup: { ...state.activeGroup, isOpen: false } };
    });
  },

  leaveGroup: (memberId) => {
    set(state => {
      if (!state.activeGroup) return state;
      const members = state.activeGroup.members.filter(m => m.id !== memberId);
      if (members.length === 0) return { activeGroup: null };
      return { activeGroup: { ...state.activeGroup, members } };
    });
  },

  getTotalForMember: (memberId) => {
    const { activeGroup } = get();
    if (!activeGroup) return 0;
    return activeGroup.members.find(m => m.id === memberId)?.subtotal ?? 0;
  },

  getGroupTotal: () => {
    const { activeGroup } = get();
    if (!activeGroup) return 0;
    return activeGroup.members.reduce((s, m) => s + m.subtotal, 0);
  },
}));
