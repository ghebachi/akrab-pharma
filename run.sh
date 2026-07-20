#!/bin/bash
set -e

# Local dev: source .env and pass to Flutter
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

flutter run --dart-define=SUPABASE_URL="$SUPABASE_URL" --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"
