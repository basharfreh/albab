# الباب العقاري — Al-Bab Real Estate

Real-estate marketplace for the single city of الباب (Al-Bab), Syria. See [`docs/00_AGENT_BRIEF.md`](docs/00_AGENT_BRIEF.md) for the full product brief and [`docs/01_PHASES.md`](docs/01_PHASES.md) for the build plan. Deploying the backend? See [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md).

## Layout

```
al-bab/
├─ backend/        # Django 5 + DRF API
├─ apps/
│  ├─ mobile/      # Flutter — Android + iOS
│  └─ dashboard/   # Flutter Web — admin only
├─ packages/
│  └─ albab_core/  # shared Dart: api client, models, theme, l10n, widgets
└─ docs/
```

## Backend setup

```bash
docker compose up -d
cd backend
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements/dev.txt
cp .env.example .env
make migrate
make run
```

Serves `http://localhost:8000/api/v1/health/` and Swagger UI at `http://localhost:8000/api/docs/`.

Useful targets: `make migrate`, `make makemigrations`, `make test`, `make lint`, `make format`, `make seed`, `make check`.

## Flutter setup

```bash
cd packages/albab_core
flutter pub get
flutter gen-l10n                              # regenerate lib/l10n/app_localizations*.dart from the ARB files
dart run build_runner build --delete-conflicting-outputs   # regenerate *.freezed.dart / *.g.dart models
flutter analyze
flutter test

cd example && flutter pub get && flutter analyze && flutter test   # the widget gallery

cd ../../../apps/mobile && flutter pub get && flutter analyze
cd ../dashboard && flutter pub get && flutter analyze
```

Only re-run `gen-l10n`/`build_runner` after editing an `.arb` file or a `@freezed`/`@JsonSerializable` class — both are checked-in generated output, not run on every `pub get`.

Run the mobile app against a local backend:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api/v1
```

View the shared widget gallery (`packages/albab_core/example`) in a browser:

```bash
cd packages/albab_core/example && flutter run -d chrome
```

## Contributing (for agents)

Read `docs/00_AGENT_BRIEF.md` in full every session, then execute exactly one phase from `docs/01_PHASES.md`. Append your entry to `docs/PROGRESS.md` before finishing.
