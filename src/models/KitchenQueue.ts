export type KitchenStage = 'queued' | 'preparing' | 'cooking' | 'plating' | 'ready';

export interface KitchenQueueItem {
  orderId: string;
  position: number;
  stage: KitchenStage;
  estimatedMinutes: number;
  startedAt: string | null;
  updatedAt: string;
}

export const STAGE_LABELS: Record<KitchenStage, string> = {
  queued: 'In Queue',
  preparing: 'Prep',
  cooking: 'Cooking',
  plating: 'Plating',
  ready: 'Ready',
};

export const STAGE_ICONS: Record<KitchenStage, string> = {
  queued: '\u23F3',
  preparing: '\uD83E\uDD52',
  cooking: '\uD83D\uDD25',
  plating: '\uD83C\uDF7D\uFE0F',
  ready: '\u2705',
};

export const STAGE_PROGRESS: Record<KitchenStage, number> = {
  queued: 0.1,
  preparing: 0.3,
  cooking: 0.6,
  plating: 0.85,
  ready: 1.0,
};
