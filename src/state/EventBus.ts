import type { OrderStatus } from '../models/Order';

export type AppEvent =
  | { type: 'orderPlaced'; orderId: string }
  | { type: 'orderStatusChanged'; orderId: string; status: OrderStatus }
  | { type: 'driverAssigned'; orderId: string; driverId: string }
  | { type: 'cartUpdated' }
  | { type: 'notificationReceived' };

/**
 * Simple in-memory event bus similar to the Swift `EventBus`.
 * Consumers can subscribe via `subscribe` and unsubscribe when done.
 */
export class EventBus {
  private static _instance: EventBus | null = null;
  static get instance(): EventBus {
    if (!this._instance) this._instance = new EventBus();
    return this._instance;
  }

  private listeners = new Set<(event: AppEvent) => void>();
  lastEvent: AppEvent | null = null;
  eventCount = 0;

  private constructor() {}

  publish(event: AppEvent): void {
    this.lastEvent = event;
    this.eventCount += 1;
    for (const listener of this.listeners) {
      listener(event);
    }
  }

  subscribe(handler: (event: AppEvent) => void): () => void {
    this.listeners.add(handler);
    return () => {
      this.listeners.delete(handler);
    };
  }
}

export const eventBus = EventBus.instance;

