export type NotificationType =
  | 'orderUpdate'
  | 'promotion'
  | 'reminder'
  | 'system';

export interface AppNotification {
  id: string;
  title: string;
  body: string;
  type: NotificationType;
  isRead: boolean;
  createdAt: string; // ISO8601
  orderId?: string | null;
}

