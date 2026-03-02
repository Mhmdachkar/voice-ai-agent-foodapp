export type FeedbackCategory = 'temperature' | 'packaging' | 'missing_items' | 'delivery_speed' | 'food_quality';

export interface OrderFeedback {
  id: string;
  orderId: string;
  userId: string;
  foodRating: number;
  driverRating: number;
  temperature: 'hot' | 'warm' | 'cold';
  packagingQuality: 'excellent' | 'good' | 'poor';
  missingItems: string[];
  photoUrl?: string | null;
  comment?: string | null;
  createdAt: string;
}

export type IncidentType = 'missing_item' | 'wrong_order' | 'cold_food' | 'late_delivery' | 'damaged' | 'other';
export type IncidentStatus = 'open' | 'in_review' | 'resolved';
export type ResolutionType = 'refund_item' | 'resend_item' | 'apply_credit' | 'full_refund' | 'none';

export interface OrderIncident {
  id: string;
  orderId: string;
  userId: string;
  type: IncidentType;
  description: string;
  photoUrl?: string | null;
  status: IncidentStatus;
  resolution?: ResolutionType | null;
  resolutionNote?: string | null;
  createdAt: string;
  resolvedAt?: string | null;
}

export const INCIDENT_LABELS: Record<IncidentType, string> = {
  missing_item: 'Missing Item',
  wrong_order: 'Wrong Order',
  cold_food: 'Cold Food',
  late_delivery: 'Late Delivery',
  damaged: 'Damaged Packaging',
  other: 'Other Issue',
};

export const RESOLUTION_LABELS: Record<ResolutionType, string> = {
  refund_item: 'Refund Item',
  resend_item: 'Re-send Item',
  apply_credit: 'Apply Store Credit',
  full_refund: 'Full Refund',
  none: 'No Action',
};
