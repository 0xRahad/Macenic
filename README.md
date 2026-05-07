# Macenic

A lightweight, native macOS menu bar utility app built with Swift and SwiftUI. No third-party dependencies.

## Features

### System Monitor
- Real-time CPU, Memory, and Disk usage with visual gauges
- Network speed monitoring (upload/download)
- Battery stats: level, health, cycle count, charging status, last charged time

### Clipboard Manager
- Persistent clipboard history (text and images, up to 50 items)
- Pin important items to keep them from being removed
- Search and filter by type (All / Text / Images)
- Floating HUD panel with global shortcut (default: `Cmd+Shift+V`)
- Keyboard navigation: arrow keys, Enter to paste, Space to preview
- Quick paste: `Option+1` through `Option+9` for instant paste
- Customizable global shortcut

### Audio Switcher
- Quick switch between audio output and input devices

### Quick Toggles
- **Keep Awake** — Prevent display from sleeping
- **Keyboard Cleaner** — Lock keyboard input for 30 seconds to clean your keyboard
- **Launch at Login** — Start Macenic automatically on login

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later

## Build

1. Clone the repository
```bash
git clone https://github.com/0xRahad/Macenic.git
cd Macenic
```

2. Open in Xcode
```bash
open Macenic.xcodeproj
```

3. Build and run (`Cmd+R`)

## Permissions

- **Accessibility** — Required for the Keyboard Cleaner feature (system-wide keyboard event interception). You will be prompted to grant this when first using the feature.

## Architecture

- **SwiftUI** with `MenuBarExtra` for the menu bar interface
- **@Observable** (Observation framework) for reactive state management
- **Native APIs only** — Mach, IOKit, CoreAudio, Carbon (for global hotkeys), CoreGraphics
- **No third-party dependencies**
- Modular feature-based structure:
  ```
  Macenic/
  ├── App/           # AppState, entry point
  ├── Features/      # UI views grouped by feature
  ├── Models/        # Data models
  ├── Services/      # System services and business logic
  └── Utilities/     # Helpers (ByteFormatter)
  ```

## Support

If you find Macenic useful, consider supporting the project:

[Support Macenic](https://www.supportkori.com/apkrahad)

## Author

**Md Rahadul Islam**
- Website: [rahadul.com](https://rahadul.com/)
- GitHub: [@0xRahad](https://github.com/0xRahad)
- Email: apkrahad@gmail.com

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
