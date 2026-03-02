export type VoiceCallState =
  | 'idle'
  | 'listening'
  | 'uploading'
  | 'transcribing'
  | 'confirmingTranscript'
  | 'thinking'
  | 'proposingActions'
  | 'speaking'
  | 'error';

export type MicMode = 'pushToTalk' | 'handsFree';

export type UserIntent =
  | 'order_intent'
  | 'menu_question'
  | 'recommendation_request'
  | 'cart_edit'
  | 'checkout_help'
  | 'smalltalk'
  | 'set_preference'
  | 'unknown';

export interface IntentClassification {
  intent: string;
  needsClarification: boolean;
  clarificationQuestion: string | null;
}

export type MessageRole = 'user' | 'assistant' | 'system';

export interface ProposedAction {
  id: string;
  type: ActionType;
  itemName: string;
  itemId?: string | null;
  quantity: number;
  price?: number | null;
  modifiers: string[];
  assumptions: string[];
  isConfirmed: boolean;
}

export type ActionType =
  | 'Add to Cart'
  | 'Remove from Cart'
  | 'Update Quantity'
  | 'Apply Preference';

export interface ConversationMessage {
  id: string;
  role: MessageRole;
  text: string;
  timestamp: string; // ISO8601
  proposedActions: ProposedAction[];
  isDecisionCard: boolean;
}

export interface AIActionLog {
  id: string;
  action: ProposedAction;
  timestamp: string; // ISO8601
  undone: boolean;
}

export interface ChatMessage {
  role: string;
  content: string;
}

export interface ChatCompletionRequest {
  model: string;
  messages: ChatMessage[];
  temperature: number;
  max_tokens: number;
}

export interface ChatChoice {
  message: ChatMessage;
}

export interface ChatCompletionResponse {
  choices: ChatChoice[];
}

export interface TranscriptionResponse {
  text: string;
  language?: string | null;
}

export interface QuickChip {
  id: string;
  label: string;
  icon: string;
  message: string;
}

