import { Audio } from 'expo-av';
import * as Speech from 'expo-speech';
import { Platform } from 'react-native';
import { voiceAIService } from './VoiceAIService';

const isWeb = Platform.OS === 'web';

const RECORDING_OPTIONS: Audio.RecordingOptions = {
  isMeteringEnabled: true,
  android: {
    extension: '.wav',
    outputFormat: Audio.AndroidOutputFormat.DEFAULT,
    audioEncoder: Audio.AndroidAudioEncoder.DEFAULT,
    sampleRate: 16000,
    numberOfChannels: 1,
    bitRate: 128000,
  },
  ios: {
    extension: '.wav',
    outputFormat: Audio.IOSOutputFormat.LINEARPCM,
    audioQuality: Audio.IOSAudioQuality.HIGH,
    sampleRate: 16000,
    numberOfChannels: 1,
    bitRate: 128000,
    linearPCMBitDepth: 16,
    linearPCMIsBigEndian: false,
    linearPCMIsFloat: false,
  },
  web: {
    mimeType: 'audio/webm;codecs=opus',
    bitsPerSecond: 128000,
  },
};

const SILENCE_THRESHOLD_DB = -38;
const VOICE_DETECTED_DB = -30;
const SILENCE_DURATION_MS = 2500;
const METERING_INTERVAL_MS = 200;
const MIN_RECORDING_MS = 800;
const TTS_NATIVE_TIMEOUT_MS = 12000;

// Hard cap: recording will ALWAYS stop after this, regardless of metering
const HARD_MAX_RECORDING_MS = 12000;
// Time-based fallback: if metering doesn't work, record for this long then stop
const FALLBACK_RECORD_DURATION_MS = 5000;
// Number of metering polls to check before deciding metering is broken
const METERING_CHECK_POLLS = 5;
// What metering value means "no data" (expo-av returns -160 or undefined when broken)
const METERING_NO_DATA_DB = -120;

// Web-specific
const WEB_MIN_RECORD_MS = 3000;
const WEB_MAX_RECORD_MS = 10000;
const WEB_SILENCE_CHECK_MS = 1500;

export class AudioService {
  private recording: Audio.Recording | null = null;
  private isSpeaking = false;
  private silenceTimer: ReturnType<typeof setTimeout> | null = null;
  private meteringInterval: ReturnType<typeof setInterval> | null = null;
  private recordingStartTime = 0;
  private onSilenceCallback: (() => void) | null = null;
  private voiceDetected = false;
  private silenceCallbackFired = false;
  private maxRecordingTimer: ReturnType<typeof setTimeout> | null = null;
  private ttsLanguage = 'en-US';
  private detectedLang = 'en';

  // Web Audio API for better web metering
  private webAudioContext: AudioContext | null = null;
  private webAnalyser: AnalyserNode | null = null;
  private webMediaStream: MediaStream | null = null;
  private webMediaSource: MediaStreamAudioSourceNode | null = null;

  setLanguage(lang: string): void {
    this.detectedLang = lang;
    const langMap: Record<string, string> = {
      en: 'en-US',
      ar: 'ar-SA',
      fr: 'fr-FR',
      es: 'es-ES',
      de: 'de-DE',
      zh: 'zh-CN',
      ja: 'ja-JP',
      ko: 'ko-KR',
      hi: 'hi-IN',
      tr: 'tr-TR',
    };
    this.ttsLanguage = langMap[lang] ?? `${lang}-${lang.toUpperCase()}`;
    console.log('[AudioService] Language set:', this.detectedLang, '→ TTS:', this.ttsLanguage);
  }

  async requestPermissions(): Promise<boolean> {
    try {
      const { granted } = await Audio.requestPermissionsAsync();
      if (granted) {
        await Audio.setAudioModeAsync({
          allowsRecordingIOS: true,
          playsInSilentModeIOS: true,
          staysActiveInBackground: false,
          shouldDuckAndroid: true,
        });
      }
      return granted;
    } catch (err) {
      console.error('[AudioService] Permission error:', err);
      return false;
    }
  }

  /**
   * Start recording audio from the microphone.
   * In live mode, pass onSilence to auto-stop after silence.
   */
  async startRecording(onSilence?: () => void): Promise<boolean> {
    try {
      if (this.recording) {
        await this.cancelRecording();
      }
      // Fully await playback cleanup to avoid audio session conflicts
      await this.stopPlaybackAsync();

      const hasPermission = await this.ensureMicPermission();
      if (!hasPermission) {
        console.error('[AudioService] Microphone permission denied');
        return false;
      }

      // On native, explicitly switch audio mode to recording
      if (!isWeb) {
        try {
          await Audio.setAudioModeAsync({
            allowsRecordingIOS: true,
            playsInSilentModeIOS: true,
            staysActiveInBackground: false,
            shouldDuckAndroid: true,
          });
        } catch (modeErr) {
          console.warn('[AudioService] Audio mode switch failed, retrying:', modeErr);
          await new Promise(r => setTimeout(r, 200));
          await Audio.setAudioModeAsync({
            allowsRecordingIOS: true,
            playsInSilentModeIOS: true,
            staysActiveInBackground: false,
            shouldDuckAndroid: true,
          });
        }
      }

      console.log('[AudioService] Starting recording...');
      const { recording } = await Audio.Recording.createAsync(RECORDING_OPTIONS);
      this.recording = recording;
      this.recordingStartTime = Date.now();
      this.onSilenceCallback = onSilence ?? null;
      this.voiceDetected = false;
      this.silenceCallbackFired = false;
      this.clearMaxRecordingTimer();

      // Set up Web Audio API analyser for better web metering
      if (isWeb && onSilence) {
        await this.setupWebAudioAnalyser();
      }

      console.log('[AudioService] Recording started (silence:', !!onSilence, 'web:', isWeb, ')');

      if (onSilence) {
        this.startSilenceDetection();
        this.maxRecordingTimer = setTimeout(() => {
          console.log('[AudioService] Hard max recording time reached, forcing stop');
          this.fireSilenceCallback();
        }, isWeb ? WEB_MAX_RECORD_MS : HARD_MAX_RECORDING_MS);
      }

      return true;
    } catch (err) {
      console.error('[AudioService] Start recording error:', err);
      this.recording = null;
      this.cleanupWebAudio();
      return false;
    }
  }

  /**
   * Set up Web Audio API AnalyserNode for real metering on web.
   * Falls back gracefully if unavailable.
   */
  private async setupWebAudioAnalyser(): Promise<void> {
    try {
      if (typeof window === 'undefined' || !window.AudioContext) return;

      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.webMediaStream = stream;
      this.webAudioContext = new AudioContext();
      this.webAnalyser = this.webAudioContext.createAnalyser();
      this.webAnalyser.fftSize = 256;
      this.webAnalyser.smoothingTimeConstant = 0.3;
      this.webMediaSource = this.webAudioContext.createMediaStreamSource(stream);
      this.webMediaSource.connect(this.webAnalyser);
      console.log('[AudioService] Web Audio API analyser initialized');
    } catch (err) {
      console.warn('[AudioService] Web Audio API setup failed, using fallback:', err);
      this.cleanupWebAudio();
    }
  }

  /**
   * Get current audio level in dB using Web Audio API.
   * Returns null if analyser is not available.
   */
  private getWebAudioLevel(): number | null {
    if (!this.webAnalyser) return null;
    try {
      const dataArray = new Uint8Array(this.webAnalyser.frequencyBinCount);
      this.webAnalyser.getByteFrequencyData(dataArray);
      let sum = 0;
      for (let i = 0; i < dataArray.length; i++) {
        sum += dataArray[i];
      }
      const avg = sum / dataArray.length;
      // Convert 0-255 scale to approximate dB (-160 to 0)
      if (avg === 0) return -160;
      const db = 20 * Math.log10(avg / 255);
      return db;
    } catch {
      return null;
    }
  }

  private cleanupWebAudio(): void {
    try { this.webMediaSource?.disconnect(); } catch { /* ignore */ }
    try { this.webAnalyser?.disconnect(); } catch { /* ignore */ }
    try { this.webAudioContext?.close(); } catch { /* ignore */ }
    if (this.webMediaStream) {
      this.webMediaStream.getTracks().forEach(t => t.stop());
    }
    this.webMediaSource = null;
    this.webAnalyser = null;
    this.webAudioContext = null;
    this.webMediaStream = null;
  }

  /**
   * Poll recording metering to detect silence and auto-stop.
   *
   * Multi-strategy approach to handle devices where expo-av metering doesn't work:
   *
   * 1. METERING MODE: If getStatusAsync().metering returns real values (> -120 dB),
   *    use standard voice-detect → silence-after-voice logic.
   *
   * 2. FALLBACK MODE: If the first N metering polls all return -160/undefined,
   *    metering is broken on this device. Switch to a fixed recording window
   *    (FALLBACK_RECORD_DURATION_MS) and assume the user spoke during that time.
   *
   * 3. HARD CAP: maxRecordingTimer (set in startRecording) always fires as final safety net.
   */
  private startSilenceDetection(): void {
    this.stopSilenceDetection();
    let silentSince = 0;
    let pollCount = 0;
    let realMeteringCount = 0;
    let meteringDecided = false;
    let meteringWorks = false;

    console.log('[AudioService] Starting silence detection (platform:', Platform.OS, ')');

    this.meteringInterval = setInterval(async () => {
      if (!this.recording || this.silenceCallbackFired) {
        this.stopSilenceDetection();
        return;
      }

      const elapsed = Date.now() - this.recordingStartTime;
      if (elapsed < MIN_RECORDING_MS) return;

      try {
        // ── Web platform: use Web Audio API or time-based ──
        const webLevel = this.getWebAudioLevel();
        if (isWeb) {
          if (webLevel !== null) {
            // Web Audio API works — use it like metering
            const db = webLevel;
            if (db >= VOICE_DETECTED_DB) {
              this.voiceDetected = true;
              silentSince = 0;
              return;
            }
            if (this.voiceDetected && db < SILENCE_THRESHOLD_DB) {
              if (silentSince === 0) silentSince = Date.now();
              if (Date.now() - silentSince >= SILENCE_DURATION_MS) {
                console.log('[AudioService] Web Audio silence detected');
                this.fireSilenceCallback();
              }
            } else if (db >= SILENCE_THRESHOLD_DB) {
              silentSince = 0;
            }
          } else {
            // No Web Audio API — use time-based
            if (elapsed >= WEB_MIN_RECORD_MS) {
              this.voiceDetected = true;
              if (silentSince === 0) silentSince = Date.now();
              if (Date.now() - silentSince >= WEB_SILENCE_CHECK_MS) {
                console.log('[AudioService] Web time-based silence trigger');
                this.fireSilenceCallback();
              }
            }
          }
          return;
        }

        // ── Native platform: expo-av metering with fallback ──
        const status = await this.recording.getStatusAsync();
        if (!status.isRecording) return;
        const db = status.metering ?? -160;
        pollCount++;

        // Phase 1: Determine if metering actually works on this device
        if (!meteringDecided) {
          if (db > METERING_NO_DATA_DB) {
            realMeteringCount++;
          }
          if (pollCount >= METERING_CHECK_POLLS) {
            meteringDecided = true;
            meteringWorks = realMeteringCount > 0;
            if (meteringWorks) {
              console.log('[AudioService] Metering is working (', realMeteringCount, '/', pollCount, ' real readings)');
            } else {
              console.log('[AudioService] Metering NOT working — switching to time-based fallback');
              // Schedule fallback stop: record for FALLBACK_RECORD_DURATION_MS total
              const remainingMs = Math.max(500, FALLBACK_RECORD_DURATION_MS - elapsed);
              this.silenceTimer = setTimeout(() => {
                console.log('[AudioService] Fallback timer fired after', FALLBACK_RECORD_DURATION_MS, 'ms total recording');
                this.voiceDetected = true; // Assume user spoke
                this.fireSilenceCallback();
              }, remainingMs);
            }
          }
          // While deciding, don't block — just collect data
          // But still detect obvious voice
          if (db >= VOICE_DETECTED_DB) {
            this.voiceDetected = true;
            silentSince = 0;
          }
          return;
        }

        // Phase 2a: Metering works — standard voice-detect + silence logic
        if (meteringWorks) {
          if (db >= VOICE_DETECTED_DB) {
            if (!this.voiceDetected) {
              console.log('[AudioService] Voice detected (dB:', db.toFixed(1), ')');
            }
            this.voiceDetected = true;
            silentSince = 0;
            return;
          }

          if (!this.voiceDetected) return;

          if (db < SILENCE_THRESHOLD_DB) {
            if (silentSince === 0) silentSince = Date.now();
            const silentFor = Date.now() - silentSince;
            if (silentFor >= SILENCE_DURATION_MS) {
              console.log('[AudioService] Silence detected after speech (', silentFor, 'ms, dB:', db.toFixed(1), ')');
              this.fireSilenceCallback();
            }
          } else {
            silentSince = 0;
          }
        }
        // Phase 2b: Metering broken — fallback timer handles it (set above)
        // Nothing to do here, the setTimeout in Phase 1 will fire
      } catch {
        // recording may have ended
      }
    }, METERING_INTERVAL_MS);
  }

  private fireSilenceCallback(): void {
    if (this.silenceCallbackFired) return;
    this.silenceCallbackFired = true;
    const cb = this.onSilenceCallback;
    this.stopSilenceDetection();
    cb?.();
  }

  private stopSilenceDetection(): void {
    if (this.meteringInterval) {
      clearInterval(this.meteringInterval);
      this.meteringInterval = null;
    }
    if (this.silenceTimer) {
      clearTimeout(this.silenceTimer);
      this.silenceTimer = null;
    }
    this.onSilenceCallback = null;
  }

  private clearMaxRecordingTimer(): void {
    if (this.maxRecordingTimer) {
      clearTimeout(this.maxRecordingTimer);
      this.maxRecordingTimer = null;
    }
  }

  hadVoiceActivity(): boolean {
    return this.voiceDetected;
  }

  /**
   * Stop recording and send the audio to Whisper STT.
   */
  async stopRecordingAndTranscribe(language?: string): Promise<string> {
    this.stopSilenceDetection();
    this.clearMaxRecordingTimer();
    this.cleanupWebAudio();

    if (!this.recording) {
      throw new Error('No active recording');
    }

    try {
      console.log('[AudioService] Stopping recording...');
      await this.recording.stopAndUnloadAsync();
      const uri = this.recording.getURI();
      this.recording = null;

      if (!uri) {
        throw new Error('No recording URI available');
      }

      const recordDuration = Date.now() - this.recordingStartTime;
      console.log('[AudioService] Recording saved, duration:', recordDuration, 'ms, uri:', uri.substring(0, 50));

      // Skip transcription for very short recordings (likely no speech)
      if (recordDuration < 500) {
        console.log('[AudioService] Recording too short, skipping transcription');
        return '';
      }

      let transcription: string;

      if (isWeb) {
        const response = await fetch(uri);
        const audioBlob = await response.blob();
        console.log('[AudioService] Web audio blob size:', audioBlob.size);
        if (audioBlob.size < 1000) {
          console.log('[AudioService] Audio blob too small, likely silence');
          return '';
        }
        transcription = await voiceAIService.transcribeAudioBlob(audioBlob, 'recording.webm', language);
      } else {
        await Audio.setAudioModeAsync({
          allowsRecordingIOS: false,
          playsInSilentModeIOS: true,
        });
        transcription = await voiceAIService.transcribeFileUri(uri, 'audio/wav', 'recording.wav', language);
      }

      return transcription;
    } catch (err: any) {
      this.recording = null;
      console.error('[AudioService] Transcription pipeline error:', err);
      throw new Error(err?.message ?? 'Failed to process voice input');
    }
  }

  async cancelRecording(): Promise<void> {
    this.stopSilenceDetection();
    this.clearMaxRecordingTimer();
    this.cleanupWebAudio();
    if (this.recording) {
      try {
        await this.recording.stopAndUnloadAsync();
      } catch {
        // ignore
      }
      this.recording = null;
    }
  }

  private playbackSound: Audio.Sound | null = null;
  private _permissionGranted: boolean | null = null;

  /**
   * Pre-request mic permission so it's ready when recording starts.
   * Call once early (e.g. before TTS greeting) to avoid delays in the auto-listen loop.
   */
  async ensureMicPermission(): Promise<boolean> {
    if (this._permissionGranted === true) return true;
    const granted = await this.requestPermissions();
    this._permissionGranted = granted;
    return granted;
  }

  /**
   * Properly await all playback resource cleanup.
   * Unlike stopPlayback(), this waits for async unloads to complete.
   */
  async stopPlaybackAsync(): Promise<void> {
    try { Speech.stop(); } catch { /* ignore */ }
    if (this.playbackSound) {
      try {
        await this.playbackSound.stopAsync();
        await this.playbackSound.unloadAsync();
      } catch { /* ignore */ }
      this.playbackSound = null;
    }
    if (this.webAudioElement) {
      try {
        this.webAudioElement.pause();
        this.webAudioElement.src = '';
      } catch { /* ignore */ }
      this.webAudioElement = null;
    }
    this.isSpeaking = false;
  }

  /**
   * Speak text aloud.
   *
   * Strategy per platform:
   *   Native (iOS/Android):
   *     1. expo-speech (instant, no network, most reliable)
   *     2. Pollinations GET stream URL → expo-av (better voice, but adds latency)
   *   Web:
   *     1. Pollinations POST → blob URL → HTML Audio
   *     2. Pollinations GET → blob URL → HTML Audio
   *     3. expo-speech (SpeechSynthesis) fallback
   *
   * Arabic always routes to expo-speech with ar-SA for best pronunciation.
   */
  async playTTS(text: string, voice: string = 'nova'): Promise<void> {
    try {
      await this.stopPlaybackAsync();
      this.isSpeaking = true;
      console.log('[AudioService] Speaking (', this.detectedLang, '):', text.substring(0, 60));

      if (!isWeb) {
        await this.playTTSNative(text, voice);
      } else {
        await this.playTTSWeb(text, voice);
      }
    } catch (err) {
      console.error('[AudioService] TTS error:', err);
      this.isSpeaking = false;
    }
  }

  /**
   * Native TTS: expo-speech first (instant, reliable), Pollinations stream as enhancement.
   * Always resolves — never blocks the conversation loop.
   */
  private async playTTSNative(text: string, voice: string): Promise<void> {
    // expo-speech is the primary TTS engine on native — zero network latency
    await this.speakWithExpoSpeech(text);
  }

  /**
   * Web TTS: use blob URLs via POST/GET, fallback to expo-speech (SpeechSynthesis).
   */
  private async playTTSWeb(text: string, voice: string): Promise<void> {
    // Try Pollinations POST TTS (blob URL)
    try {
      const audioUrl = await voiceAIService.generateTtsAudioUrl(text, voice);
      await this.playWebAudio(audioUrl);
      console.log('[AudioService] Web TTS POST playback finished');
      this.isSpeaking = false;
      return;
    } catch (postErr) {
      console.warn('[AudioService] Web TTS POST failed:', postErr);
    }

    // Try Pollinations GET TTS (blob URL)
    try {
      const audioUrl = await voiceAIService.generateTtsAudioUrlGet(text, voice);
      await this.playWebAudio(audioUrl);
      console.log('[AudioService] Web TTS GET playback finished');
      this.isSpeaking = false;
      return;
    } catch (getErr) {
      console.warn('[AudioService] Web TTS GET also failed:', getErr);
    }

    // Final fallback: expo-speech (SpeechSynthesis on web)
    console.log('[AudioService] Web TTS: all endpoints failed, using expo-speech');
    await this.speakWithExpoSpeech(text);
  }

  /**
   * Play an audio URL on web only (native uses playTTSNative instead).
   * Kept for any other audio playback needs.
   */
  private async playAudioUrl(audioUrl: string): Promise<void> {
    if (isWeb) {
      await this.playWebAudio(audioUrl);
    } else {
      try {
        await Audio.setAudioModeAsync({
          allowsRecordingIOS: false,
          playsInSilentModeIOS: true,
          staysActiveInBackground: false,
          shouldDuckAndroid: true,
        });
      } catch { /* ignore */ }
      const { sound } = await Audio.Sound.createAsync(
        { uri: audioUrl },
        { shouldPlay: true, volume: 1.0 },
      );
      this.playbackSound = sound;
      await new Promise<void>((resolve, reject) => {
        const timeout = setTimeout(() => {
          sound.unloadAsync().catch(() => {});
          this.playbackSound = null;
          reject(new Error('Playback timeout'));
        }, 60000);
        sound.setOnPlaybackStatusUpdate((status) => {
          if (status.isLoaded && status.didJustFinish) {
            clearTimeout(timeout);
            this.isSpeaking = false;
            sound.unloadAsync().catch(() => {});
            this.playbackSound = null;
            resolve();
          }
        });
      });
    }
  }

  /**
   * Speak with expo-speech — primary TTS engine on native.
   * Reliable, no network latency, supports all languages.
   */
  private speakWithExpoSpeech(text: string): Promise<void> {
    return new Promise<void>((resolve) => {
      let resolved = false;
      const done = () => {
        if (resolved) return;
        resolved = true;
        this.isSpeaking = false;
        resolve();
      };
      try {
        const lang = this.detectedLang === 'ar' ? 'ar-SA' : this.ttsLanguage;
        console.log('[AudioService] expo-speech speaking, lang:', lang, 'text:', text.substring(0, 40));
        Speech.speak(text, {
          language: lang,
          rate: this.detectedLang === 'ar' ? 0.9 : 1.0,
          pitch: 1.0,
          onDone: done,
          onStopped: done,
          onError: (err) => {
            console.warn('[AudioService] expo-speech error:', err);
            done();
          },
        });
        // Safety timeout — never block the conversation loop
        setTimeout(() => {
          if (!resolved) {
            console.warn('[AudioService] expo-speech timeout after 10s, resolving');
            Speech.stop();
            done();
          }
        }, 10000);
      } catch (err) {
        console.warn('[AudioService] expo-speech threw:', err);
        done();
      }
    });
  }

  private playWebAudio(url: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (typeof window === 'undefined') {
        reject(new Error('No window object'));
        return;
      }
      const audio = new window.Audio(url);
      this.webAudioElement = audio;

      const cleanup = () => {
        this.webAudioElement = null;
        try { URL.revokeObjectURL(url); } catch { /* ignore */ }
      };

      const timeout = setTimeout(() => {
        cleanup();
        reject(new Error('Web audio playback timeout'));
      }, 60000);

      audio.onended = () => {
        clearTimeout(timeout);
        cleanup();
        resolve();
      };
      audio.onerror = (e) => {
        clearTimeout(timeout);
        cleanup();
        reject(e);
      };
      audio.play().catch((err) => {
        clearTimeout(timeout);
        cleanup();
        reject(err);
      });
    });
  }

  private webAudioElement: HTMLAudioElement | null = null;

  stopPlayback(): void {
    try { Speech.stop(); } catch { /* ignore */ }
    if (this.playbackSound) {
      try {
        this.playbackSound.stopAsync();
        this.playbackSound.unloadAsync();
      } catch { /* ignore */ }
      this.playbackSound = null;
    }
    if (this.webAudioElement) {
      try {
        this.webAudioElement.pause();
        this.webAudioElement.src = '';
      } catch { /* ignore */ }
      this.webAudioElement = null;
    }
    this.isSpeaking = false;
  }

  getIsPlaying(): boolean {
    return this.isSpeaking;
  }

  getIsRecording(): boolean {
    return this.recording !== null;
  }
}

export const audioService = new AudioService();
