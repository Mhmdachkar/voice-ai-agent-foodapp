import type { UserRole } from './UserRole';
import type { FoodMemory } from './FoodMemory';

export interface DeliveryAddress {
  street: string;
  city: string;
  state: string;
  zip: string;
  notes: string;
}

export const emptyDeliveryAddress: DeliveryAddress = {
  street: '',
  city: '',
  state: '',
  zip: '',
  notes: '',
};

export interface AppUser {
  id: string;
  name: string;
  email: string;
  phone: string;
  role: UserRole;
  avatarUrl?: string | null;
  address?: DeliveryAddress | null;
  foodMemory: FoodMemory;
  createdAt: string; // ISO8601
}

