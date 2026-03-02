import type { CartItem } from './Cart';
import type { DeliveryAddress } from './AppUser';

export type OrderStatus =
  | 'PLACED'
  | 'ACCEPTED'
  | 'PREPARING'
  | 'READY'
  | 'OUT_FOR_DELIVERY'
  | 'DELIVERED'
  | 'CANCELED';

export interface OrderTimelineEvent {
  id: string;
  status: OrderStatus;
  timestamp: string; // ISO8601
  note?: string | null;
}

export interface Order {
  id: string;
  customerId: string;
  customerName: string;
  items: CartItem[];
  status: OrderStatus;
  timeline: OrderTimelineEvent[];
  subtotal: number;
  tax: number;
  deliveryFee: number;
  tip: number;
  total: number;
  deliveryAddress: DeliveryAddress;
  deliveryNotes: string;
  promoCode?: string | null;
  promoDiscount: number;
  driverId?: string | null;
  driverName?: string | null;
  estimatedDeliveryTime?: string | null;
  scheduledFor?: string | null;
  createdAt: string; // ISO8601
}

