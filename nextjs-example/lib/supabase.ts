import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export interface DutyPharmacy {
  id: string;
  name_ar: string;
  name_fr: string;
  municipality: string;
  phone_number: string | null;
  latitude: number;
  longitude: number;
  is_night_duty: boolean;
  duty_date: string;
  distance_meters: number;
}

export async function fetchNearestDutyPharmacies(
  lat: number,
  lng: number,
  targetDate?: string
): Promise<DutyPharmacy[]> {
  const date = targetDate || new Date().toISOString().split('T')[0];

  const { data, error } = await supabase.rpc('get_nearest_duty_pharmacies', {
    user_lat: lat,
    user_lng: lng,
    target_date: date,
  });

  if (error) {
    console.error('Supabase RPC error:', error);
    return [];
  }

  return (data as DutyPharmacy[]) || [];
}
