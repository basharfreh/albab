# API.md

Kept current by backend phases. Full interactive schema is served at `/api/docs/` (Swagger UI) and `/api/schema/` (OpenAPI) once the server is running.

## Base

- Base path: `/api/v1/`
- Auth: JWT in `Authorization: Bearer <access>`
- Pagination: `{count, next, previous, results}`, `?page=`, `?page_size=` (max 50)
- Errors: `{"detail": "..."}` for single errors, `{"field": ["..."]}` for validation
- Rate limits: `auth` (register/login/OTP request+verify) 5/min per IP, `events` (`/listings/{id}/events/`) 60/min, `geo` (search/reverse) 30/min — 429 on breach. Counters live in the shared Redis cache, so the limit is global across all app server processes, not per-process.
- Response caching: `GET /neighborhoods/` and `GET /listings/map/` are cached 60s (full URL incl. query string is the cache key), in every environment, not just prod.

## Endpoints

| Method | Path | Phase | Notes |
|---|---|---|---|
| GET | `/api/v1/health/` | P0 | `{"status": "ok", "version": "0.1.0"}`, `AllowAny` |
| POST | `/api/v1/auth/register/` | P1 | `{phone, name, password, role, agency_name?}` → created user (no tokens). `role` is one of `seeker\|owner\|agency` (not `admin`). `phone` accepts any Syrian format, normalized to E.164. `AllowAny` |
| POST | `/api/v1/auth/login/` | P1 | `{phone, password}` → `{access, refresh}` (SimpleJWT). Rejects `is_blocked` accounts. `AllowAny` |
| POST | `/api/v1/auth/refresh/` | P1 | `{refresh}` → `{access}` (rotation + blacklist enabled). `AllowAny` |
| POST | `/api/v1/auth/otp/request/` | P1 | `{phone, purpose}` → `{sent: true}` (+ `debug_code` when `DEBUG=True`). `purpose` is `register\|login\|password_reset`. 60s resend throttle → 429. `AllowAny` |
| POST | `/api/v1/auth/otp/verify/` | P1 | `{phone, purpose, code}` → `{verified: true}`; sets `is_phone_verified=True` on any user with that phone. 5-minute expiry, 5 attempts. `AllowAny` |
| GET / PATCH | `/api/v1/auth/me/` | P1 | Own profile. GET returns `MeSerializer` (id, name, role, avatar, agency_name, agency_logo, phone, whatsapp_phone, is_phone_verified). PATCH accepts multipart for `avatar`; `phone`/`role`/`is_phone_verified`/`id` are read-only. `IsAuthenticated` |
| GET | `/api/v1/neighborhoods/` | P2 | Active neighborhoods, unpaginated (small reference list). `AllowAny` |
| GET | `/api/v1/listings/` | P2 | Paginated, `status=published` only. Filters: `purpose`, `property_type`, `neighborhood` (id), `min_price`/`max_price`, `min_area`/`max_area`, `bedrooms` (`n` exact, `n+` at least), `bathrooms`, `q` (title/description/landmark/neighborhood name, icontains), `bbox=minLng,minLat,maxLng,maxLat`, `ordering` (`is_featured`/`published_at`, default `-is_featured,-published_at`). `ListingCardSerializer`. The filter screen's live count (UC-13) should call this with `page_size=1` and read `count`. `AllowAny` |
| GET | `/api/v1/listings/map/` | P2 | Same filters as above. Returns `{"results": [...], "truncated": bool}` — `results` capped at 500 markers, `ListingMapSerializer` (id, lat, lng, property_type, purpose, price only). `AllowAny` |
| GET | `/api/v1/listings/{id}/` | P2 | `ListingDetailSerializer` (adds description, full `images[]`, lat/lng, `owner` block, `created_at`). Visible if `published`, or if the requester is the owner (any status). `owner.whatsapp_phone` already falls back to `owner.phone` when unset. `AllowAny` |
| POST | `/api/v1/listings/` | P2 | Creates a `draft` owned by the requester. `ListingWriteSerializer` (no `owner`/`status` in the body). `IsAuthenticated` |
| PATCH | `/api/v1/listings/{id}/` | P2 | Owner only. Allowed while `draft\|rejected\|published`; 400 otherwise (e.g. `pending`). `IsAuthenticated` |
| DELETE | `/api/v1/listings/{id}/` | P2 | Owner only, any status. `IsAuthenticated` |
| POST | `/api/v1/listings/{id}/submit/` | P2 | `draft\|rejected` → `pending`. Validates ≥1 image, price, lat/lng, neighborhood (per-field errors if missing) and the owner's quota (seeker 0 / owner 10 / agency 100 *active* — `pending`+`published`+`paused` — listings). `IsAuthenticated`, owner only |
| POST | `/api/v1/listings/{id}/status/` | P2 | `{status}` → one of `sold\|rented\|paused\|published`. Legal transitions only: `published→{sold,rented,paused}`, `paused→published`. Everything else (including reaching `pending`/`published`/`rejected` any other way) is out of scope here — moderation is P3. `IsAuthenticated`, owner only |
| POST | `/api/v1/listings/{id}/images/` | P2 | Multipart `image` (+ optional `is_cover`). Max 15/listing, 8MB, jpg/png/webp only. Generates an 800px WebP thumbnail. First image auto-cover. `IsAuthenticated`, owner only |
| DELETE | `/api/v1/listings/{id}/images/{image_id}/` | P2 | Owner only. Deleting the cover promotes the next image (by `sort_order`) to cover. |
| POST | `/api/v1/listings/{id}/images/reorder/` | P2 | `{order: [image_id, ...]}` (must be exactly the listing's image ids). Rewrites `sort_order`. `IsAuthenticated`, owner only |
| GET | `/api/v1/me/listings/` | P2 (fields added P10) | The requester's own listings, any status. Filter: `?status=`. `MyListingSerializer` — `ListingCardSerializer` plus `status`, `rejection_reason`, `views_count`, `contacts_count`, `created_at`, `published_at`, so the mobile "عقاراتي" screen's status chip / rejected-reason / views count and the stats screen's per-listing breakdown need no other endpoint. `IsAuthenticated` |
| GET | `/api/v1/favorites/` | P2 | The requester's favorited listings as `ListingCardSerializer`, unpaginated. `IsAuthenticated` |
| POST | `/api/v1/favorites/` | P2 | `{listing: id}` — 404 unless the listing is `published`. Idempotent (`get_or_create`). `IsAuthenticated` |
| DELETE | `/api/v1/favorites/{listing_id}/` | P2 | `IsAuthenticated` |
| GET | `/api/v1/geo/search/?q=` | P2 | Server-side Nominatim proxy (`/search`), viewbox-bounded to Al-Bab, 24h Redis cache, throttled (`geo` scope, 60/min ≈ 1/s). `AllowAny` |
| GET | `/api/v1/geo/reverse/?lat=&lng=` | P2 | Nearest **active** `Neighborhood` by haversine distance over neighborhood centers (204 if none active). This is what fills the wizard's neighborhood field. `AllowAny` |
| POST | `/api/v1/listings/{id}/events/` | P3 | `{kind: view\|call\|whatsapp\|share}`. Logs a `ListingEvent` and rolls it into `Listing.views_count`/`contacts_count` + `ListingDailyStat`. `view` is throttled to one per listing per ip-hash per hour (a throttled repeat still returns 201 but is a no-op). `call`/`whatsapp` count as contacts; `share` is logged only. `AllowAny` |
| POST | `/api/v1/listings/{id}/report/` | P3 | `{reason, note?}` → creates an open `ListingReport`. `IsAuthenticated` |
| GET | `/api/v1/me/listings/stats/?days=30` | P3 (channel split added P10) | `{series: [{date, views, contacts}, ...], totals: {views, contacts, by_channel: {call, whatsapp, message}}}`, summed across the requester's own listings. `by_channel` counts `ListingEvent`s directly (not `ListingDailyStat`, which has no per-kind breakdown) over the same `days` window. `IsAuthenticated` |
| GET / POST | `/api/v1/conversations/` | P3 | GET lists the requester's conversations (as seeker or owner). POST `{listing}` — `get_or_create`s a conversation for `(listing, requester)`; 400 if the requester owns the listing. `IsAuthenticated` |
| GET / POST | `/api/v1/conversations/{id}/messages/` | P3 | GET marks the counterpart's unread messages read as a side effect, then lists messages. POST `{body}` creates a message, bumps `last_message_at`, fires a `new_message` notification and a `message` analytics event. 403 if the requester isn't a participant. `IsAuthenticated` |
| GET | `/api/v1/notifications/` | P3 | The requester's notifications, newest first. `IsAuthenticated` |
| POST | `/api/v1/notifications/read-all/` | P3 | Marks every unread notification read. `IsAuthenticated` |
| POST | `/api/v1/notifications/{id}/read/` | P10 | Marks one notification read (idempotent), returns it. **Not in brief §8's fixed list** — added because P10's notifications screen needs "tap marks it read" distinct from the bulk "تعليم الكل كمقروء" app-bar action, and `read-all/` alone can't express that without a tap marking every other notification read too. `IsAuthenticated`, 404 on another user's notification. |
| GET / PATCH | `/api/v1/auth/me/` | P3 | Now also returns `unread_messages`/`unread_notifications` (computed from `engagement`). |
| GET | `/api/v1/admin/kpis/` | P3 | `{total_users, total_listings, for_sale, for_rent}`, each `{total, delta_30d}` — `delta_30d` is how many of that set were created in the last 30 days (no historical snapshot to diff against). `total_listings`/`for_sale`/`for_rent` count `published` listings only. `IsAdminRole` |
| GET | `/api/v1/admin/analytics/visits/?days=30` | P3 | Platform-wide `[{date, views, contacts}, ...]` for the last `days` days. `IsAdminRole` |
| GET | `/api/v1/admin/analytics/by-type/` | P3 | `[{property_type, count}, ...]` over `published` listings, for the by-type pie. `IsAdminRole` |
| GET | `/api/v1/admin/listings/?status=pending` | P3, ordering added P11, owner added P11 | The moderation queue, any status filter. `AdminListingSerializer` (`ListingDetailSerializer` + `status`, `rejection_reason`, `created_at`). `?ordering=` accepts `created_at`/`-created_at` (default) or `views_count`/`-views_count` — P11's dashboard home reuses this one endpoint for both "أحدث العقارات المضافة" (`?status=published&ordering=-created_at`) and "أكثر العقارات مشاهدة" (`?status=published&ordering=-views_count`) rather than adding two new endpoints outside brief §8's fixed list. `?owner=<user id>` filters to one user's listings — same reasoning, added for P11's المستخدمين row drawer. `IsAdminRole` |
| POST | `/api/v1/admin/listings/{id}/approve/` | P3 | `pending → published`, sets `published_at`, logs a `ModerationAction`, notifies the owner. 400 if not `pending`. `IsAdminRole` |
| POST | `/api/v1/admin/listings/{id}/reject/` | P3 | `{reason}` (required) — `pending → rejected`, logs a `ModerationAction`, notifies the owner. 400 if not `pending`. `IsAdminRole` |
| GET | `/api/v1/admin/users/` | P3 | `?role=` filter, `?q=` search on name/phone (icontains). `AdminUserSerializer`. `IsAdminRole` |
| POST | `/api/v1/admin/users/{id}/block/` | P3, reason added P11 | `{blocked: bool}` (default `true`), `{reason}` (optional) — sets `is_blocked` and `block_reason` (persisted while blocked; cleared on unblock). `IsAdminRole` |
| POST | `/api/v1/admin/users/{id}/role/` | P3 | `{role}` — one of the `UserRole` values. `IsAdminRole` |
| GET | `/api/v1/admin/reports/` | P3, `reporter` nested P11 | `?status=` filter. `reporter` is a nested `UserSerializer` (name/role/avatar) as of P11's التقارير screen — was a bare PK before, changed since the dashboard needs the reporter's name to display, not just their id. `IsAdminRole` |
| POST | `/api/v1/admin/reports/{id}/close/` | P3 | Sets `status=closed`, `handled_by=request.user`. `IsAdminRole` |
| GET / POST | `/api/v1/admin/promotions/` | P3 | Manages **`Promotion`** instances (a package applied to a listing), not `PromotionPackage` — see PROGRESS.md P3 decisions. POST `{listing, package}` creates one in `pending` status. `IsAdminRole` |
| GET / POST | `/api/v1/admin/transactions/` | P3 | POST `{user, promotion, amount, method, currency?, reference?, status?}` (`status` defaults to `completed`) records a manual payment; a `completed` transaction immediately activates its `Promotion` (`starts_at`/`ends_at`/`status=active`) and sets `listing.is_featured` + `featured_until`. `IsAdminRole` |

`PromotionPackage` (the catalog of purchasable packages, e.g. "7 days / $10") has no dedicated API endpoint yet — managed via Django admin. See PROGRESS.md.

More endpoints are added here as each phase implements them. See `01_PHASES.md` §8 in `00_AGENT_BRIEF.md` for the full fixed endpoint surface.
