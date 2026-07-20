@echo off
setlocal

REM Read .env file
for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
  set "%%a=%%b"
)

flutter run --dart-define=SUPABASE_URL="%SUPABASE_URL%" --dart-define=SUPABASE_ANON_KEY="%SUPABASE_ANON_KEY%"
