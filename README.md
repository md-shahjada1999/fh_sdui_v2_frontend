# Flip Health — SDUI V2

A 100% **Server-Driven UI** Flutter application. The entire UI — screens, styles, actions, navigation — is defined by JSON served from a backend. The client parses, resolves tokens/styles/expressions, and renders a live widget tree at runtime.

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x (SDK `^3.9.2`) |
| Dart | 3.x |
| Xcode | 15+ (for iOS) |
| Android Studio / Gradle | Latest stable (for Android) |
| Node.js | 18+ (only if running the mock backend) |

## Quick Start

```bash
# 1. Clone the repo
git clone <repo-url>
cd fh_sdui_v2

# 2. Install dependencies
flutter pub get

# 3. Run on a connected device / simulator
flutter run
```

## Configuration

All endpoint URLs live in a single file:

**`lib/core/sdui/config/screen_config.dart`**

| Field | Purpose |
|-------|---------|
| `manifestUrl` | URL to the SDUI manifest (screen registry with hashes) |
| `apiBaseUrl` | Base URL prepended to relative API paths like `/api/auth/send-otp` |

Update these to point at your backend before running.

### iOS HTTP (development only)

Plain HTTP connections (e.g. to a local backend on `192.168.x.x`) are allowed via the `NSAppTransportSecurity` entry in `ios/Runner/Info.plist`. Remove or tighten this for production.

## Project Structure

```
lib/
├── main.dart                          # Entry point, manifest check, app launch
├── app.dart                           # GetMaterialApp, routes, theme
│
├── core/
│   ├── api/
│   │   └── api_client.dart            # Dio HTTP client, templating, caching
│   │
│   ├── sdui/
│   │   ├── config/
│   │   │   └── screen_config.dart     # Endpoint URL registry
│   │   ├── models/
│   │   │   ├── sdui_root.dart         # Top-level JSON schema (tokens, styles, apis, layout)
│   │   │   ├── sdui_node.dart         # Single UI node
│   │   │   ├── sdui_action.dart       # Action definition (api, navigate, toast, etc.)
│   │   │   ├── sdui_api.dart          # API call definition
│   │   │   ├── sdui_style.dart        # Resolved style model
│   │   │   ├── manifest.dart          # Manifest schema (versioning, hashes)
│   │   │   ├── artifact.dart          # Pre-compiled artifact schema
│   │   │   └── patch.dart             # Patch operation schema
│   │   ├── resolver/
│   │   │   ├── token_resolver.dart    # Resolves #tokens.path references
│   │   │   ├── style_resolver.dart    # Merges style classes + inline styles
│   │   │   └── expression_resolver.dart # Evaluates {{expressions}} (&&, ||, .length, etc.)
│   │   ├── engine/
│   │   │   └── layout_engine.dart     # Converts SduiRoot → Flutter widget tree
│   │   ├── actions/
│   │   │   ├── action_executor.dart   # Runs actions: api, navigate, toast, chain, etc.
│   │   │   └── device_handler.dart    # Device capabilities (geolocation, camera, etc.)
│   │   ├── loader/
│   │   │   └── artifact_loader.dart   # Loads screens: cache → assets → remote
│   │   ├── patch/
│   │   │   └── patch_engine.dart      # Applies incremental patches to render tree
│   │   ├── parser/
│   │   │   └── sdui_parser.dart       # JSON → SduiRoot
│   │   ├── widgets/
│   │   │   └── sdui_widgets.dart      # All SDUI widget implementations
│   │   ├── sdui_screen.dart           # Widget that hosts a rendered SDUI screen
│   │   └── sdui_page.dart             # Reusable page with loading/error states
│   │
│   ├── state/
│   │   └── sdui_state_controller.dart # GetX controller (state, form data, repeat scope)
│   │
│   └── storage/
│       ├── local_storage.dart         # File-based cache (artifacts, manifest)
│       ├── manifest_checker.dart      # Diff remote vs local manifest, download updates
│       ├── hash_util.dart             # SHA-256 hashing
│       └── security.dart              # Secure token storage (flutter_secure_storage)
│
└── features/
    ├── login/login_page.dart          # Login screen (SduiPage wrapper)
    ├── otp/otp_page.dart              # OTP screen
    ├── dashboard/dashboard_page.dart  # Dashboard screen
    └── module/module_page.dart        # Generic module screen (dynamic route)
```

## How It Works

1. **Startup** — `main.dart` initialises local storage, fetches the manifest, diffs hashes against the local cache, and downloads any changed screens.
2. **Routing** — `app.dart` defines GetX routes. Each page is a thin wrapper around `SduiPage`, which loads the screen JSON by `screenId`.
3. **Loading** — `ArtifactLoader` tries: local cache → bundled assets → remote API.
4. **Parsing** — `SduiParser` converts the JSON into an `SduiRoot` (tokens, styles, apis, actions, layout).
5. **Rendering** — `LayoutEngine` walks the layout tree, resolves tokens/styles/expressions, and builds Flutter widgets.
6. **Interaction** — User events (tap, input change, submit) fire actions defined in the JSON. `ActionExecutor` handles API calls, navigation, toasts, setState, chaining, etc.

## Supported Widget Types

`screen`, `column`, `row`, `container`, `text`, `rich_text`, `image`, `icon`, `button`, `input`, `checkbox`, `otp_input`, `spacer`, `expanded`, `scroll`, `divider`, `grid`, `stack`, `carousel`, `bottom_nav`

## Supported Action Types

`api`, `navigate`, `setState`, `toast`, `popup`, `log`, `openUrl`, `analytics`, `chain`, `device`

## JSON Schema (minimal example)

```json
{
  "tokens": {
    "colors": { "primary": "#E8734A" }
  },
  "styles": {
    "classes": {
      "heading": { "fontSize": 26, "fontWeight": "bold", "color": "#tokens.colors.primary" }
    }
  },
  "apis": {
    "login": {
      "method": "POST",
      "url": "/api/auth/login",
      "body": { "mobile": "{{form.mobile}}" },
      "store": "loginResponse"
    }
  },
  "actions": {},
  "components": {},
  "layout": {
    "type": "column",
    "children": [
      { "type": "text", "props": { "text": "Hello" }, "style": [".heading"] },
      {
        "type": "button",
        "props": { "text": "Login", "enabled": "{{form.mobile.length >= 10}}" },
        "actions": [
          {
            "event": "onClick",
            "type": "api",
            "target": "login",
            "onSuccess": { "event": "", "type": "navigate", "target": "/dashboard" },
            "onFail": { "event": "", "type": "toast", "props": { "message": "Failed" } }
          }
        ]
      }
    ]
  }
}
```

## Adding a New Screen

1. Create the screen JSON on your backend.
2. Add its URL to the manifest (or directly to `ScreenConfig`).
3. Register a route in `app.dart` — or use the generic `/module/:id` route which resolves any `screenId` dynamically.
4. Navigate to it via a JSON action: `{ "type": "navigate", "target": "/module/pharmacy" }`.

## Dependencies

| Package | Purpose |
|---------|---------|
| `get` | State management, routing, snackbars |
| `dio` | HTTP client |
| `path_provider` | Local file storage paths |
| `flutter_secure_storage` | Encrypted token storage |
| `crypto` | SHA-256 hashing for manifest verification |
| `url_launcher` | Open external URLs |
| `geolocator` | Device location |
| `file_picker` | File selection |
| `image_picker` | Camera / gallery access |
