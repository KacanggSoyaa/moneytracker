# Money Tracker

A local-first expense & income tracker built with Flutter. All data stays on your device (SQLite) — no accounts, no cloud.

## Features

- **Home** — balance, month switcher, budget status, top categories, recent transactions
- **Transactions** — grouped by day, income/expense filter, add / edit / delete
- **Insights** — 6-month income/expense bar chart, spending donut chart, per-category monthly budgets
- **Settings** — currency (19 symbols), light/dark/auto theme, custom categories, CSV backup & restore

## Tech stack

- Flutter (Dart) + Material 3
- SQLite via `sqflite` (native), `sqflite_common_ffi_web` (browser)
- `fl_chart` for charts, `provider` for state management
- Money stored as integer cents to avoid float rounding

## Requirements

- Flutter SDK (any modern 3.x) with the **Android toolchain** configured
- For web runs: just a browser

## Running

Commands below assume `flutter` is on your PATH (it is, on this machine).

**Android phone / emulator** (device connected with USB debugging):
```
flutter run
```

**Chrome** (fast iteration with hot reload):
```
flutter run -d chrome
```
- `r` hot-reload, `R` full restart, `q` quit
- Note: browser data is stored in IndexedDB and is tied to the served port (localhost:8080 vs 8081 are separate databases)

**Prebuilt APK** (no dev machine needed to install):
`build\app\outputs\flutter-apk\app-debug.apk`

## Builds

```
flutter analyze   # static analysis
flutter test      # unit tests
flutter build apk --debug     # Android debug APK
flutter build web --release   # web bundle -> build/web
```

Serve the web build locally:
```
npx http-server build/web -p 8080 -c-1
```

## Project layout

```
lib/
  main.dart                  # entry point (web DB factory init)
  app.dart                   # MaterialApp + theming
  theme.dart                 # light/dark theme (teal seed)
  models/                    # Category, AppTransaction, Budget, AppSettings
  data/app_database.dart     # SQLite schema, seeds, queries
  providers/app_state.dart   # ChangeNotifier state
  services/                  # CSV backup (native file write + browser download)
  utils/                     # currency / date / icon helpers
  widgets/                   # shared UI pieces
  screens/                   # Home, Transactions, Insights, Settings, categories
```