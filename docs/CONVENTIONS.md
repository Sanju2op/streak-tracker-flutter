# CONVENTIONS.md

> Rules for AI agents and developers. Read this alongside ARCHITECTURE.md at
> the start of every session.

---

## Session Startup (say this to your AI agent)

> "Read ARCHITECTURE.md and TASKS.md. Check the current task status and
> continue from where we left off. Open the relevant image in UI Images/
> before building any screen."

---

## Git Setup

The repo origin is `<https://github.com/Sanju2op/streak-tracker-flutter.git>`.
The Flutter project lives **directly at the repo root** — not in a subfolder.

### First-time setup (Windows 11)

```powershell
# initialize git locally
git init

# add remote repo
git remote add origin https://github.com/Sanju2op/streak-tracker-flutter.git

# add all files
git add .

# commit
git commit -m "Initial commit"

# set main branch and push
git branch -M main
git push -u origin main

# flutter setup
flutter pub get
flutter doctor -v
```

### Push changes

```powershell
git add .
git status          # verify before committing — see .gitignore rules below
git commit -m "feat: description of change"
git push origin main
```

### .gitignore — must include

```gitignore
# Flutter
build/
.dart_tool/
.flutter-plugins
.flutter-plugins-dependencies
*.apk
*.aab
*.ipa

# Signing keys — NEVER commit these
*.jks
*.keystore
key.properties

# IDE
.idea/
.vscode/
*.iml
```

---

## Windows 11 Environment Setup (One-Time)

AI agents: Run these in order. Verify each step before continuing.

### Step 1 — Install Flutter SDK (Stable)

```powershell
# Option A — Direct download (recommended)
# 1. Go to: https://docs.flutter.dev/get-started/install/windows
# 2. Download the Flutter SDK zip (stable channel)
# 3. Extract to C:\flutter  (no spaces or special chars in path)
# 4. Add to PATH: C:\flutter\bin
#    → System Properties → Environment Variables → Path → New → C:\flutter\bin

# Option B — winget
winget install FlutterSoftwareFoundation.Flutter

# Verify
flutter --version     # must satisfy pubspec.lock, currently 3.38.4 or later
flutter channel       # must show "stable"
```

### Step 2 — Install Android Studio + SDK

```powershell
# 1. Download: https://developer.android.com/studio
# 2. Install with default options
# 3. Open Android Studio → More Actions → SDK Manager
#    Install:
#      ✓ Android SDK (API 34 or latest)
#      ✓ Android SDK Build-Tools
#      ✓ Android SDK Platform-Tools
#      ✓ Android Emulator (optional — real device is faster)

# 4. Set environment variable:
#    ANDROID_HOME = C:\Users\ <YourName>\AppData\Local\Android\Sdk
#    Add to PATH: %ANDROID_HOME%\platform-tools

# 5. Accept all Android licenses
flutter doctor --android-licenses   # press y to accept each
```

### Step 3 — Install Chrome (for web testing)

```powershell
winget install Google.Chrome
# Or download from https://www.google.com/chrome/
```

### Step 4 — Verify Full Setup

```powershell
flutter doctor -v
```

Required green checks:

```text
[✓] Flutter (Channel stable, 3.38.4+)
[✓] Android toolchain
[✓] Chrome - develop for the web
```

Not required (Windows only):

```text
[!] Visual Studio  ← only needed for Windows desktop builds
```

### Step 5 — Get Project Dependencies

```powershell
cd streak-tracker
flutter pub get
```

### Step 6 — Connect Android Device

1. On your phone: Settings → About Phone → tap **Build Number** 7 times
2. Settings → Developer Options → enable **USB Debugging**
3. Connect via USB cable
4. Run: `flutter devices` — your phone should appear
5. If not showing: install Google USB drivers from Android Studio SDK Manager

---

## Running the App

```powershell
# On Android (connected device)
flutter run -d android

# In Chrome browser
flutter run -d chrome

# List all available devices
flutter devices

# Hot reload (while app is running)
r       # hot reload
R       # hot restart (full state reset)
q       # quit
```

---

## Building APKs

```powershell
# Debug APK — fast build, no signing needed, for sideloading/testing
flutter build apk --debug
# File: build\app\outputs\flutter-apk\app-debug.apk

# Release APK — optimized, requires signing config
flutter build apk --release
# File: build\app\outputs\flutter-apk\app-release.apk

# Install directly on connected device
flutter install
# Or via adb:
adb install build\app\outputs\flutter-apk\app-debug.apk
```

For release signing, generate a keystore (once):

```powershell
keytool -genkey -v -keystore streak-tracker-key.jks `
  -keyalg RSA -keysize 2048 -validity 10000 -alias streak-tracker
# Store the .jks file OUTSIDE the repo — never commit it
```

---

## Web Testing

```powershell
# Development (hot reload, Chrome)
flutter run -d chrome

# Production build
flutter build web --wasm --release

# Serve locally
cd build\web
python -m http.server 8080
# Open: http://localhost:8080
```

Note: Web uses `shared_preferences` for storage (not sqflite). Data persists
across page reloads in the same browser.

---

## Local & Global Skills for AI Agents

Skills are stored locally at `.agents/skills/` in the project root, as well as
globally at `/home/sanjay/.agents/skills/`.

```text
streak-tracker/
  .agents/
    skills/
      flutter-skill.md    ← patterns, package versions, common mistakes
```

- **Skill Search & Installation:** The `find-skills` tool is installed in
  `/home/sanjay/.agents/skills/find-skills`. We use the Skills CLI (`npx skills`)
  from the open agent skills ecosystem (<https://skills.sh/>).
- **Ecosystem Capability:** If a specialized task or domain capability is
  needed but not currently installed, agents can search for it using
  `npx skills find [query]` and install it using
  `npx skills add <owner/repo@skill> -g -y`.

Tell your AI agent at session start:
> "Read .agents/skills/flutter-skill.md, ARCHITECTURE.md, and TASKS.md before
> starting."

---

## Coding Conventions

### State Management

- Screens: `ConsumerWidget` or `ConsumerStatefulWidget` — never plain
  `StatelessWidget` when reading providers.
- Business logic: `AsyncNotifierProvider` (for async DB data) or
  `NotifierProvider` (for sync state) in `lib/providers/`.
- Local ephemeral UI state (form fields, sheet state): `StatefulWidget` +
  `setState` is fine.

### Navigation

- Use `context.go('/route')` or `context.push('/route')` from go_router.
- Never use raw `Navigator.push()` for routed screens.
- Bottom sheets are NOT routes — use `showModalBottomSheet()`.

### Null Safety

- No `!` force-unwrap without a comment explaining why it's safe.
- Use `?.` and `??` appropriately.
- Never use `dynamic` — always type explicitly.

### No Hardcoded Values

- Colors → `lib/constants/colors.dart`.
- Layout constants → `lib/constants/app_theme.dart`.
- Accent colors on counter → always `hexToColor(counter.color)`, never
  hardcode.

### Database

- Only `lib/db/sqflite_adapter.dart` may import `sqflite`.
- Only `lib/db/web_adapter.dart` may import `shared_preferences`.
- All other code calls `ref.read(dbAdapterProvider)`.

### Time + Dates

- Store all timestamps as `int` (Unix milliseconds).
- Compute elapsed time only in `lib/utils/time_utils.dart`.
- Format dates/durations only in `lib/utils/format_utils.dart`.
- Never compute time inline in widgets.

### Platform

- `kIsWeb` from `flutter/foundation.dart` for any platform branch.
- `HapticFeedback.mediumImpact()` is safe to call on web (no-op), no guard
  needed.
- `flutter_local_notifications` must be gated — check `!kIsWeb` before
  scheduling.

### Build Validation

- After completing a phase or fixing one or multiple bugs, always run a build
  (e.g., `flutter build apk --debug -t lib/main.dart`) to check for build
  warnings and errors.
- Ensure all build-time issues are fixed before proceeding to the next task
  or committing.

### Code Style

- `dart format .` before committing.
- `flutter analyze` after every change — fix all warnings, not just errors.
- Compliance with `markdownlint` rules is required for all project `.md` files
  (e.g., line wrapping to 80 columns, proper blank lines around code blocks,
  and clean list/block element indentation).
- File names: `snake_case.dart`
- Class names: `PascalCase`
- Constants: `kCamelCase` (e.g., `kCardRadius`)
- Provider names: `camelCaseProvider` / `camelCaseNotifierProvider`

---

## Version Bumping

```yaml
# pubspec.yaml
version: 1.0.0+1   # semver+buildNumber
```

| Change type | Example |
| --- | --- |
| Bug fix | `1.0.0+1` → `1.0.1+2` |
| New feature | `1.0.1+2` → `1.1.0+3` |
| Breaking change | `1.1.0+3` → `2.0.0+4` |

---

## Switching AI Agents

These files are all the context needed to switch between Claude Code, Codex,
Antigravity, or any other agent:

| File | Purpose |
| --- | --- |
| `ARCHITECTURE.md` | Stack, folder structure, data models, UI design spec |
| `CONVENTIONS.md` | This file — setup, git, workflow, coding rules |
| `TASKS.md` | What's done, what's next, bugs |
| `UI Images/` | Design reference — open before building any screen |
| `.agents/skills/flutter-skill.md` | Copy-paste patterns, quick reference |

---

## Troubleshooting

| Problem | Fix |
| --- | --- |
| `flutter doctor` SDK issue | Set `ANDROID_HOME` env var, restart shell |
| Device not in `flutter devices` | Enable USB Debugging, install USB drivers |
| Web sqflite build error | Only import sqflite in `sqflite_adapter.dart` |
| Android 13+ notifications fail | Use `permission_handler` to ask permission |
| Timer ticks after page exit | Cancel `_timer` in `dispose()` of display |
| Keyboard hides sheet | Wrap sheet in Padding using viewInsets.bottom |
| Web `shared_prefs` resets | Hot restart (`R`) resets memory, not storage |
| `flutter pub get` fails | Verify versions match ARCHITECTURE.md table |
