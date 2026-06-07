# Web Compatibility & Free Hosting Guide
>
> Streak Tracker Flutter — Making the app fully web-compatible and deploying it for free

---

## Overview

The app already has partial web support — the `DbAdapter` pattern routes to `WebAdapter` (shared_preferences), `kIsWeb` gates protect notifications and home_widget, and GoRouter handles URL-based navigation. However **four blockers** must be fixed before the app can build and run cleanly on web. After that, three free hosting options are documented with full CI/CD configs.

## Current Repo Status

- Web compatibility blockers are implemented in code.
- `.github/workflows/build.yml` is deployment-neutral for now: it runs
  `flutter analyze`, `flutter test`, `flutter build web --release`,
  packages the web build, builds the release APK, and uploads both as
  GitHub Actions artifacts.
- No hosting-provider secrets are required until the deployment target is
  chosen.
- This project currently requires Flutter `>=3.38.4` from `pubspec.lock`.
  Do not pin CI or hosting builds to Flutter 3.24 examples from older notes.

---

## Section 1 — Web Compatibility Audit

### ✅ Already Web-Compatible

| Area | Status | Notes |
| ------ | -------- | ------- |
| Database | ✅ | `WebAdapter` uses `shared_preferences` (localStorage) |
| Navigation | ✅ | GoRouter handles browser back/forward and URL routing |
| Home Widget calls | ✅ | `updateHomeWidgets()` in `widget_utils.dart` returns early on `kIsWeb` |
| Notifications | ✅ | All notification calls in `notification_utils.dart` return early on `kIsWeb` |
| Permission requests | ✅ | `requestPermission()` returns early on `kIsWeb` |
| Reminders storage | ✅ | `reminder_provider.dart` uses `shared_preferences` — works on web |
| Charts | ✅ | `fl_chart` is pure Dart — web compatible |
| Calendar | ✅ | `table_calendar` is pure Dart — web compatible |
| State management | ✅ | `flutter_riverpod` is web compatible |
| Haptics | ✅ | `HapticFeedback` is a no-op on web — no guard needed |
| Theme / Colors | ✅ | No platform-specific code |
| Share text | ✅ | `share_plus` supports Web Share API for text/URLs |

### ❌ Blockers — Must Fix Before Web Build

| # | Area | Problem | Severity |
| --- | ------ | --------- | ---------- |
| W-1 | `share_utils.dart` | Uses `dart:io` (File), `path_provider` — both crash on web | 🔴 BUILD FAIL |
| W-2 | `web/manifest.json` | Placeholder content — "A new Flutter project", wrong theme color | 🟡 UX |
| W-3 | `web/index.html` | Placeholder title and description — affects SEO and PWA install prompt | 🟡 UX |
| W-4 | GoRouter initial location | No explicit `initialLocation` — browser navigation can 404 on hard refresh | 🟡 UX |

---

## Section 2 — Required Code Fixes

### Fix W-1: Share Feature Web Compatibility (CRITICAL)

**File:** `lib/utils/share_utils.dart`

The current `shareCounterImage()` function:

1. Uses `path_provider` (`getTemporaryDirectory()`) — `dart:io` — **crashes on web**
2. Uses `File` from `dart:io` — **crashes on web**
3. Uses `XFile(imagePath)` from a disk path — **invalid on web**

The `screenshot` package itself works on web via CanvasKit (it uses `RepaintBoundary.toImage()`), so the image capture part is fine. The problem is what happens to the bytes afterward.

**Fix:** Split the share function into platform-aware branches using `kIsWeb`. On web, trigger a browser download using `dart:html`; on native, continue using the file-based approach.

**Step 1 — Add `web` package to `pubspec.yaml`:**

```yaml
dependencies:
  # ... existing deps ...
  web: ^1.0.0    # official Dart web interop package (replaces dart:html)
```

> Note: Flutter 3.24+ recommends the `web` package over `dart:html`. Both work; `web` is the future-proof choice.

**Step 2 — Replace `shareCounterImage()` in `lib/utils/share_utils.dart`:**

```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

// Native-only imports — conditionally compiled
import 'share_utils_native.dart'
    if (dart.library.js_interop) 'share_utils_web.dart';

import '../constants/colors.dart';
import '../models/counter.dart';
import '../models/elapsed_time.dart';
import '../utils/time_utils.dart';
import '../utils/format_utils.dart';

enum ShareImageFormat { portrait, square, story }

// ... ShareImageGenerator and ChevronPainter widgets unchanged ...

Future<void> shareCounterImage(
  BuildContext context,
  Counter counter,
  ShareImageFormat format,
  String period, {
  String? resetMessage,
}) async {
  final screenshotController = ScreenshotController();
  final elapsed = getElapsed(
    counter.startedAt,
    DateTime.now().millisecondsSinceEpoch,
  );
  var loaderShown = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );
  loaderShown = true;

  try {
    final imageBytes = await screenshotController.captureFromWidget(
      ShareImageGenerator(
        counter: counter,
        format: format,
        elapsed: elapsed,
        period: period,
        resetMessage: resetMessage,
      ),
      delay: const Duration(milliseconds: 100),
      context: context,
    );

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      loaderShown = false;
    }

    if (kIsWeb) {
      // Web: trigger a browser download — no file system access available
      await downloadImageOnWeb(
        imageBytes,
        '${counter.title.replaceAll(' ', '_')}_streak.png',
      );
    } else {
      // Native: write to temp dir and share via system share sheet
      await shareImageOnNative(
        imageBytes,
        counter.title,
        'My ${counter.title} Streak',
      );
    }
  } catch (e) {
    if (context.mounted) {
      if (loaderShown) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to share: $e')),
      );
    }
  }
}
```

**Step 3 — Create `lib/utils/share_utils_native.dart`:**

```dart
// Native implementation — uses dart:io and path_provider
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareImageOnNative(
  List<int> imageBytes,
  String counterTitle,
  String subject,
) async {
  final directory = await getTemporaryDirectory();
  final imagePath =
      '${directory.path}/share_${DateTime.now().millisecondsSinceEpoch}.png';
  final file = File(imagePath);
  await file.writeAsBytes(imageBytes);

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile(imagePath)],
      subject: subject,
      text: 'Check out my streak on $counterTitle!',
    ),
  );
}

// This stub exists so web-conditional import compiles
Future<void> downloadImageOnWeb(List<int> bytes, String filename) async {
  // No-op on native — this path is never called
}
```

**Step 4 — Create `lib/utils/share_utils_web.dart`:**

```dart
// Web implementation — uses browser download API
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<void> downloadImageOnWeb(List<int> bytes, String filename) async {
  // Convert bytes to a JS Uint8Array, create a Blob, then trigger download
  final jsArray = bytes.map((b) => b.toJS).toList().toJS;
  final uint8Array = web.Uint8Array(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    uint8Array[i] = bytes[i];
  }

  final blob = web.Blob(
    [uint8Array.buffer].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );

  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;

  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

// Stub so native-conditional import compiles
Future<void> shareImageOnNative(
  List<int> imageBytes,
  String counterTitle,
  String subject,
) async {
  // No-op on web — this path is never called
}
```

> **Why conditional imports instead of `kIsWeb` if-else?**
> `dart:io` and `path_provider` fail to compile at all on web — not just at runtime. Conditional imports (`if (dart.library.js_interop)`) tell the Dart compiler to swap files at compile time, keeping each build target clean.

---

### Fix W-2: Rewrite `web/manifest.json`

The current manifest uses Flutter's default placeholder values. Replace the entire file:

```json
{
    "name": "Streak Tracker",
    "short_name": "Streak",
    "description": "Track your habits and personal streaks. A free, no-ads Days Since tracker.",
    "start_url": "./",
    "display": "standalone",
    "background_color": "#F2F2F7",
    "theme_color": "#000000",
    "orientation": "portrait-primary",
    "prefer_related_applications": false,
    "categories": ["health", "lifestyle", "productivity"],
    "lang": "en",
    "icons": [
        {
            "src": "icons/Icon-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "any"
        },
        {
            "src": "icons/Icon-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "any"
        },
        {
            "src": "icons/Icon-maskable-192.png",
            "sizes": "192x192",
            "type": "image/png",
            "purpose": "maskable"
        },
        {
            "src": "icons/Icon-maskable-512.png",
            "sizes": "512x512",
            "type": "image/png",
            "purpose": "maskable"
        }
    ],
    "shortcuts": [
        {
            "name": "Add Counter",
            "short_name": "Add",
            "description": "Create a new streak counter",
            "url": "./counters",
            "icons": [{ "src": "icons/Icon-192.png", "sizes": "192x192" }]
        }
    ]
}
```

> `theme_color: "#000000"` matches the dark OLED theme of the app. The browser toolbar will match.

---

### Fix W-3: Rewrite `web/index.html`

Replace the placeholder content inside `<head>`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">

  <!-- SEO -->
  <meta name="description" content="Track your habits and personal streaks. A free, premium Days Since tracker — no ads, no paid plans.">
  <meta name="keywords" content="streak tracker, habit tracker, days since, habit counter">
  <meta name="author" content="Sanju2op">

  <!-- Open Graph (social sharing previews) -->
  <meta property="og:title" content="Streak Tracker">
  <meta property="og:description" content="Track your habits and personal streaks. Free, no ads.">
  <meta property="og:type" content="website">
  <meta property="og:image" content="icons/Icon-512.png">

  <!-- PWA / iOS -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
  <meta name="apple-mobile-web-app-title" content="Streak Tracker">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Theme color — matches app dark background -->
  <meta name="theme-color" content="#000000">
  <meta name="theme-color" content="#F2F2F7" media="(prefers-color-scheme: light)">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png">
  <link rel="manifest" href="manifest.json">

  <title>Streak Tracker</title>

  <!-- Loading screen styles — shown before Flutter initialises -->
  <style>
    body {
      margin: 0;
      background-color: #000000;
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100vh;
    }
    @media (prefers-color-scheme: light) {
      body { background-color: #F2F2F7; }
      .loading-dot { background-color: #1C1C1E !important; }
    }
    .loading-dots {
      display: flex;
      gap: 8px;
    }
    .loading-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background-color: #FFFFFF;
      animation: pulse 1.2s ease-in-out infinite;
    }
    .loading-dot:nth-child(2) { animation-delay: 0.2s; }
    .loading-dot:nth-child(3) { animation-delay: 0.4s; }
    @keyframes pulse {
      0%, 80%, 100% { opacity: 0.2; transform: scale(0.8); }
      40% { opacity: 1; transform: scale(1); }
    }
  </style>
</head>
<body>
  <!-- Loading indicator shown while Flutter engine initialises -->
  <div class="loading-dots" id="loading">
    <div class="loading-dot"></div>
    <div class="loading-dot"></div>
    <div class="loading-dot"></div>
  </div>

  <script src="flutter_bootstrap.js" async></script>
  <script>
    // Hide loading dots once Flutter has rendered its first frame
    window.addEventListener('flutter-first-frame', function () {
      document.getElementById('loading').style.display = 'none';
    });
  </script>
</body>
</html>
```

---

### Fix W-4: Add `initialLocation` to GoRouter

**File:** `lib/router/app_router.dart`

```dart
// Before:
final appRouter = GoRouter(
  routes: [ ... ],
  redirect: (_, state) => state.uri.path == '/' ? '/counters' : null,
);

// After:
final appRouter = GoRouter(
  initialLocation: '/counters',  // ← ADD: explicit initial route for web
  routes: [ ... ],
  redirect: (_, state) => state.uri.path == '/' ? '/counters' : null,
);
```

Without `initialLocation`, GoRouter defaults to `/` — which gets redirected, but on a browser hard-refresh of a sub-page URL (`/counters/some-id`), the redirect fires before the route is matched, causing a blank screen in some configurations.

---

### Fix W-5: Enable Web Splash Screen

**File:** `pubspec.yaml`

```yaml
flutter_native_splash:
  color: "#F2F2F7"
  color_dark: "#000000"
  image: "assets/splash/splash.png"
  image_dark: "assets/splash/splash_dark.png"
  android: true
  web: true          # ← Change from false to true
  web_image_mode: center
```

After changing, run:

```bash
dart run flutter_native_splash:create
```

---

## Section 3 — Build Configuration

### Choosing a Web Renderer

Flutter offers two web renderers:

| Renderer | Bundle Size | Quality | Performance | Use When |
| ---------- | ------------- | --------- | ------------- | ---------- |
| `html` | ~2 MB | Lower | Fast startup | Primarily text/list UIs |
| `canvaskit` | ~8 MB | Highest | Slower startup | Graphics-heavy apps |
| `wasm` (Flutter 3.24+) | ~5 MB | Highest | Fastest | Best of both worlds |

**Recommendation for Streak Tracker:** Use `--wasm` (WebAssembly) if on Flutter 3.24+. It gives CanvasKit visual quality with significantly faster startup and a smaller bundle than full CanvasKit. The `BackdropFilter` blur effects and the `fl_chart` rendering both benefit from CanvasKit-class rendering.

```bash
# Preferred — WebAssembly (Flutter 3.24+)
flutter build web --wasm

# Fallback — CanvasKit (all stable versions)
flutter build web --web-renderer canvaskit

# Check your Flutter version
flutter --version
```

### Optimising Bundle Size

Add to `web/index.html` inside `<head>` to enable compression signalling:

```html
<meta http-equiv="Content-Encoding" content="gzip">
```

Also, ensure your hosting platform serves `.br` (Brotli) files if available — Flutter web build generates pre-compressed `.br` and `.gz` versions of all assets automatically. Most free CDN hosts (Vercel, Netlify, Cloudflare Pages) serve these automatically.

---

## Section 4 — Free Hosting Options

Three fully free options are documented below. **Netlify is the recommended choice** for this project — zero config, automatic HTTPS, fast global CDN, and handles the Flutter web SPA routing with one config file.

---

### Option A — Netlify (Recommended)

**Free tier:** 100 GB bandwidth/month, unlimited sites, automatic HTTPS, custom domain.

**Setup (5 minutes):**

**Step 1 — Create `netlify.toml` at the repo root:**

```toml
[build]
  command = "flutter build web --wasm"
  publish = "build/web"

[build.environment]
  FLUTTER_VERSION = "3.38.4"

# SPA redirect — sends all routes to index.html so GoRouter handles them
[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

# Security headers
[[headers]]
  for = "/*"
  [headers.values]
    X-Frame-Options = "DENY"
    X-Content-Type-Options = "nosniff"
    Referrer-Policy = "strict-origin-when-cross-origin"

# Cache Flutter assets aggressively
[[headers]]
  for = "/flutter_assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"

[[headers]]
  for = "/*.js"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

**Step 2 — Add `.netlify/` to `.gitignore`:**

```gitignore
.netlify/
```

**Step 3 — Deploy:**

1. Go to [netlify.com](https://netlify.com) → "Add new site" → "Import an existing project"
2. Connect your GitHub repo `Sanju2op/streak-tracker-flutter`
3. Netlify auto-detects `netlify.toml` — click "Deploy site"
4. Your app is live at `https://random-name.netlify.app`

**Custom domain (free):** Site settings → Domain management → Add custom domain. Netlify provisions an SSL certificate automatically via Let's Encrypt.

> **Important:** Netlify's build environment doesn't have Flutter pre-installed. Add a `build.sh` script OR use the Netlify Flutter community build plugin. Alternatively, use GitHub Actions to build and deploy to Netlify (see GitHub Actions section below).

**Netlify + GitHub Actions workflow (most reliable):**

Create `.github/workflows/deploy-netlify.yml`:

```yaml
name: Deploy to Netlify

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.4'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build web (WASM)
        run: flutter build web --wasm

      - name: Deploy to Netlify
        uses: nwtgck/actions-netlify@v3
        with:
          publish-dir: './build/web'
          production-branch: main
          github-token: ${{ secrets.GITHUB_TOKEN }}
          deploy-message: "Deploy from GitHub Actions — ${{ github.sha }}"
          enable-pull-request-comment: true
          enable-commit-comment: true
        env:
          NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
          NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

**Add secrets in GitHub:** Repo → Settings → Secrets and variables → Actions:

- `NETLIFY_AUTH_TOKEN` — from Netlify User Settings → Applications → Personal access tokens
- `NETLIFY_SITE_ID` — from Netlify Site settings → General → Site ID

---

### Option B — GitHub Pages

**Free tier:** Unlimited for public repos, 1 GB storage, 100 GB bandwidth/month.

**Limitation:** The app will be hosted at `https://sanju2op.github.io/streak-tracker-flutter/` — a subdirectory, not the root. This requires passing `--base-href` to the build command.

**Step 1 — Create `.github/workflows/deploy-gh-pages.yml`:**

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]
  workflow_dispatch:

permissions:
  contents: write
  pages: write
  id-token: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.4'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        # base-href MUST match the GitHub Pages subdirectory path
        run: flutter build web --wasm --base-href /streak-tracker-flutter/

      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
          publish_branch: gh-pages
          force_orphan: true
```

**Step 2 — Enable GitHub Pages:**

1. GitHub repo → Settings → Pages
2. Source: "Deploy from a branch"
3. Branch: `gh-pages` / `/ (root)`
4. Save — site is live at `https://sanju2op.github.io/streak-tracker-flutter/`

**Step 3 — Fix GoRouter base path:**

GoRouter must know about the `/streak-tracker-flutter/` path prefix. Update `lib/router/app_router.dart`:

```dart
// Detect base path at runtime from the browser URL
// This is only needed if using GitHub Pages subdirectory hosting.
// For Netlify/Vercel root hosting, this is not required.

import 'package:flutter/foundation.dart' show kIsWeb;

String get _basePath {
  if (!kIsWeb) return '/';
  // In web, check the base href set during build
  return const String.fromEnvironment('BASE_HREF', defaultValue: '/');
}

final appRouter = GoRouter(
  initialLocation: '/counters',
  // urlPathStrategy is set in main.dart — see below
  routes: [ ... ],
);
```

Add to `lib/main.dart` before `runApp`:

```dart
import 'package:flutter_web_plugins/url_strategy.dart';

void main() {
  usePathUrlStrategy(); // removes the # from URLs on web
  runApp(const ProviderScope(child: StreakTrackerApp()));
}
```

> **Note:** `flutter_web_plugins` is part of the Flutter SDK — no extra package needed.

**Add `flutter_web_plugins` dependency to pubspec.yaml:**

```yaml
dependencies:
  flutter_web_plugins:
    sdk: flutter
```

---

### Option C — Vercel

**Free tier:** 100 GB bandwidth/month, unlimited deployments, global edge network, automatic HTTPS.

**Step 1 — Create `vercel.json` at the repo root:**

```json
{
  "buildCommand": null,
  "outputDirectory": "build/web",
  "installCommand": null,
  "framework": null,
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ],
  "headers": [
    {
      "source": "/flutter_assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

**Step 2 — Create `.github/workflows/deploy-vercel.yml`:**

```yaml
name: Deploy to Vercel

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.4'
          channel: 'stable'
          cache: true

      - name: Install dependencies
        run: flutter pub get

      - name: Build web
        run: flutter build web --wasm

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: ./build/web
          vercel-args: '--prod'
```

**Get Vercel secrets:**

- `VERCEL_TOKEN` — Vercel dashboard → Settings → Tokens
- `VERCEL_ORG_ID` and `VERCEL_PROJECT_ID` — in `.vercel/project.json` after running `vercel link` locally once

---

## Section 5 — Web UX Considerations

### Responsive Layout

The current `SliverGrid` uses `crossAxisCount: 2` hardcoded — this looks fine on mobile but on a wide browser window (1440px+) two wide cards look awkward.

**Fix:** Make column count responsive in `counters_screen.dart`:

```dart
// In _CounterGrid or where SliverGrid is built:
final screenWidth = MediaQuery.of(context).size.width;
final crossAxisCount = screenWidth > 900 ? 4 : screenWidth > 600 ? 3 : 2;

SliverGrid(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: crossAxisCount,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 0.9,
  ),
  ...
)
```

Similarly, constrain the max content width on large screens so the app doesn't stretch across a 4K monitor. Wrap the root `Scaffold` body in a `Center` + `ConstrainedBox`:

```dart
// In app.dart or a layout wrapper widget:
ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 600),
  child: child,
)
```

This makes the web version feel like a proper mobile PWA, not a stretched app.

### Mouse Interactions

On web, users hover with a cursor. Flutter renders correctly but doesn't show pointer cursors on tappable elements by default.

**Fix:** Wrap tappable widgets in `MouseRegion` to show correct cursor:

```dart
// For CounterCard and _MenuRow:
MouseRegion(
  cursor: SystemMouseCursors.click,
  child: GestureDetector(
    onTap: ...,
    child: ...,
  ),
)
```

Or use `InkWell` instead of `GestureDetector` — `InkWell` automatically sets `SystemMouseCursors.click` on web.

### Share on Web — User Communication

Since web users download the image file instead of opening a native share sheet, update the `ShareSheet` UI to communicate this clearly on web:

```dart
// In share_sheet.dart, the share button label:
import 'package:flutter/foundation.dart' show kIsWeb;

Text(kIsWeb ? 'Download Image' : 'Share'),
```

The icon should also change:

```dart
Icon(kIsWeb ? Icons.download_rounded : Icons.ios_share),
```

### No Context Menu / Text Selection

Flutter web apps disable browser text selection and right-click by default. For a streak tracker, this is appropriate — users shouldn't be able to accidentally select numbers. No action needed.

### Keyboard Navigation

GoRouter handles browser history (back/forward buttons). Tab focus and keyboard navigation work automatically via Flutter's focus system.

---

## Section 6 — ARCHITECTURE.md Updates Required

Add the following to the ARCHITECTURE.md package table:

```markdown
| Web interop  | **web ^1.0.x**                    | Browser download API for web image sharing     |
| Web plugins  | **flutter_web_plugins** (SDK)     | `usePathUrlStrategy()` — removes # from URLs   |
```

Add a new section to ARCHITECTURE.md:

```markdown
## Web Deployment

The app is hosted as a PWA at [URL]. Free hosting via Netlify (recommended).

### Build for Web
```bash
# WASM renderer (recommended — Flutter 3.24+)
flutter build web --wasm

# Fallback — CanvasKit
flutter build web --web-renderer canvaskit
```

### Base Href

- Netlify / Vercel (root domain): no `--base-href` needed
- GitHub Pages (subdirectory): `--base-href /streak-tracker-flutter/`

### Feature Differences: Web vs Android

| Feature | Android | Web |
| --------- | --------- | ----- |
| Streak tracking | ✅ | ✅ |
| Calendar | ✅ | ✅ |
| Stats charts | ✅ | ✅ |
| Goals | ✅ | ✅ |
| Reminders | ✅ | ❌ (no local notifications) |
| Home screen widgets | ✅ | ❌ (Android-only) |
| Share image | ✅ System share | ✅ Download file |
| Offline support | ✅ | ✅ (PWA service worker) |
| Install to home screen | N/A | ✅ (PWA install prompt) |

```

---

## Section 7 — Testing Checklist Before Deployment

Run these before pushing:

```bash
# 1. Verify the web build compiles cleanly
flutter build web --wasm

# 2. Serve locally and test all screens
cd build/web && python -m http.server 8080
# Open: http://localhost:8080

# 3. Test browser navigation
# - Open a counter, note the URL (/counters/<id>)
# - Hit browser back — should return to /counters
# - Hard-refresh on /counters/<id> — should not 404

# 4. Test dark/light mode
# - Toggle OS dark mode — app should follow immediately

# 5. Test PWA install
# - Chrome: address bar → Install button (desktop)
# - Mobile Chrome: browser menu → "Add to Home Screen"

# 6. Test share/download on web
# - Open a counter → Share → "Download Image"
# - File should download as a .png

# 7. Lighthouse audit
# - Chrome DevTools → Lighthouse → Run audit
# - Target: Performance 80+, PWA 100, Accessibility 90+

# 8. Run Flutter tests (they still pass on web build)
flutter test
```

---

## Summary

| Task | File(s) | Effort |
| ------ | --------- | -------- |
| Fix share — conditional imports | `share_utils.dart`, new `share_utils_native.dart`, new `share_utils_web.dart` | 45 min |
| Add `web` package | `pubspec.yaml`, ARCHITECTURE.md | 5 min |
| Rewrite `manifest.json` | `web/manifest.json` | 10 min |
| Rewrite `index.html` | `web/index.html` | 15 min |
| Add `initialLocation` to GoRouter | `lib/router/app_router.dart` | 2 min |
| Add `usePathUrlStrategy()` to main | `lib/main.dart` | 5 min |
| Enable web splash | `pubspec.yaml` + regenerate | 10 min |
| Responsive grid column count | `lib/screens/counters/counters_screen.dart` | 15 min |
| Max width constraint | `lib/app.dart` | 10 min |
| Mouse cursor on tappable items | `counter_card.dart`, `_MenuRow` | 20 min |
| Share button label for web | `lib/sheets/share_sheet.dart` | 5 min |
| Create `netlify.toml` | repo root | 5 min |
| Create GitHub Actions workflow | `.github/workflows/` | 15 min |
| Update ARCHITECTURE.md | `ARCHITECTURE.md` | 10 min |
