# الباب العقاري — Agent Brief (paste at the start of EVERY session)

> This file is context, not a task. The task comes from `01_PHASES.md`.
> Read this fully, then execute only the phase you were given.

---

## 1. Product

**الباب العقاري (Al-Bab Real Estate)** — a real-estate marketplace for the single city of **الباب (Al-Bab), Syria**.
Owners and agencies list houses, apartments, shops and land for sale or rent. Seekers browse a map, filter, and contact the owner directly by **phone call or WhatsApp** — the app does not broker or take payment for deals. Admins moderate listings and sell promotion (featured) packages.

Non-negotiable product facts, taken from the approved mockup:

- **Arabic-first, RTL.** English is a secondary locale. Every screen must be designed RTL-first.
- **The map is the home screen**, not a list.
- **Guest mode is real.** Browsing, searching, viewing a listing and calling the owner all work without an account. Auth is required only for: favorites, messages, notifications, publishing a listing, account.
- Prices are in **USD** (`$85,000`), with a `negotiable` flag ("قابل للتفاوض").
- The location vocabulary is **neighborhood + landmark** ("حي الحسين - قرب جامع النور"), not street addresses.
- Contact is **owner-direct**: a WhatsApp button and a Call button on every listing.

---

## 2. Actors and permissions

| Actor | Arabic | Can |
|---|---|---|
| Guest | زائر | Browse map/list, search, filter, open listing, call/WhatsApp owner |
| Seeker | مستخدم | Guest + favorites, in-app messages, notifications, profile |
| Owner | مالك عقار | Seeker + create/edit/delete own listings, view own listing stats |
| Agency | مكتب عقاري | Owner + higher listing quota, agency profile (name, logo, phone), bulk view |
| Admin | مشرف | Moderate listings, manage users, promotions, transactions, abuse reports, settings |

`Owner` and `Agency` differ only by quota and profile fields. Do **not** build two separate models for them — one `User.role` field.

---

## 3. Use case catalog

Each use case has an ID. Phases reference these IDs; never invent a feature that has no ID here.

**Auth & identity**
- `UC-01` Continue as guest ("متابعة كضيف") — enter the app with no account
- `UC-02` Register with phone + name + password, choose role (seeker / owner / agency)
- `UC-03` Log in with phone + password
- `UC-04` Verify phone by OTP (pluggable provider; console backend in dev)
- `UC-05` Switch app language ar ⇄ en, persisted
- `UC-06` View / edit own profile (name, phone, avatar, agency fields)
- `UC-07` Log out ("تسجيل الخروج")

**Discovery**
- `UC-10` Browse listings on a map with type-colored pins, clustered when dense
- `UC-11` Tap a pin → peek card at the bottom (photo, title, neighborhood + landmark, price, area, beds, baths, photo count)
- `UC-12` Free-text search of properties and places ("ابحث عن عقار أو موقع")
- `UC-13` Filter: sale/rent toggle, property type, neighborhood, price range, area range, bedrooms — with a **live result count** on the apply button ("عرض النتائج (125)")
- `UC-14` Browse the same results as a scrollable list
- `UC-15` View listing detail: gallery with counter (1/15), sale/rent + type badges, price + negotiable, area / bedrooms / bathrooms stats row, description, owner block
- `UC-16` Call the owner (`tel:`)
- `UC-17` Message the owner on WhatsApp (`wa.me` with a prefilled Arabic message naming the listing)
- `UC-18` Add / remove favorite ("المفضلة")
- `UC-19` Share a listing (deep link)
- `UC-20` Report an inappropriate listing

**Supply (owner side)**
- `UC-30` Create a listing through a 4-step wizard: المعلومات → الموقع → الصور → مراجعة
- `UC-31` Step 1 — title, type, sale/rent, price, bedrooms & bathrooms steppers, description
- `UC-32` Step 2 — pick the exact point by dragging the map under a fixed center pin, with place search; neighborhood is derived from the point and confirmable
- `UC-33` Step 3 — upload up to 15 photos, reorder, set cover
- `UC-34` Step 4 — review everything, submit for moderation
- `UC-35` My listings ("عقاراتي") — list with status, edit, delete
- `UC-36` Change listing status: mark sold / rented / paused / republish
- `UC-37` View own listing stats ("إحصائيات مشاهدات عقاراتي") — views and contacts per day
- `UC-38` Request a promotion (featured placement) for a listing

**Engagement**
- `UC-40` In-app conversation per (listing, seeker) pair, with unread badge
- `UC-41` Notifications list with unread badge (listing approved/rejected, new message, promotion expiring)
- `UC-42` Push notifications (deferred to the last phase; the model and endpoints exist earlier)

**Admin dashboard (Flutter Web)**
- `UC-50` KPI row: total users, total listings, listings for sale, listings for rent
- `UC-51` Visits chart, last 30 days
- `UC-52` Listings-by-type pie
- `UC-53` Latest added listings table + most viewed listings table
- `UC-54` Moderate listings: queue of `pending`, approve / reject with reason
- `UC-55` Manage users: search, view, change role, block/unblock
- `UC-56` Manage promotions ("الإعلانات"): packages, active promotions
- `UC-57` Manage transactions ("المعاملات"): manually recorded payments for promotions
- `UC-58` Abuse reports queue ("التقارير")
- `UC-59` Settings: neighborhoods, property types, quotas, static content

---

## 4. How the use cases connect

```
                    UC-01 guest ──────────────┐
UC-02/03 auth ──► session ──────────────────┐ │
                                            ▼ ▼
                                     UC-10 map home ◄──── UC-12 search
                                            │                  ▲
                                   UC-11 peek card             │
                                            │             UC-13 filter ──► UC-14 list
                                            ▼
                                     UC-15 detail
                            ┌───────────────┼───────────────┬─────────────┐
                            ▼               ▼               ▼             ▼
                     UC-16 call      UC-17 whatsapp   UC-18 favorite  UC-40 message
                            └──────── contact event ──────┘                │
                                            │                              ▼
                                            ▼                        UC-41 notify
                                     UC-37 owner stats

owner: UC-30 wizard (UC-31 → UC-32 → UC-33 → UC-34) ──► status=pending
                                            │
                                            ▼
                          UC-54 admin approve ──► status=published ──► visible in UC-10/13/14
                                            │
                                            └── reject ──► UC-41 notification to owner

UC-38 promotion request ──► UC-57 transaction recorded ──► listing.is_featured ──► ranked first in UC-10/14
```

Two rules fall out of this graph and must hold everywhere:

1. **Nothing reaches discovery without `status=published`.** The wizard produces `pending`, moderation produces `published`.
2. **Every contact action is logged** (`call`, `whatsapp`, `message`), because owner stats (`UC-37`) and admin analytics (`UC-51`) both read from that log.

---

## 5. Screen inventory (from the mockup)

Mobile — `apps/mobile`:
1. Splash / welcome — logo, تسجيل الدخول, إنشاء حساب, متابعة كضيف, language globe
2. Login, Register (phone-first)
3. Map home — search bar + filter icon, bell, pins, bottom peek card, bottom nav
4. Results list
5. Search & filter sheet — البحث والتصفية
6. Listing detail
7. Add listing wizard (4 steps, stepper header)
8. Location picker — اختر موقع العقار
9. Account — حسابي (profile header + row list with badges)
10. My listings, Listing stats, Favorites, Messages, Conversation, Notifications, Settings

Bottom nav, in RTL order (right → left): **الرئيسية · الرسائل · [+ أضف عقار] · المفضلة · الحساب**.
The `+` is a raised circular FAB in the center of the bar. In LTR the order mirrors.

Dashboard — `apps/dashboard` (Flutter Web): dark navy left sidebar (in RTL it sits on the right) with الرئيسية · العقارات · المستخدمين · الإعلانات · المعاملات · الإشعارات · التقارير · الإعدادات, KPI cards, charts, tables.

---

## 6. Domain model

Django apps and the models they own. Field names are binding — the Flutter models are generated from this shape.

**`accounts`**
- `User(AbstractBaseUser)` — `phone` (unique, E.164, USERNAME_FIELD), `name`, `role` (`seeker|owner|agency|admin`), `avatar`, `is_phone_verified`, `agency_name`, `agency_logo`, `whatsapp_phone` (nullable, falls back to `phone`), `is_blocked`, `created_at`
- `OtpCode` — `phone`, `code_hash`, `purpose`, `expires_at`, `consumed_at`, `attempts`

**`catalog`**
- `Neighborhood` — `name_ar`, `name_en`, `slug`, `center_lat`, `center_lng`, `is_active`, `sort_order`
- `Listing` — `owner` FK, `title`, `description`, `property_type` (`house|apartment|shop|land|other`), `purpose` (`sale|rent`), `price` (Decimal), `currency` (default `USD`), `is_negotiable`, `area_sqm`, `bedrooms`, `bathrooms`, `neighborhood` FK, `landmark` (text, e.g. "قرب جامع النور"), `lat`, `lng`, `status` (`draft|pending|published|rejected|sold|rented|paused`), `rejection_reason`, `views_count`, `contacts_count`, `is_featured`, `featured_until`, `published_at`, `created_at`, `updated_at`
- `ListingImage` — `listing` FK, `image`, `thumbnail`, `sort_order`, `is_cover`
- `Favorite` — `user`, `listing`, unique together

**`engagement`**
- `Conversation` — `listing`, `seeker`, `owner`, `last_message_at`, unique on (`listing`,`seeker`)
- `Message` — `conversation`, `sender`, `body`, `read_at`, `created_at`
- `Notification` — `user`, `kind`, `title`, `body`, `data` (JSON), `read_at`
- `DeviceToken` — `user`, `token`, `platform`

**`analytics`**
- `ListingEvent` — `listing`, `kind` (`view|call|whatsapp|message|share`), `user` (nullable), `ip_hash`, `created_at`
- `ListingDailyStat` — `listing`, `date`, `views`, `contacts` (rolled up nightly + on write)

**`moderation`**
- `ListingReport` — `listing`, `reporter`, `reason`, `note`, `status` (`open|closed`), `handled_by`
- `ModerationAction` — `listing`, `admin`, `action`, `reason`, `created_at`

**`billing`**
- `PromotionPackage` — `name_ar`, `name_en`, `days`, `price`, `is_active`
- `Promotion` — `listing`, `package`, `starts_at`, `ends_at`, `status`
- `Transaction` — `user`, `promotion`, `amount`, `currency`, `method` (`cash|manual`), `reference`, `status`, `recorded_by`

No payment gateway. Transactions are recorded by an admin by hand.

**Listing lifecycle**

```
draft ──submit──► pending ──approve──► published ──┬──► sold
  ▲                  │                             ├──► rented
  └──── edit ────────┘                             └──► paused ──republish──► pending
                     └──reject──► rejected ──edit──► pending
```

---

## 7. Stack and repo layout

**Backend** — Python 3.12, Django 5, Django REST Framework, `djangorestframework-simplejwt`, `django-filter`, PostgreSQL 16, Pillow, `django-cors-headers`, `drf-spectacular`, Celery + Redis (only from the phase that needs it).

**No PostGIS.** Al-Bab is one city; store `lat`/`lng` as `DecimalField` and filter by bounding box with plain `__range` lookups plus an index on `(lat, lng)`. Do not add GeoDjango, GDAL, or a spatial database.

**Maps** — `flutter_map` + OpenStreetMap raster tiles. **Not** Google Maps: billing and API availability are unreliable for Syria, and `flutter_map` runs identically on mobile and web. Geocoding/place search uses Nominatim through a **backend proxy endpoint** (server-side cache + user-agent, never called directly from the client).

**Flutter** — Flutter 3.2x stable, Dart 3, `flutter_riverpod` for state, `go_router` for routing, `dio` for HTTP, `freezed` + `json_serializable` for models, `flutter_secure_storage` for tokens, `cached_network_image`, `url_launcher`, `image_picker`, `intl` + `flutter_localizations` with ARB files.

```
al-bab/
├─ backend/
│  ├─ config/                 # settings/{base,dev,prod}.py, urls.py, celery.py
│  ├─ apps/{accounts,catalog,engagement,analytics,moderation,billing,common}/
│  ├─ requirements/{base.txt,dev.txt}
│  ├─ manage.py
│  └─ Makefile
├─ apps/
│  ├─ mobile/                 # Flutter — Android + iOS
│  └─ dashboard/              # Flutter Web — admin only
├─ packages/
│  └─ albab_core/             # shared Dart: api client, models, theme, l10n, common widgets
├─ docs/
│  ├─ 00_AGENT_BRIEF.md       # this file
│  ├─ 01_PHASES.md
│  ├─ API.md                  # kept current by backend phases
│  └─ PROGRESS.md             # every agent appends here before finishing
└─ docker-compose.yml         # postgres, redis, backend
```

`apps/mobile` and `apps/dashboard` depend on `packages/albab_core` by relative path:

```yaml
dependencies:
  albab_core:
    path: ../../packages/albab_core
```

Flutter code layout is **feature-first, two layers only** — `data/` (models, repository) and `ui/` (screens, widgets, providers). Do not add a `domain/` layer, use-case classes, or an abstract repository interface with a single implementation.

```
lib/
├─ main.dart
├─ app.dart              # MaterialApp.router, theme, locale
├─ router.dart
└─ features/
   └─ listings/
      ├─ data/listing_repository.dart
      └─ ui/{map_home_screen.dart, listing_detail_screen.dart, widgets/}
```

---

## 8. API conventions

- Base path `/api/v1/`. JSON only. `snake_case` keys.
- JWT in `Authorization: Bearer <access>`; refresh at `/api/v1/auth/refresh/`.
- Pagination: `PageNumberPagination`, `?page=`, `?page_size=` (max 50), response `{count, next, previous, results}`.
  The filter screen's live count (`UC-13`) reads `count` from a `page_size=1` request — **do not add a separate count endpoint.**
- Errors: `{"detail": "..."}` for single errors, `{"field": ["..."]}` for validation. Every message must have an Arabic translation available through Django's i18n.
- Timestamps ISO-8601 UTC. Money as a decimal string (`"85000.00"`), never a float.
- `drf-spectacular` schema at `/api/schema/`, Swagger UI at `/api/docs/`. Every new endpoint gets a docstring and correct serializer annotations.

Endpoint surface (phases fill it in; the paths are fixed):

```
POST   /auth/register/            POST /auth/login/           POST /auth/refresh/
POST   /auth/otp/request/         POST /auth/otp/verify/
GET    /auth/me/                  PATCH /auth/me/

GET    /neighborhoods/
GET    /listings/                 # filters below
GET    /listings/map/             # light marker payload: id, lat, lng, property_type, purpose, price
GET    /listings/{id}/
POST   /listings/                 PATCH /listings/{id}/       DELETE /listings/{id}/
POST   /listings/{id}/submit/     POST  /listings/{id}/status/
POST   /listings/{id}/images/     DELETE /listings/{id}/images/{image_id}/   POST /listings/{id}/images/reorder/
POST   /listings/{id}/events/     # {kind: view|call|whatsapp|share} — anonymous allowed, throttled
POST   /listings/{id}/report/
GET    /me/listings/              GET /me/listings/stats/?days=30
GET    /favorites/                POST /favorites/            DELETE /favorites/{listing_id}/
GET    /conversations/            POST /conversations/
GET    /conversations/{id}/messages/                          POST /conversations/{id}/messages/
GET    /notifications/            POST /notifications/read-all/
GET    /geo/search/?q=            # Nominatim proxy, cached
GET    /geo/reverse/?lat=&lng=    # returns nearest neighborhood

GET    /admin/kpis/               GET /admin/analytics/visits/?days=30       GET /admin/analytics/by-type/
GET    /admin/listings/?status=pending
POST   /admin/listings/{id}/approve/   POST /admin/listings/{id}/reject/
GET    /admin/users/              POST /admin/users/{id}/block/   POST /admin/users/{id}/role/
GET    /admin/promotions/         POST /admin/promotions/
GET    /admin/transactions/       POST /admin/transactions/
GET    /admin/reports/            POST /admin/reports/{id}/close/
```

`GET /listings/` filters: `purpose`, `property_type`, `neighborhood`, `min_price`, `max_price`, `min_area`, `max_area`, `bedrooms` (n = exactly, `n+` = at least), `bathrooms`, `q`, `bbox=minLng,minLat,maxLng,maxLat`, `ordering` (default `-is_featured,-published_at`).

---

## 9. Design tokens

Extracted from the approved mockup. These are **fixed**. Do not introduce a color, radius or font that is not listed here; if a state needs one, derive it from these.

```dart
// packages/albab_core/lib/theme/app_colors.dart
primary        #1B8B4C   // brand green: primary buttons, active nav, price text, sliders
primaryDark    #0F6B39   // pressed state
primaryTint    #E8F5EE   // selected chips, icon backgrounds, toggle track
navy           #1B2A41   // dashboard sidebar, marketing panels
surface        #FFFFFF
background     #F4F6F8   // app scaffold, dashboard canvas
border         #E4E7EB
textPrimary    #1A1D22
textSecondary  #6B7280
textMuted      #9AA1AC
danger         #E14B4B   // unread badges, destructive actions, rejected status
warning        #F0A030
```

Property-type pin colors (map legend and the by-type pie must use the same map):

```
house #1B8B4C · apartment #F0A030 · shop #3B82F6 · land #8B5CF6 · other #6B7280
```

- **Type**: `Cairo` for Arabic and Latin alike, from Google Fonts, bundled as an asset — not fetched at runtime. Weights 400 / 600 / 700 only.
  Scale: display 24/700, title 20/700, section 16/600, body 14/400, label 13/600, caption 12/400. Line height 1.5 for Arabic body text.
- **Radius**: 16 cards and sheets, 12 buttons and inputs, 999 chips and the FAB.
- **Spacing**: 4-point scale — 4, 8, 12, 16, 20, 24, 32. Screen horizontal padding 16.
- **Elevation**: one shadow only — `0 2 8 rgba(16,24,40,0.06)`. Cards on the background get it; sheets get it inverted upward. Nothing else casts a shadow.
- **Buttons**: filled green, full width, height 48, radius 12, weight 600. Secondary is an outlined button with the same metrics and a `border` stroke. Never two filled greens side by side except the Call/WhatsApp pair on the detail screen, which is deliberate.
- **Icons**: outline style, 22px in nav and lists, 20px inline. Filled variant only for the active nav item and an active favorite.

**RTL rules**
- `MaterialApp` locale defaults to `ar`, `supportedLocales: [ar, en]`, and the whole tree is direction-aware.
- Use `EdgeInsetsDirectional` and `start`/`end` everywhere. A raw `EdgeInsets.only(left:)` in a layout is a defect.
- Numbers, prices, phone numbers and dates stay **LTR** inside Arabic text — wrap them in `Directionality(textDirection: TextDirection.ltr, ...)` or format with `intl` so `$85,000` and `+963 987 654 321` never reorder.
- Icons that imply direction (back arrow, chevrons) must flip; logos, media controls and the map must not.
- Every user-visible string comes from ARB files. **No hardcoded strings in widgets, Arabic or English.**

**Copy voice** — plain, direct Arabic in sentence case. Buttons say what happens: `تأكيد الموقع`, `عرض النتائج (125)`, `التالي`. Empty states point to the next action ("لا توجد عقارات في هذه المنطقة — جرّب توسيع البحث"). Errors say what failed and what to do, and never apologize.

---

## 10. Conventions and definition of done

**Backend**
- `ruff` + `black`, line length 100. Type hints on function signatures.
- Fat serializers/services, thin views. ViewSets only where they earn it; plain `APIView` is fine.
- Every model change ships with its migration in the same commit.
- `pytest` + `pytest-django` + `factory_boy`. Minimum: one test per endpoint covering the happy path and one permission failure.
- Permissions are explicit per view. Default `IsAuthenticated`; read-only discovery endpoints are `AllowAny`.

**Flutter**
- `flutter analyze` clean, `dart format` applied.
- Riverpod: `Notifier`/`AsyncNotifier` providers. No `setState` for anything crossing a widget boundary, no global singletons besides the DI container.
- Every screen handles four states: loading (skeleton, not a bare spinner where a shape is known), empty, error with retry, data.
- Widgets over 150 lines get split. Files over 300 lines get split.
- No business logic in `build()`.

**Every agent, before finishing a phase, must:**
1. Run the checks (`make check` in `backend/`, `flutter analyze` in each Flutter package).
2. Update `docs/API.md` if endpoints changed.
3. Append a dated entry to `docs/PROGRESS.md`: phase, files added/changed, decisions taken, anything left for the next agent.
4. Print the exact commands to run the result.

**Hard rules for agents**
- Do only the phase you were assigned. If you notice work belonging to a later phase, write it in `PROGRESS.md` — do not build it.
- Do not rename anything defined in this brief (models, fields, endpoints, tokens).
- Do not add a package that is not listed in §7 without recording the reason in `PROGRESS.md`.
- Do not invent screens or features that lack a UC id.
- Prefer boring, readable code. No abstraction with one implementation, no premature caching, no clever metaprogramming.
- All seed and demo data is Arabic, from Al-Bab: neighborhoods حي الحسين، حي الزهراء، حي المشلب، حي الصناعة، and realistic USD prices.
