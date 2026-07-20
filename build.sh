#!/bin/bash
set -e

echo "=== 1. Cloning Flutter SDK ==="
git clone https://github.com/flutter/flutter.git -b stable --depth 1 _flutter
export PATH="$PWD/_flutter/bin:$PATH"

echo "=== 2. Running Flutter Doctor ==="
flutter doctor -v

echo "=== 3. Getting Dependencies ==="
flutter pub get

echo "=== 4. Building Web for Production ==="
flutter build web --release \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY"

echo "=== Build Completed Successfully ==="
