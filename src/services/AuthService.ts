import type { SupabaseClient } from '@supabase/supabase-js';
import { supabase, isSupabaseConfigured } from '../lib/supabase';
import type { DBProfile } from '../models/SupabaseModels';
import type { AppUser } from '../models/AppUser';
import { mapProfileToAppUser } from '../services/mappers/profileMapper';

export interface AuthResult {
  user: AppUser | null;
  error?: string;
}

/**
 * Auth service wrapping Supabase auth & profiles table.
 * Mirrors `SupabaseAuthService` behavior from Swift.
 */
export class AuthService {
  private client: SupabaseClient;

  constructor(client: SupabaseClient = supabase) {
    this.client = client;
  }

  async initialize(): Promise<AuthResult> {
    if (!isSupabaseConfigured) {
      return { user: null, error: undefined };
    }
    try {
      const {
        data: { session },
        error,
      } = await this.client.auth.getSession();
      if (error || !session) {
        return { user: null, error: error?.message };
      }
      const profile = await this.fetchProfile(session.user.id);
      if (!profile) return { user: null, error: 'Failed to load profile' };
      const user = mapProfileToAppUser(profile);
      return { user };
    } catch (e: any) {
      return { user: null, error: e?.message ?? 'Failed to initialize auth' };
    }
  }

  async signUp(
    email: string,
    password: string,
    fullName: string,
    role: string,
  ): Promise<AuthResult> {
    if (!isSupabaseConfigured) {
      return { user: null, error: 'Supabase is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file, or use Quick Login.' };
    }
    try {
      console.log('[AUTH] Starting signup:', { email, fullName, role });
      
      const { data, error } = await this.client.auth.signUp({
        email,
        password,
        options: {
          data: {
            full_name: fullName,
            role,
          },
        },
      });
      
      console.log('[AUTH] Signup response:', { 
        userId: data.user?.id, 
        error: error?.message,
        session: !!data.session 
      });
      
      if (error || !data.user) {
        console.log('[AUTH] Signup failed:', error?.message);
        return { user: null, error: error?.message ?? 'Sign up failed' };
      }
      
      console.log('[AUTH] Fetching profile for:', data.user.id);
      const profile = await this.fetchProfile(data.user.id, true);
      
      console.log('[AUTH] Profile fetched:', profile ? 'Found' : 'Not found');
      
      if (!profile) {
        console.log('[AUTH] Profile not found. Database trigger may not have run.');
        return { 
          user: null, 
          error: 'Profile not created. Please ensure database migration is complete.' 
        };
      }
      
      const user = mapProfileToAppUser(profile);
      console.log('[AUTH] User mapped successfully:', user.name, user.role);
      
      return { user };
    } catch (e: any) {
      console.error('[AUTH] Exception during signup:', e);
      return { user: null, error: e?.message ?? 'Sign up failed' };
    }
  }

  async signIn(email: string, password: string): Promise<AuthResult> {
    if (!isSupabaseConfigured) {
      return { user: null, error: 'Supabase is not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY in your .env file, or use Quick Login.' };
    }
    try {
      console.log('[AUTH] Starting sign in:', { email });
      
      const { data, error } = await this.client.auth.signInWithPassword({
        email,
        password,
      });
      
      console.log('[AUTH] Sign in response:', { 
        userId: data.user?.id, 
        error: error?.message 
      });
      
      if (error || !data.user) {
        console.log('[AUTH] Sign in failed:', error?.message);
        return { user: null, error: error?.message ?? 'Sign in failed' };
      }
      
      const profile = await this.fetchProfile(data.user.id);
      
      if (!profile) {
        console.log('[AUTH] Profile not found for existing user');
        return { user: null, error: 'Profile not found. Please contact support.' };
      }
      
      const user = mapProfileToAppUser(profile);
      console.log('[AUTH] Sign in successful:', user.name, user.role);
      
      return { user };
    } catch (e: any) {
      console.error('[AUTH] Exception during sign in:', e);
      return { user: null, error: e?.message ?? 'Sign in failed' };
    }
  }

  async signOut(): Promise<void> {
    await this.client.auth.signOut();
  }

  private async fetchProfile(userId: string, waitForTrigger = false): Promise<DBProfile | null> {
    console.log('[AUTH] Fetching profile for user:', userId);
    
    // Only delay after sign-up to allow database trigger to complete
    if (waitForTrigger) {
      await new Promise(resolve => setTimeout(resolve, 1500));
    }
    
    const { data, error } = await this.client
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle<DBProfile>();
    
    if (error) {
      console.error('[AUTH] Profile fetch error:', error.message);
      return null;
    }
    
    if (!data) {
      console.log('[AUTH] No profile found for user:', userId);
    }
    
    return data ?? null;
  }
}

export const authService = new AuthService();

