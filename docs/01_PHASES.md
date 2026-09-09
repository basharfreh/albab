# الباب العقاري — Build Phases

Each phase below is one agent session. Paste `00_AGENT_BRIEF.md` first, then one phase block.
Phases in the same row of the dependency graph can run in parallel by different agents.

```
P0 scaffold
 ├─ P1 auth ──► P2 catalog ──► P3 engagement+admin API
 └─ P4 core package ──┬─► P5 auth UI ──► P6 map home ──► P7 filter ──► P8 detail
                      │                                   └────────────► P9 wizard
                      ├─────────────────────────────────► P10 account
                      └─────────────────────────────────► P11 dashboard
                                                              P12 hardening (last)
```

P4 can start as soon as P2's serializers are merged. P11 needs P3. P12 is always last.

---

## P0 — Repository scaffold

**Goal.** A running skeleton: Postgres up, Django answering, two Flutter apps and the shared package building, one `make` entrypoint.

**Do**
1. Create the layout in §7 of the brief.
2. `docker-compose.yml` with `postgres:16` (db `albab`) and `redis:7`. Backend runs on the host during development.
3. `backend/`: Django 5 project `config`, settings split `base/dev/prod`, env via `django-environ`, `.env.example` committed. Install DRF, simplejwt, django-filter, cors-headers, drf-spectacular, Pillow, psycopg. Empty apps under `apps/` with `apps.py` `name = "apps.<x>"`.
4. `apps/common/`: `models.py` with `TimeStampedModel`, `pagination.py` with `DefaultPagination` (page_size 20, max 50), `exceptions.py` with a DRF exception handler that always returns `{"detail": ...}` or field errors.
5. `backend/Makefile`: `run`, `migrate`, `makemigrations`, `test`, `lint`, `format`, `seed`, `check` (= lint + test).
6. `flutter create` for `apps/mobile` (org `sy.albab`, name `albab_mobile`), `apps/dashboard` (web only), and `flutter create --template=package packages/albab_core`. Wire the path dependency both ways.
7. `docs/API.md` and `docs/PROGRESS.md` stubs. `.gitignore`, `README.md` with setup commands.
8. `/api/v1/health/` returning `{"status":"ok","version":"0.1.0"}`.

**Done when.** `docker compose up -d && make migrate && make run` serves `/api/v1/health/` and `/api/docs/`; `flutter analyze` is clean in all three Dart packages.

**Not now.** Any model beyond `TimeStampedModel`. Any screen. CI.

---

## P1 — Backend: accounts and auth (UC-01…UC-07)

**Do**
1. `apps/accounts`: custom `User` per brief §6, `USERNAME_FIELD = "phone"`, `UserManager`. Set `AUTH_USER_MODEL` **before the first migration** — this is the last moment it is cheap.
2. Phone normalisation to E.164 for Syria (`0987654321` / `+963987654321` / `963987654321` → `+963987654321`) in `apps/accounts/utils.py`, applied in the serializer and in `create_user`.
3. Endpoints: register, login, refresh, `GET/PATCH /auth/me/`, avatar upload via multipart on `PATCH`.
4. JWT config: access 30 min, refresh 30 days, rotation on, blacklist app enabled.
5. OTP: `OtpCode` model, `request` and `verify` endpoints, 6 digits, 5-minute expiry, 5 attempts, 60-second resend throttle, hashed at rest. Provider interface `apps/accounts/otp/backends.py` with `ConsoleOtpBackend` (prints, and returns the code in the response when `DEBUG`) selected by `OTP_BACKEND` setting. No real SMS gateway yet.
6. `UserSerializer` (public: id, name, role, avatar, agency_name, agency_logo) vs `MeSerializer` (adds phone, whatsapp_phone, is_phone_verified). **Never expose another user's phone through `UserSerializer`** — phone reaches the client only inside a published listing's owner block (P2).
7. Django admin registration for `User`. Seed command `seed_users` creating one admin, one agency, two owners, two seekers.

**Done when.** Registering with `0987 654 321` then logging in with `+963987654321` works; `GET /auth/me/` returns the profile; tests cover register, duplicate phone, login failure, me-requires-auth, OTP verify and expiry.

**Not now.** Password reset by SMS, social login, roles beyond the enum, push tokens.

---

## P2 — Backend: catalog, search, favorites (UC-10…UC-19, UC-30…UC-36)

**Do**
1. Models `Neighborhood`, `Listing`, `ListingImage`, `Favorite` exactly as in brief §6. Indexes: `(status, published_at)`, `(lat, lng)`, `(purpose, property_type)`, `(neighborhood, status)`.
2. Image pipeline: on upload, save the original and generate an 800px-wide WebP thumbnail with Pillow in `apps/catalog/services/images.py`. Max 15 images per listing, max 8 MB each, jpg/png/webp only. First image is cover unless another is flagged.
3. `ListingFilterSet` (django-filter) covering every query param in brief §8. `bbox` is a custom filter splitting four floats and applying `lat__range` + `lng__range`. `q` searches `title`, `description`, `landmark`, `neighborhood__name_ar` (`icontains`, no full-text search yet). `bedrooms=3+` means `gte`.
4. Serializers: `ListingCardSerializer` (list — cover thumb, title, neighborhood name, landmark, price, is_negotiable, area, bedrooms, bathrooms, images_count, purpose, property_type, is_featured, is_favorited), `ListingDetailSerializer` (adds description, all images, lat/lng, owner block with name/avatar/phone/whatsapp_phone, created_at), `ListingMapSerializer` (id, lat, lng, property_type, purpose, price only — this endpoint must stay under ~120 bytes per marker and is capped at 500 markers, returning `{"truncated": true}` when the bbox holds more).
5. `is_favorited` is annotated per request, `False` for anonymous. Discovery endpoints use `AllowAny`; queryset is `status=published` for everyone except the owner reading their own.
6. Write flow: `POST /listings/` creates `draft`, `PATCH` edits while `draft|rejected|published`, `POST /listings/{id}/submit/` validates completeness (≥1 image, price, location, neighborhood) and moves to `pending`. `POST /listings/{id}/status/` accepts `sold|rented|paused|published` for the owner with legal transitions only, enforced in a `services/listing_status.py` transition table.
7. Quotas: seeker 0 active listings, owner 10, agency 100. Enforced on submit, message in Arabic.
8. `/me/listings/` with a `status` filter. `/favorites/` list/add/remove.
9. `/geo/search/` and `/geo/reverse/`: server-side Nominatim proxy, 24h cache in Redis, viewbox bounded to Al-Bab, descriptive User-Agent, 1 req/s throttle. `/geo/reverse/` returns the nearest active `Neighborhood` by haversine over the neighborhood centers — that is how the wizard fills the neighborhood field.
10. `seed_catalog`: the four Al-Bab neighborhoods with real center coordinates, plus 60 published listings with varied types, purposes, prices ($15k–$250k), areas, and scattered coordinates; images generated as flat-color placeholders.

**Done when.** `GET /listings/?purpose=sale&min_price=50000&bedrooms=3+&bbox=...` returns a correct `count` and page; the map endpoint returns markers for the same bbox; a draft cannot be submitted without an image; tests cover filters, permissions, quota, the status transition table, and image limits.

**Not now.** Messaging, notifications, analytics, promotions, moderation endpoints.

---

## P3 — Backend: engagement, analytics, moderation, admin API (UC-20, UC-37…UC-41, UC-50…UC-59)

**Do**
1. `apps/engagement`: `Conversation`, `Message`, `Notification`, `DeviceToken`. `POST /conversations/` is idempotent per (listing, seeker) and rejects an owner messaging their own listing. Messages mark read on fetch. Unread counts exposed on `GET /auth/me/` as `unread_messages` and `unread_notifications` — the account screen badges read from there.
2. `apps/analytics`: `POST /listings/{id}/events/` accepts `view|call|whatsapp|share` from anyone, throttled at 1 view per listing per IP-hash per hour (`ip_hash` = salted sha256, never store raw IP). Writing an event increments the denormalised `views_count`/`contacts_count` and upserts `ListingDailyStat`.
3. `GET /me/listings/stats/?days=30` → per-day series plus totals, for the owner's chart.
4. `apps/moderation`: `POST /listings/{id}/report/`, admin queue, `approve` (sets `published`, `published_at`, notifies owner) and `reject` (needs a reason, notifies owner). Every action writes a `ModerationAction`.
5. `apps/billing`: packages, promotions, manual transactions. Approving a transaction activates the promotion and sets `is_featured` + `featured_until`. A Celery beat task expires promotions hourly; a management command does the same so Celery stays optional in development.
6. Admin API under `/admin/` with an `IsAdminRole` permission class: KPIs (`total_users`, `total_listings`, `for_sale`, `for_rent`, each with a 30-day delta), visits series, by-type breakdown, latest listings, most viewed, user management, reports queue.
7. Notification creation lives in one place — `apps/engagement/services/notify.py` — with a `kind` enum. Push delivery is a no-op backend for now behind the same interface.

**Done when.** Approving a pending listing publishes it, notifies the owner, and makes it appear in `/listings/`; `/admin/kpis/` matches hand-counted seed data; posting the same view event twice within an hour increments once.

**Not now.** WebSockets/live chat (messages poll on a 15s interval), real push credentials, payment gateways.

---

## P4 — Flutter: shared core package

**Goal.** `packages/albab_core` — everything both apps share. No screens.

**Do**
1. `theme/`: `AppColors`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppTypography`, and `AppTheme.light()` building a `ThemeData` where the default `ElevatedButton`, `OutlinedButton`, `InputDecoration`, `Card`, `Chip` and `BottomNavigationBar` already match brief §9 — so screens rarely style anything locally. Bundle Cairo 400/600/700 as assets.
2. `l10n/`: `app_ar.arb` (source of truth) and `app_en.arb`, `flutter gen-l10n` wired, `ar` first in `supportedLocales`. Seed with every string already visible in the mockup.
3. `format/`: `Money.format(decimalString)` → `$85,000`; `Area.format(120)` → `120 م²`; `PhoneFormat.display(e164)` → `+963 987 654 321`; `RelativeTime.format(dt)` → `منذ 5 ساعات`. All LTR-safe inside Arabic text.
4. `api/`: `ApiClient` wrapping Dio — base URL from `--dart-define=API_BASE_URL`, JSON, 20s timeouts, an auth interceptor attaching the access token, a refresh interceptor that queues concurrent 401s and retries once, and an error mapper turning DRF responses into `ApiException(message, fieldErrors, statusCode)` with localised fallbacks.
5. `models/`: freezed + json_serializable for `User`, `Listing`, `ListingImage`, `Neighborhood`, `Conversation`, `Message`, `Notification`, `Paginated<T>`, plus the enums `PropertyType`, `ListingPurpose`, `ListingStatus`, `UserRole` — each enum carrying its wire value, its localisation key, its icon and (for `PropertyType`) its pin colour from brief §9.
6. `storage/`: `TokenStorage` on `flutter_secure_storage`, `PrefsStorage` for locale and onboarding flags.
7. `widgets/`: `PrimaryButton`, `SecondaryButton`, `AppTextField`, `AppDropdown`, `CounterField` (the −/+ stepper), `PriceRangeSlider`, `SectionHeader`, `AppBadge`, `EmptyState`, `ErrorState`, `LoadingSkeleton`, `ListingCard` (the peek/list card from the mockup), `PropertyStatsRow` (area · bedrooms · bathrooms). Each gets an entry in a `widgetbook_page.dart` gallery screen inside the package example so later phases can see them.
8. `providers/`: `apiClientProvider`, `authStateProvider` (`unknown | guest | authenticated(User)`), `localeProvider`.

**Done when.** The example app renders the widget gallery in both `ar` and `en` with correct direction, and no widget in the gallery contains a hardcoded string or hex colour.

**Not now.** Repositories for specific features, routing, any screen from §5.

---

## P5 — Mobile: auth flows and app shell (UC-01…UC-07)

**Do**
1. `go_router` with `/welcome`, `/login`, `/register`, `/verify`, and a `StatefulShellRoute` for the five tabs `/map`, `/messages`, `/add`, `/favorites`, `/account`. Redirect rules: guest may reach every tab, but tapping Messages, Favorites, Add or Account while unauthenticated opens a bottom sheet offering login/register and returns to the previous tab on dismiss.
2. Welcome screen exactly as the mockup: centred logo and Arabic tagline, filled `تسجيل الدخول`, outlined `إنشاء حساب`, plain-text `متابعة كضيف`, and a globe language toggle at the bottom that switches locale immediately.
3. Login (phone + password), Register (name, phone, password, role chips مالك عقار / مكتب عقاري / مستخدم, agency name when agency), OTP verify screen with 6 boxes, auto-advance, paste support and a resend countdown.
4. `AuthRepository` + `authStateProvider` writing tokens to `TokenStorage`; app boot restores the session and lands on `/map` for both guest and authenticated users.
5. The bottom nav bar from the mockup: five items, centre raised green circular `+`, active item green with a filled icon, RTL-ordered.

**Done when.** Cold start → guest → map; login persists across restart; logout returns to `/welcome`; wrong password shows the Arabic field error from the API.

**Not now.** Real content in any tab — placeholders are fine outside `/map`.

---

## P6 — Mobile: map home (UC-10, UC-11, UC-14)

**Do**
1. `flutter_map` with OSM tiles, initial camera centred on Al-Bab at zoom 14, min zoom 12, and a bounds constraint around the city.
2. Markers from `GET /listings/map/`, refetched on map-idle with a 400ms debounce, keyed by bbox and cached in memory for the session. Pin shape as in the mockup: a rounded teardrop in the type colour with a white glyph. Cluster when markers overlap, showing a count.
3. Tapping a pin selects it (enlarged pin) and slides up the peek card — `ListingCard` from core, in horizontal layout — which is dismissible and opens the detail route on tap.
4. Top overlay: search field with placeholder `ابحث عن عقار أو موقع`, a filter icon button on the leading edge showing a dot when filters are active, and a bell with the unread badge.
5. A list/map toggle. The list view reuses `GET /listings/` with the same active filters, infinite scroll, pull-to-refresh, and a "search this area" behaviour when the map bbox is applied.
6. Empty state when the visible area has nothing; error state with retry; skeleton cards while loading.
7. Fire the `view` event when a detail screen opens, not when a pin is tapped.

**Done when.** Panning refetches at most once per gesture; 500 seed markers render without dropping frames on a mid-range device; the same filter state drives both map and list.

**Not now.** The filter sheet UI (P7) — read filter state from a provider that P7 will populate.

---

## P7 — Mobile: search and filter (UC-12, UC-13)

**Do**
1. `FilterState` (freezed) as the single source of truth: `purpose`, `propertyType`, `neighborhood`, `priceMin/Max`, `areaMin/Max`, `bedrooms`, `bathrooms`, `query`, `bbox`. One provider, consumed by P6's map and list.
2. The filter screen from the mockup, top to bottom: segmented للبيع / للإيجار; نوع العقار dropdown; الحي dropdown from `GET /neighborhoods/`; السعر with two numeric fields (من / إلى) bound to a `RangeSlider`; المساحة the same; عدد الغرف as chips (الكل · 1 · 2 · 3 · 4 · +5). Fields and slider stay in sync in both directions.
3. Live count: debounce 350ms, request `GET /listings/?...&page_size=1`, and label the apply button `عرض النتائج (125)`. While in flight, keep the last count and show an inline spinner — never blank the number.
4. `إعادة تعيين` clears to defaults. Applying pops back and updates map + list together. Active filters persist for the session but not across restarts.
5. Search field: submitting sets `query`; recent searches stored locally, max 8, clearable. Place results from `/geo/search/` move the map camera instead of filtering.

**Done when.** Every control changes the count within one debounce; applying then reopening shows the same state; clearing restores the unfiltered count.

---

## P8 — Mobile: listing detail, contact, favorites, share, report (UC-15…UC-20)

**Do**
1. Detail screen matching the mockup: full-bleed gallery with `1/15` counter, back / share / favorite icon buttons floating over it, tap for a full-screen zoomable pager.
2. Body: badges (purpose then type), title, `location_on` + neighborhood − landmark, price in green with `قابل للتفاوض` beside it, then the three-column stats row (المساحة · غرف النوم · الحمامات) separated by hairline dividers, then `معلومات العقار` with the description, then the owner block (avatar, name, role badge, member-since).
3. Sticky bottom action bar with two filled buttons: `واتساب` opening `https://wa.me/<digits>?text=<encoded Arabic message naming the listing title and price>`, and `اتصال` opening `tel:`. Each posts its event to `/listings/{id}/events/` before launching. If no WhatsApp app is installed, fall back to the web URL.
4. Favorite toggles optimistically with rollback on failure; unauthenticated tap opens the login sheet.
5. Share produces a deep link `https://albab.sy/l/{id}` with a short Arabic caption. Register the app link scheme and handle cold-start deep links into the detail route.
6. `الإبلاغ عن هذا العقار` in an overflow menu → reason sheet → `POST /listings/{id}/report/` → confirmation snackbar.
7. A horizontal `عقارات مشابهة` strip: same neighborhood or type, price within ±30%, excluding the current listing.

**Done when.** Every element of the mockup detail screen is present, the two contact buttons work on a real device, and the view event fires once per screen open.

---

## P9 — Mobile: add-listing wizard (UC-30…UC-34, UC-38)

**Do**
1. Wizard shell with the 4-step header from the mockup (المعلومات · الموقع · الصور · مراجعة), completed steps in green with a check, current step outlined, future steps grey. Back gesture asks to save as draft.
2. Step 1: title with the hint `مثال: منزل في حي الحسين`, type dropdown, للبيع/للإيجار segmented, price with a `$` prefix and thousands separators while typing, `عدد الغرف` and `عدد الحمامات` counters, description with a counter to 1000. Per-field validation on blur, `التالي` disabled until valid.
3. Step 2: the location picker screen — a fixed centre pin over a draggable map with a soft accuracy circle, place search at the top, the hint `اسحب الخريطة وحدد الموقع بدقة`, and a `تأكيد الموقع` button. On confirm, call `/geo/reverse/` to fill the neighborhood, show it as an editable dropdown, and offer an optional landmark field prefilled from the reverse result.
4. Step 3: pick from gallery or camera, up to 15, client-side compression to ≤1600px / ~1MB before upload, per-image upload progress, retry on failure, drag to reorder, `تعيين كصورة رئيسية`, delete with undo.
5. Step 4: read-only summary of every field with an edit affordance jumping back to the right step, then `نشر العقار` → `submit` → a success screen explaining moderation (`سيتم مراجعة عقارك خلال 24 ساعة`) with buttons to view it or add another.
6. Draft persistence: the wizard writes a `draft` listing after step 1 and PATCHes afterwards, so images attach to a real id and an interrupted session resumes.
7. Quota rejection from the API renders as a friendly Arabic screen offering the agency upgrade, and a promotion request entry point (`UC-38`) on the success screen.

**Done when.** A fresh owner completes all four steps, the listing appears in `عقاراتي` as `قيد المراجعة`, and killing the app mid-wizard resumes from the same step.

---

## P10 — Mobile: account, my listings, stats, messages, notifications, settings (UC-06, UC-35…UC-37, UC-40, UC-41)

**Do**
1. Account screen exactly as the mockup: avatar, name, phone, role badge, then rows — عقاراتي (with count), المفضلة (count), الرسائل (red unread badge), الإشعارات (red badge), إحصائيات مشاهدات عقاراتي, الإعدادات, تسجيل الخروج in red. Guests see a sign-in prompt card instead of the profile header.
2. `عقاراتي`: status-tabbed list (الكل · منشور · قيد المراجعة · مرفوض · مباع/مؤجر), each row with a status chip, views count, and an overflow menu (تعديل · تمييز · تعليق · حذف). Rejected rows show the admin's reason inline.
3. Stats screen: a 30-day line chart of views plus totals for views and contacts split by channel, and a per-listing breakdown. Use `fl_chart`.
4. Favorites: grid of `ListingCard`, swipe to remove, empty state pointing to the map.
5. Messages: conversation list (counterpart avatar, listing thumbnail, last message, time, unread dot) and a chat screen with a listing header banner, bubbles, and 15-second polling while open. Sending is optimistic with a failed-state retry.
6. Notifications: grouped by day, unread highlighted, tapping routes by `kind` and marks read, `تعليم الكل كمقروء` in the app bar.
7. Settings: language, notification toggles, edit profile (name, avatar, WhatsApp number), change password, about, contact support, delete account with confirmation.

**Done when.** Badges match `/auth/me/`, every list has loading/empty/error states, and logging out clears secure storage and returns to `/welcome`.

---

## P11 — Dashboard: admin web app (UC-50…UC-59)

**Goal.** `apps/dashboard`, Flutter Web, admin-only, reusing `albab_core`.

**Do**
1. Shell: dark navy (`#1B2A41`) sidebar on the RTL start side with the brand lockup and the eight items from the mockup, collapsible under 1100px, a top bar with a search field, a bell and the admin avatar menu. Content canvas `#F4F6F8`, max width 1440, 24px gutters.
2. Login route restricted to `role=admin`; any other role gets a clear rejection, not a blank screen.
3. الرئيسية: four KPI cards (إجمالي المستخدمين · إجمالي العقارات · عقارات للبيع · عقارات للإيجار) with the 30-day delta; the `الزيارات خلال آخر 30 يوم` area chart; the `العقارات حسب النوع` pie using the pin colours; and the two tables `أحدث العقارات المضافة` and `أكثر العقارات مشاهدة` with `عرض الكل` links.
4. العقارات: server-side paginated data table with status/type/purpose/neighborhood filters and search; row click opens a detail drawer with the gallery, map point, owner and moderation history; approve and reject (reason required) act from the drawer and from bulk selection.
5. المستخدمين: table with role filter and search, row drawer showing their listings and activity, change role, block/unblock with a reason.
6. الإعلانات: promotion packages CRUD and active promotions with days remaining. المعاملات: recorded payments, filters by date and status, and a manual "record payment" dialog that activates a promotion.
7. الإشعارات: broadcast composer (all users / by role / one user) with an Arabic preview. التقارير: abuse queue with resolve/dismiss, plus CSV export of listings and users.
8. الإعدادات: neighborhoods CRUD (name ar/en, center point picked on a small map, active), quotas, and static content.
9. Web specifics: URL-driven routes so every table state is linkable, keyboard focus visible, tables horizontally scrollable rather than squeezed, and a real 404 route.

**Done when.** An admin approves a pending listing here and it appears in the mobile map within one refresh; every table paginates and filters server-side; a non-admin cannot reach any route.

---

## P12 — Hardening and release

**Do**
1. Backend: response caching for `/neighborhoods/` and `/listings/map/` (60s), `select_related`/`prefetch_related` audit with `django-silk` in dev, rate limits (auth 5/min per IP, events 60/min, geo 30/min), Sentry hookup, `prod.py` with `SECURE_*` headers, media on S3-compatible storage behind `django-storages`, Gunicorn + Whitenoise, deployment README.
2. Push notifications: swap the no-op backend for FCM, register `DeviceToken` on login, handle taps into deep routes.
3. Flutter: golden tests for `ListingCard`, `PropertyStatsRow` and the filter sheet in `ar` and `en`; widget tests for the wizard's validation; integration test for the guest → search → detail → call flow.
4. Accessibility and polish pass: semantic labels on icon buttons, 48dp touch targets, contrast check against the tokens, `MediaQuery.textScaler` up to 1.3 without overflow, reduced-motion respected.
5. Offline and failure behaviour: cached last map results, a connectivity banner, retry on every failed request, no infinite spinners.
6. Analytics review: confirm owner stats and admin KPIs agree on the same numbers.
7. Release: app icons and splash for both platforms, Arabic store listing, versioning, signed builds, dashboard deployed as static web.

**Done when.** `make check` and `flutter test` pass everywhere; a release build runs against staging with no debug flags.

---

## Session prompt template

```
Read docs/00_AGENT_BRIEF.md in full before doing anything.
You are executing Phase <N>: <title> from docs/01_PHASES.md.

Rules:
- Build only what that phase lists. Anything you notice outside it goes in docs/PROGRESS.md.
- Follow the naming in the brief exactly — models, fields, endpoints, tokens.
- Read docs/PROGRESS.md first to see what previous agents left you.

Finish by:
1. running the checks for what you touched,
2. updating docs/API.md if endpoints changed,
3. appending your entry to docs/PROGRESS.md,
4. printing the commands to run and verify your work.
```
