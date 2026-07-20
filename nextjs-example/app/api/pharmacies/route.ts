import { NextRequest, NextResponse } from 'next/server';
import { fetchNearestDutyPharmacies } from '@/lib/supabase';

export async function GET(request: NextRequest) {
  const { searchParams } = new URL(request.url);

  const lat = parseFloat(searchParams.get('lat') || '0');
  const lng = parseFloat(searchParams.get('lng') || '0');
  const date = searchParams.get('date') || undefined;

  if (!lat || !lng) {
    return NextResponse.json(
      { error: 'Missing lat or lng parameters' },
      { status: 400 }
    );
  }

  const pharmacies = await fetchNearestDutyPharmacies(lat, lng, date);

  return NextResponse.json({
    count: pharmacies.length,
    pharmacies,
  });
}
