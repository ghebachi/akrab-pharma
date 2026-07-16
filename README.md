<div align="center">

# أقرب فارما — Akrab Pharma

**The open-source duty pharmacy finder for Guelma, Algeria.**

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3FCF8E?style=for-the-badge&logo=supabase&logoColor=white)
![PostGIS](https://img.shields.io/badge/PostGIS-4A86C8?style=for-the-badge&logo=postgresql&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)
![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen?style=for-the-badge)

A modern, open-source mobile application built with **Flutter** and **Supabase** to locate the nearest active duty pharmacies in Guelma and across Algeria — powered by GPS geolocation and supported by the [OpenCode](https://opencode.ai) community.

تطبيق مفتوح المصدر حديث مبني بـ **Flutter** و **Supabase** لإيجاد أقرب صيدلية نشطة في ولاية قالمة وعبر الجزائر — بتقنية تحديد الموقع الجغرافي وبدعم من مجتمع [OpenCode](https://opencode.ai).

[**Screenshots**](#- screenshots) · [**Quick Start**](#-quick-start--البدء-السريع) · [**Report a Bug**](#-report-a-bug) · [**Contribute**](#-how-to-contribute--كيفية-المساهمة)

</div>

---

## About / المنvelope

Finding an open pharmacy late at night or during holidays shouldn't be a guessing game. **Akrab Pharma** puts real-time duty schedules at your fingertips — just open the app, and instantly see which pharmacies are on duty near you, complete with distance, contact info, and one-tap navigation.

> لا يجب أن يكون البحث عن صيدلية مفتوحة في الليل أو أثناء العطلات أمرًا عشوائيًا. **أقرب فارما** يضع جداول المناوبات الفورية في متناول يدك.

<br>

---

## Features / المميزات

| Feature | Description |
|:---|:---|
| 🌍 **GPS Distance Calculation** | Real-time distance computed server-side via PostgreSQL **PostGIS/Geography** RPC — no client-side math, no approximations. |
| 🎨 **Branded UI** | Clean Material Design interface with **Navy Blue** (`#1E3B8B`) and **Emerald Green** (`#10B981`) branding. |
| 💬 **WhatsApp Quick-Ask** | One-tap button to open a WhatsApp conversation with any pharmacy to verify stock or hours. |
| 🗺️ **Instant Navigation** | Google Maps integration launches driving directions directly to the selected pharmacy. |
| 📝 **Public Report System** | Users can flag closed pharmacies, wrong locations, or incorrect phone numbers — keeping data accurate for everyone. |
| 📅 **Dynamic Date Filter** | Browse duty schedules up to **90 days** ahead or into the past — perfect for planning ahead. |
| 🔒 **Row Level Security** | Supabase RLS policies ensure the public can only read, while admins control all writes. |

---

## Tech Stack / التقنيات المستخدمة

```
┌─────────────────────────────────────────────────┐
│                   FRONTEND                       │
│                                                  │
│  Flutter 3.x  ·  Dart 3.x                       │
│  Material Design 3  ·  url_launcher             │
│  geolocator (GPS)                                │
├─────────────────────────────────────────────────┤
│                   BACKEND                        │
│                                                  │
│  Supabase (PostgreSQL 15+)                       │
│  PostGIS (GEOGRAPHY, ST_Distance, GIST)         │
│  RPC Functions  ·  Row Level Security           │
│  Auth (JWT)                                      │
├─────────────────────────────────────────────────┤
│                   DEVOPS                         │
│                                                  │
│  GitHub  ·  Supabase CLI  ·  SQL Migrations     │
│  OpenCode Community                              │
└─────────────────────────────────────────────────┘
```

### Key dependencies / المكتبات الأساسية

| Package | Purpose |
|:---|:---|
| `supabase_flutter` | Supabase client for Dart/Flutter |
| `geolocator` | Cross-platform GPS location services |
| `url_launcher` | Open WhatsApp, Google Maps, and phone dialer |

---

## Quick Start / البدء السريع

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.x+)
- [Supabase CLI](https://supabase.com/docs/guides/cli)
- A [Supabase](https://supabase.com) project

### 1. Clone the repository

```bash
git clone https://github.com/ghebachi/akrab-pharma.git
cd akrab-pharma
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run database migrations

```bash
supabase db push
```

### 4. Configure environment

Create a `.env` file in the project root:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Initialize Supabase in your `main.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const AkrabPharmaApp());
}
```

### 5. Run the app

```bash
flutter run
```

---

## Database Schema / هيكل قاعدة البيانات

The backend is powered by three core tables and one RPC function:

```sql
pharmacies          →  id, name, address, municipality, phone,
                       whatsapp, location (GEOGRAPHY), created_at

duty_schedules      →  id, pharmacy_id (FK), duty_date, is_night_duty

user_reports        →  id, pharmacy_id (FK), report_type (ENUM), created_at

admin_users         →  user_id (FK → auth.users), created_at
```

**RPC Function:**
`get_nearest_duty_pharmacies(user_lat, user_lng, target_date)` — returns pharmacies on duty for the given date, sorted by distance from the user, including latitude/longitude for map navigation.

Full migration scripts are in [`supabase/migrations/`](supabase/migrations/).

---

## Screenshots / لقطات الشاشة

> _Screenshots coming soon! If you run the app, feel free to submit a PR with screenshots._

| Home (Nearby) | Pharmacy Card | Date Picker |
|:---:|:---:|:---:|
| _coming soon_ | _coming soon_ | _coming soon_ |

---

## Report a Bug / الإبلاغ عن خطأ

Found a wrong phone number, a closed pharmacy, or an incorrect location? Use the **in-app report button** — it's anonymous and helps keep the data accurate for the entire community.

هل وجدت رقم هاتف خاطئ، أو صيدلية مغلقة، أو موقعًا غير صحيح؟ استخدم **زر الإبلاغ في التطبيق** — الإبلاغ مجهول الهوية ويساعد في الحفاظ على دقة البيانات للمجتمع بأكمله.

For code bugs or feature requests, please [open an issue](https://github.com/ghebachi/akrab-pharma/issues).

---

## How to Contribute / كيفية المساهمة

We welcome contributions from everyone — especially Algerian developers in the **OpenCode** community! Whether you want to fix a bug, improve the UI, add new municipalities, or translate the app — your help is appreciated.

> نرحب بالمساهمات من الجميع — خاصة المطورين الجزائريين في مجتمع **OpenCode**! سواء أردت إصلاح خطأ، أو تحسين الواجهة، أو إضافة بلديات جديدة، أو ترجمة التطبيق — مساعدتك مقدرة.

### Steps / الخطوات

```text
1. Fork       →  Fork this repository to your GitHub account.
2. Branch     →  Create a feature branch: git checkout -b feat/my-feature
3. Code       →  Make your changes and test them locally.
4. Commit     →  Commit with a clear message: git commit -m "feat: add night duty filter"
5. Push       →  Push to your fork: git push origin feat/my-feature
6. PR         →  Open a Pull Request against the `main` branch.
```

### Contribution Ideas

- Add **night duty toggle** to filter day/night shifts
- Implement **pharmacy photos** and reviews
- Add **Arabic/ French/ Tamazight** full localization
- Write **unit and widget tests**
- Improve **accessibility** (screen readers, RTL)
- Add **push notifications** for upcoming duty schedules
- Expand coverage to **other Algerian provinces**

---

## Project Structure / هيكل المشروع

```
akrab-pharma/
├── lib/
│   ├── config/
│   │   └── app_colors.dart          # Brand theme & colors
│   ├── services/
│   │   └── gps_service.dart         # GPS permission & location
│   └── views/
│       └── home_screen.dart          # Main UI + pharmacy cards
├── supabase/
│   └── migrations/
│       ├── 20260716000000_initial_schema.sql
│       └── 20260716010000_add_latlng_to_rpc.sql
├── .gitignore
└── README.md
```

---

## License / الترخيص

This project is licensed under the **MIT License** — free to use, modify, and distribute.

هذا المشروع مرخص تحت **رخصة MIT** — مجاني للاستخدام والتعديل والتوزيع.

---

## Acknowledgements / الشكر

Built with ❤️ by the Algerian open-source community, powered by [OpenCode](https://opencode.ai).

> صنع بـ ❤️ من مجتمع المصادر المفتوحة الجزائري، بتقنية [OpenCode](https://opencode.ai).

<div align="center">

**If this project helps you, please give it a ⭐ — it motivates the community to keep building!**

**إذا كان هذا المشروع مفيدًا لك، يرجى إعطاءه نجمة ⭐ — هذا يحفز المجتمع على الاستمرار في البناء!**

</div>
