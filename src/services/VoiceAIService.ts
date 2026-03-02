import { Config } from '../config/Config';
import type {
  ChatCompletionRequest,
  ChatCompletionResponse,
  ChatMessage,
} from '../models/VoiceCallTypes';

const REQUEST_TIMEOUT_MS = 30000;
const MAX_RETRIES = 2;
const RETRY_DELAY_MS = 800;

const PRIMARY_MODEL = 'openai-large';
const FALLBACK_MODEL = 'openai';
const PRIMARY_MAX_TOKENS = 1024;
const FALLBACK_MAX_TOKENS = 4096;
const MAX_MENU_CONTEXT_CHARS = 3000;
const MAX_HISTORY_MESSAGES = 12;

function fetchWithTimeout(
  url: string,
  options: RequestInit,
  timeoutMs = REQUEST_TIMEOUT_MS,
): Promise<Response> {
  return new Promise((resolve, reject) => {
    const controller = new AbortController();
    const timer = setTimeout(() => {
      controller.abort();
      reject(new Error('Request timed out — check your internet connection.'));
    }, timeoutMs);
    fetch(url, { ...options, signal: controller.signal })
      .then(res => {
        clearTimeout(timer);
        resolve(res);
      })
      .catch(err => {
        clearTimeout(timer);
        if (err?.name === 'AbortError') {
          reject(new Error('Request timed out — check your internet connection.'));
        } else {
          reject(err);
        }
      });
  });
}

async function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchWithRetry(
  url: string,
  options: RequestInit,
  timeoutMs = REQUEST_TIMEOUT_MS,
  maxRetries = MAX_RETRIES,
): Promise<Response> {
  let lastError: Error | null = null;
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      const res = await fetchWithTimeout(url, options, timeoutMs);
      if (res.ok || (res.status >= 400 && res.status < 500)) {
        return res;
      }
      lastError = new Error(`Server error (${res.status})`);
      console.warn(`[VoiceAI] Attempt ${attempt + 1} failed with ${res.status}, retrying...`);
    } catch (err: any) {
      lastError = err;
      if (err?.message?.includes('timed out') && attempt < maxRetries) {
        console.warn(`[VoiceAI] Attempt ${attempt + 1} timed out, retrying...`);
      } else if (attempt >= maxRetries) {
        throw err;
      }
    }
    if (attempt < maxRetries) {
      await sleep(RETRY_DELAY_MS * (attempt + 1));
    }
  }
  throw lastError ?? new Error('Request failed after retries');
}

async function parseApiError(res: Response): Promise<string> {
  try {
    const body = await res.json();
    if (body?.error?.message) return body.error.message;
    if (body?.error?.code) return `${body.error.code}: ${body.error.message ?? 'Unknown error'}`;
    return `HTTP ${res.status}`;
  } catch {
    try {
      const text = await res.text();
      return text.substring(0, 200) || `HTTP ${res.status}`;
    } catch {
      return `HTTP ${res.status}`;
    }
  }
}

/**
 * Extract content from a chat completion response, handling multiple formats.
 */
function extractContent(data: any): string {
  // Standard OpenAI format
  const c1 = data?.choices?.[0]?.message?.content;
  if (typeof c1 === 'string' && c1.trim()) return c1.trim();

  // Some APIs use delta instead of message
  const c2 = data?.choices?.[0]?.delta?.content;
  if (typeof c2 === 'string' && c2.trim()) return c2.trim();

  // Some APIs use text field directly
  const c3 = data?.choices?.[0]?.text;
  if (typeof c3 === 'string' && c3.trim()) return c3.trim();

  // Fallback: top-level text or content
  const c4 = data?.text ?? data?.content ?? data?.response ?? data?.output;
  if (typeof c4 === 'string' && c4.trim()) return c4.trim();

  // Multiple choices — try all
  if (Array.isArray(data?.choices)) {
    for (const choice of data.choices) {
      const ct = choice?.message?.content ?? choice?.text ?? choice?.delta?.content;
      if (typeof ct === 'string' && ct.trim()) return ct.trim();
    }
  }

  return '';
}

export class VoiceAIService {
  private chatUrl = Config.voiceChatUrl;
  private ttsUrl = Config.voiceTtsUrl;
  private sttUrl = Config.voiceSttUrl;
  private apiKey = Config.pollinationApiKey;
  // Once we detect credits are exhausted, skip authenticated requests to reduce latency
  private _creditsExhausted = false;

  private getHeaders(includeAuth = true): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    if (includeAuth && this.apiKey && !this._creditsExhausted) {
      headers.Authorization = `Bearer ${this.apiKey}`;
    }
    return headers;
  }

  private getAuthHeaders(includeAuth = true): Record<string, string> {
    const headers: Record<string, string> = {};
    if (includeAuth && this.apiKey && !this._creditsExhausted) {
      headers.Authorization = `Bearer ${this.apiKey}`;
    }
    return headers;
  }

  private _markCreditsExhausted(): void {
    if (!this._creditsExhausted) {
      this._creditsExhausted = true;
      console.warn('[VoiceAI] Credits exhausted — switching to free tier (no auth)');
    }
  }

  async verifyConnection(): Promise<{ ok: boolean; error?: string }> {
    try {
      const res = await fetchWithTimeout(
        `${this.chatUrl.replace('/v1/chat/completions', '')}/v1/models`,
        { method: 'GET', headers: this.getAuthHeaders() },
        8000,
      );
      if (res.ok) return { ok: true };
      if (res.status === 402) {
        // Credits exhausted but free tier still works
        this._markCreditsExhausted();
        // Verify free tier works
        const freeRes = await fetchWithTimeout(
          `${this.chatUrl.replace('/v1/chat/completions', '')}/v1/models`,
          { method: 'GET' },
          8000,
        );
        if (freeRes.ok) return { ok: true };
        return { ok: false, error: 'API unavailable' };
      }
      if (res.status === 401) return { ok: false, error: 'Invalid API key. Check your Pollinations key.' };
      return { ok: false, error: `API returned ${res.status}` };
    } catch (err: any) {
      return { ok: false, error: err?.message ?? 'Cannot reach Pollinations API' };
    }
  }

  /**
   * Speech-to-Text via Pollinations Whisper endpoint (WEB).
   */
  async transcribeAudioBlob(audioBlob: Blob, filename: string = 'recording.webm', language?: string): Promise<string> {
    if (audioBlob.size < 100) {
      console.warn('[VoiceAI] Audio blob too small:', audioBlob.size);
      return '';
    }

    const buildFormData = () => {
      const fd = new FormData();
      fd.append('file', audioBlob, filename);
      fd.append('model', 'whisper-1');
      if (language) fd.append('language', language);
      return fd;
    };

    try {
      console.log('[VoiceAI] STT request (web), size:', audioBlob.size, 'lang:', language ?? 'auto');
      let res = await fetchWithRetry(this.sttUrl, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: buildFormData() as any,
      }, REQUEST_TIMEOUT_MS, 1);

      // Free-tier fallback: retry without auth on 402
      if (res.status === 402) {
        this._markCreditsExhausted();
        console.log('[VoiceAI] STT retrying on free tier (no auth)...');
        res = await fetchWithRetry(this.sttUrl, {
          method: 'POST',
          headers: this.getAuthHeaders(false),
          body: buildFormData() as any,
        }, REQUEST_TIMEOUT_MS, 1);
      }

      if (!res.ok) {
        const errMsg = await parseApiError(res);
        console.error('[VoiceAI] STT error:', res.status, errMsg);
        if (res.status === 401) throw new Error('Invalid API key — check your Pollinations key');
        throw new Error(`Transcription failed: ${errMsg}`);
      }

      const data = await res.json();
      const text = (data.text ?? data.choices?.[0]?.message?.content ?? '').trim();
      console.log('[VoiceAI] STT result:', text.substring(0, 80) || '(empty)');
      return text;
    } catch (err: any) {
      if (err?.message?.includes('timed out')) {
        throw new Error('Speech recognition timed out. Please try again.');
      }
      throw new Error(err?.message ?? 'Transcription failed');
    }
  }

  /**
   * Speech-to-Text via Pollinations Whisper endpoint (NATIVE / React Native).
   */
  async transcribeFileUri(fileUri: string, mimeType: string = 'audio/wav', filename: string = 'recording.wav', language?: string): Promise<string> {
    const buildFormData = () => {
      const fd = new FormData();
      fd.append('file', {
        uri: fileUri,
        name: filename,
        type: mimeType,
      } as any);
      fd.append('model', 'whisper-1');
      if (language) fd.append('language', language);
      return fd;
    };

    try {
      console.log('[VoiceAI] STT request (native), uri:', fileUri, 'lang:', language ?? 'auto');
      let res = await fetchWithRetry(this.sttUrl, {
        method: 'POST',
        headers: this.getAuthHeaders(),
        body: buildFormData() as any,
      }, REQUEST_TIMEOUT_MS, 1);

      // Free-tier fallback: retry without auth on 402
      if (res.status === 402) {
        this._markCreditsExhausted();
        console.log('[VoiceAI] STT retrying on free tier (no auth)...');
        res = await fetchWithRetry(this.sttUrl, {
          method: 'POST',
          headers: this.getAuthHeaders(false),
          body: buildFormData() as any,
        }, REQUEST_TIMEOUT_MS, 1);
      }

      if (!res.ok) {
        const errMsg = await parseApiError(res);
        console.error('[VoiceAI] STT error:', res.status, errMsg);
        if (res.status === 401) throw new Error('Invalid API key — check your Pollinations key');
        throw new Error(`Transcription failed: ${errMsg}`);
      }

      const data = await res.json();
      const text = (data.text ?? data.choices?.[0]?.message?.content ?? '').trim();
      console.log('[VoiceAI] STT result:', text.substring(0, 80) || '(empty)');
      return text;
    } catch (err: any) {
      if (err?.message?.includes('timed out')) {
        throw new Error('Speech recognition timed out. Please try again.');
      }
      throw new Error(err?.message ?? 'Transcription failed');
    }
  }

  /**
   * Main chat completion — sends conversation history + menu/prefs context.
   *
   * Intent classification is embedded in the main prompt to avoid a second API call.
   * Uses openai-large (GPT-5.2, non-reasoning) as primary; falls back to openai (GPT-5-mini,
   * reasoning) with high max_tokens if needed.
   * Returns the AI response text, never throws for empty responses (returns fallback instead).
   */
  async chat(
    messages: ChatMessage[],
    menuContext: string,
    foodMemoryContext: string,
    language: string = 'en',
  ): Promise<string> {
    const languageInstruction = language === 'ar'
      ? `LANGUAGE: Respond ENTIRELY in Arabic (العربية). Use natural Gulf/Levantine Arabic, not classical. All text must be Arabic.`
      : language !== 'en'
        ? `LANGUAGE: The user speaks "${language}". Respond in the same language.`
        : `LANGUAGE: English. If the user writes Arabic or another language, switch to that language.`;

    const trimmedMenu = menuContext.length > MAX_MENU_CONTEXT_CHARS
      ? menuContext.substring(0, MAX_MENU_CONTEXT_CHARS) + '\n...(more items available)'
      : menuContext;

    const recentMessages = messages.length > MAX_HISTORY_MESSAGES
      ? messages.slice(-MAX_HISTORY_MESSAGES)
      : messages;

    const systemContent = `You are a fast, decisive food ordering assistant. Responses are read aloud — keep them SHORT (1-2 sentences). Act immediately, don't over-confirm.

${languageInstruction}

CRITICAL RULES:
- ACT FIRST, talk second. When user wants an item, add it immediately and confirm in one sentence.
- NEVER ask "would you like me to add that?" — just add it.
- NEVER repeat the full menu. Mention 2-3 items max when recommending.
- When user asks "what do you have?" or "show menu", list 4-5 top items with prices briefly.
- When user says "yes", "confirm", "that's it", "نعم", "خلاص", "تمام" — proceed with confirm_order immediately.
- Only ask for address ONCE if not provided. Don't re-ask.
- No markdown, no bullets, no asterisks — plain speech only.
- Bilingual: English and Arabic. Switch seamlessly.

ORDER FLOW:
1. User wants items → add_to_cart immediately, say "Added [item] to your cart. Anything else?"
2. User says done → ask for address if not set, then confirm_order
3. User gives address → set_address, then confirm_order
4. Multiple items in one message → use MULTIPLE action blocks, one per item

ACTIONS — append at END of every response:
|||ACTION:{"type":"<type>","itemName":"<name>","quantity":<n>}|||

Types: add_to_cart, remove_from_cart, update_quantity, clear_cart, view_cart, apply_promo, set_delivery_notes, confirm_order, set_address, none

USER PREFERENCES: ${foodMemoryContext}

MENU:
${trimmedMenu}`.trim();

    const systemMessage: ChatMessage = { role: 'system', content: systemContent };
    const allMessages: ChatMessage[] = [systemMessage, ...recentMessages];

    console.log('[VoiceAI] Chat request — model:', PRIMARY_MODEL,
      'messages:', allMessages.length, 'lang:', language,
      'sysLen:', systemContent.length, 'menuLen:', trimmedMenu.length);

    // Attempt 1: primary model (openai-large / GPT-5.2, non-reasoning)
    const content = await this._chatRequest(allMessages, PRIMARY_MODEL, PRIMARY_MAX_TOKENS);
    if (content) return content;

    // Attempt 2: fallback model (openai / GPT-5-mini reasoning) with high token budget
    console.warn('[VoiceAI] Primary model returned empty, trying fallback model:', FALLBACK_MODEL);
    const fallbackContent = await this._chatRequest(allMessages, FALLBACK_MODEL, FALLBACK_MAX_TOKENS);
    if (fallbackContent) return fallbackContent;

    // Attempt 3: minimal prompt — just the user's last message, no context
    const lastUserMsg = [...recentMessages].reverse().find(m => m.role === 'user');
    if (lastUserMsg) {
      console.warn('[VoiceAI] Fallback model also empty, trying minimal prompt');
      const minimalMessages: ChatMessage[] = [
        { role: 'system', content: 'You are a helpful food ordering assistant. Be concise. End with |||ACTION:{"type":"none"}|||' },
        lastUserMsg,
      ];
      const minContent = await this._chatRequest(minimalMessages, PRIMARY_MODEL, PRIMARY_MAX_TOKENS);
      if (minContent) return minContent;
    }

    console.error('[VoiceAI] All chat attempts returned empty');
    return "I'm sorry, could you say that again? I didn't quite catch that. |||ACTION:{\"type\":\"none\"}|||";
  }

  /**
   * Low-level chat completion request. Returns content string or empty string on failure.
   */
  private async _chatRequest(
    messages: ChatMessage[],
    model: string,
    maxTokens: number,
  ): Promise<string> {
    const body: ChatCompletionRequest = {
      model,
      messages,
      temperature: 0.3,
      max_tokens: maxTokens,
    };

    try {
      let res = await fetchWithRetry(this.chatUrl, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(body),
      });

      // Free-tier fallback: retry without auth on 402
      if (res.status === 402) {
        this._markCreditsExhausted();
        console.log('[VoiceAI] Chat retrying on free tier (no auth), model:', model);
        res = await fetchWithRetry(this.chatUrl, {
          method: 'POST',
          headers: this.getHeaders(false),
          body: JSON.stringify(body),
        });
      }

      if (!res.ok) {
        const errMsg = await parseApiError(res);
        console.error('[VoiceAI] Chat error:', res.status, errMsg, 'model:', model);
        if (res.status === 401) throw new Error('Invalid API key — check your Pollinations key');
        throw new Error(`AI request failed: ${errMsg}`);
      }

      const data = await res.json();
      const usage = data?.usage;
      console.log('[VoiceAI] Chat response — model:', data?.model ?? model,
        'finish:', data?.choices?.[0]?.finish_reason,
        'tokens:', usage?.total_tokens,
        'reasoning:', usage?.completion_tokens_details?.reasoning_tokens ?? 0);

      const content = extractContent(data);
      if (!content) {
        console.warn('[VoiceAI] Empty content from', model,
          '— raw:', JSON.stringify(data).substring(0, 500));
        return '';
      }

      console.log('[VoiceAI] Chat reply (', model, '):', content.substring(0, 100));
      return content;
    } catch (err: any) {
      if (err?.message?.includes('timed out')) {
        throw new Error('The assistant is taking too long. Please try again.');
      }
      if (err?.message?.includes('Pollen') || err?.message?.includes('API key')) {
        throw err;
      }
      console.error('[VoiceAI] _chatRequest error with', model, ':', err?.message);
      return '';
    }
  }

  /**
   * Generate TTS audio via Pollinations POST endpoint (web only — uses blob URLs).
   */
  async generateTtsAudioUrl(text: string, voice: string = 'nova'): Promise<string> {
    const body = {
      model: 'tts-1',
      input: text.slice(0, 1000),
      voice,
    };

    console.log('[VoiceAI] TTS POST request, voice:', voice, 'length:', text.length);
    let res = await fetchWithRetry(this.ttsUrl, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(body),
    }, 20000, 1);

    // Free-tier fallback on 402
    if (res.status === 402) {
      this._markCreditsExhausted();
      res = await fetchWithRetry(this.ttsUrl, {
        method: 'POST',
        headers: this.getHeaders(false),
        body: JSON.stringify(body),
      }, 20000, 1);
    }

    if (!res.ok) {
      const errMsg = await parseApiError(res);
      console.error('[VoiceAI] TTS POST error:', res.status, errMsg);
      throw new Error(`TTS failed (${res.status}): ${errMsg}`);
    }

    const blob = await res.blob();
    if (blob.size < 100) {
      throw new Error('TTS returned empty audio');
    }
    if (typeof URL !== 'undefined' && typeof URL.createObjectURL === 'function') {
      const url = URL.createObjectURL(blob);
      console.log('[VoiceAI] TTS audio ready (blob URL), size:', blob.size, 'bytes');
      return url;
    }
    throw new Error('URL.createObjectURL not available on this platform');
  }

  /**
   * Build a direct streaming URL for TTS via Pollinations GET /audio/{text}.
   * This URL can be passed directly to expo-av on native — no download/blob needed.
   */
  getTtsStreamUrl(text: string, voice: string = 'nova'): string {
    const encodedText = encodeURIComponent(text.slice(0, 500));
    const baseUrl = this.ttsUrl.replace('/v1/audio/speech', '');
    let url = `${baseUrl}/audio/${encodedText}?voice=${voice}`;
    if (this.apiKey) {
      url += `&token=${this.apiKey}`;
    }
    return url;
  }

  /**
   * Fallback TTS via GET /audio/{text} — fetches and returns blob URL (web only).
   */
  async generateTtsAudioUrlGet(text: string, voice: string = 'nova'): Promise<string> {
    const url = this.getTtsStreamUrl(text, voice);

    console.log('[VoiceAI] TTS GET request, voice:', voice);
    const res = await fetchWithTimeout(url, { method: 'GET' }, 20000);

    if (!res.ok) {
      throw new Error(`TTS GET failed (${res.status})`);
    }

    const blob = await res.blob();
    if (blob.size < 100) {
      throw new Error('TTS GET returned empty audio');
    }
    if (typeof URL !== 'undefined' && typeof URL.createObjectURL === 'function') {
      const blobUrl = URL.createObjectURL(blob);
      console.log('[VoiceAI] TTS GET audio ready (blob URL), size:', blob.size, 'bytes');
      return blobUrl;
    }
    throw new Error('URL.createObjectURL not available on this platform');
  }
}

export const voiceAIService = new VoiceAIService();
