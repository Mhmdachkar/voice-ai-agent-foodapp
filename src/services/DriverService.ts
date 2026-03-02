import type { SupabaseClient } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';
import type { DBDriverStatus, DBProfile } from '../models/SupabaseModels';
import type { AppUser } from '../models/AppUser';
import { mapProfileToAppUser } from './mappers/profileMapper';

export interface DriverServiceState {
  onlineDrivers: AppUser[];
  driverStatuses: Record<string, DBDriverStatus>;
  errorMessage?: string;
}

export class DriverService {
  private client: SupabaseClient;
  state: DriverServiceState = {
    onlineDrivers: [],
    driverStatuses: {},
  };

  constructor(client: SupabaseClient = supabase) {
    this.client = client;
  }

  async fetchDrivers(): Promise<void> {
    try {
      const { data: profiles, error: pErr } = await this.client
        .from('profiles')
        .select('*')
        .eq('role', 'driver')
        .returns<DBProfile[]>();

      if (pErr || !profiles) {
        this.state.errorMessage = pErr?.message ?? 'Failed to load drivers';
        return;
      }

      const { data: statuses, error: sErr } = await this.client
        .from('driver_status')
        .select('*')
        .returns<DBDriverStatus[]>();

      if (sErr || !statuses) {
        this.state.errorMessage = sErr?.message ?? 'Failed to load driver status';
        return;
      }

      const map: Record<string, DBDriverStatus> = {};
      for (const st of statuses) {
        map[st.driver_id] = st;
      }
      this.state.driverStatuses = map;

      this.state.onlineDrivers = profiles
        .filter(p => map[p.id]?.is_online === true)
        .map(mapProfileToAppUser);
    } catch (e: any) {
      this.state.errorMessage = e?.message ?? 'Failed to fetch drivers';
    }
  }

  async fetchAllDriverProfiles(): Promise<AppUser[]> {
    try {
      const { data, error } = await this.client
        .from('profiles')
        .select('*')
        .eq('role', 'driver')
        .returns<DBProfile[]>();
      if (error || !data) return [];
      return data.map(mapProfileToAppUser);
    } catch {
      return [];
    }
  }

  async setOnlineStatus(driverId: string, isOnline: boolean): Promise<void> {
    try {
      const exists = !!this.state.driverStatuses[driverId];
      const now = new Date().toISOString();
      if (exists) {
        const payload = { is_online: isOnline, last_seen: now };
        await this.client
          .from('driver_status')
          .update(payload)
          .eq('driver_id', driverId);
      } else {
        const payload = { driver_id: driverId, is_online: isOnline };
        await this.client.from('driver_status').insert(payload);
      }
      this.state.driverStatuses[driverId] = {
        driver_id: driverId,
        is_online: isOnline,
        current_order_id: this.state.driverStatuses[driverId]?.current_order_id ?? null,
        last_seen: now,
      };
    } catch (e: any) {
      this.state.errorMessage = e?.message ?? 'Failed to update driver status';
    }
  }

  async clearCurrentOrder(driverId: string): Promise<void> {
    try {
      await this.client
        .from('driver_status')
        .update({ current_order_id: null })
        .eq('driver_id', driverId);
    } catch {
      // ignore
    }
  }
}

export const driverService = new DriverService();

