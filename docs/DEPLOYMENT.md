# Deployment

Production settings live in `backend/config/settings/prod.py` (`DJANGO_SETTINGS_MODULE=config.settings.prod`). Everything here is additive on top of `base.py` — see `backend/.env.example` for the settings every environment needs (`SECRET_KEY`, `DATABASE_URL`, `REDIS_URL`, etc.).

## Processes

`backend/Procfile` defines four process types (works as-is on Heroku-style platforms; adapt the commands for systemd/supervisor elsewhere):

| Process | Command | Required? |
|---|---|---|
| `web` | `gunicorn config.wsgi:application --bind 0.0.0.0:$PORT` | Yes |
| `release` | `python manage.py migrate --noinput` | Yes, run once per deploy before `web` starts |
| `worker` | `celery -A config worker --loglevel=info` | Only if you want Celery-driven promotion expiry |
| `beat` | `celery -A config beat --loglevel=info` | Only alongside `worker` — this is what fires the hourly schedule |

`worker`/`beat` are optional: `prod.py` sets `CELERY_TASK_ALWAYS_EAGER = False` (unlike dev, which defaults to eager so Celery is optional locally), so without a running `worker`+`beat` pair, nothing expires promotions automatically. The simpler alternative is a plain cron entry instead of running Celery at all:

```bash
python manage.py expire_promotions  # hourly, via any scheduler
```

Static files are served by Gunicorn itself via Whitenoise (`whitenoise.middleware.WhiteNoiseMiddleware` + `CompressedManifestStaticFilesStorage`) — no separate static host or CDN is required. Run `python manage.py collectstatic --noinput` as part of your build step, before `release`.

## Required environment variables

Everything from `.env.example`, plus in production:

| Variable | Purpose |
|---|---|
| `ALLOWED_HOSTS` | Comma-separated real hostnames — `base.py` defaults this to empty, which fails closed. |
| `SECRET_KEY` | A real secret, not the `insecure-dev-key` default. |

## Optional: S3-compatible media storage

Unset, media (`ImageField` uploads — avatars, listing photos/thumbnails, agency logos) is stored on local disk under `backend/media/`, which does not survive a redeploy on most PaaS platforms. Set `AWS_STORAGE_BUCKET_NAME` to switch to `django-storages`' S3 backend for anything S3-API-compatible (AWS S3, DigitalOcean Spaces, Cloudflare R2, MinIO, ...):

| Variable | Notes |
|---|---|
| `AWS_STORAGE_BUCKET_NAME` | Presence of this variable is what flips `prod.py` over to S3 — leave unset to keep local disk. |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | Credentials scoped to that bucket only. |
| `AWS_S3_REGION_NAME` | e.g. `us-east-1`. |
| `AWS_S3_ENDPOINT_URL` | Only needed for a non-AWS S3-compatible provider (Spaces, R2, MinIO). |
| `AWS_S3_CUSTOM_DOMAIN` | Only if serving media through a CDN/custom domain in front of the bucket. |

## Optional: Sentry

Set `SENTRY_DSN` to enable error reporting (`sentry-sdk` + its Django integration). Unset, `prod.py` skips initialization entirely — no crash, just no reporting. `SENTRY_TRACES_SAMPLE_RATE` (default `0.1`) and `SENTRY_ENVIRONMENT` (default `production`) are optional tuning knobs.

## Security headers already on by default in `prod.py`

`SECURE_SSL_REDIRECT`, HSTS (1 year, subdomains, preload), secure session/CSRF cookies, `X-Content-Type-Options: nosniff`, and a `same-origin` referrer policy. `SECURE_PROXY_SSL_HEADER` is set to trust `X-Forwarded-Proto` — **only deploy behind a reverse proxy/load balancer that sets this header itself** (nginx, most PaaS platforms do this automatically); if a client could set that header directly and reach Django unproxied, this setting would let them spoof "https" and defeat the SSL redirect.

## Rate limits (also apply outside prod, see `config/settings/base.py`)

`auth` (register/login/OTP request+verify) 5/min per IP, `events` (view/call/whatsapp/share logging) 60/min, `geo` (place search + reverse geocode) 30/min. `/neighborhoods/` and `/listings/map/` responses are cached for 60s (Redis-backed, via `CACHES["default"]`) regardless of environment.

## Dev-only: request profiling

`django-silk` is wired into `config/settings/dev.py` only (`INSTALLED_APPS`, middleware, and `/silk/` in `config/urls.py`, guarded by `"silk" in settings.INSTALLED_APPS`) — it never loads under `prod.py`. Visit `/silk/` on a local `runserver` to inspect slow queries/N+1s.
