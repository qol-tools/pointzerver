# Session Handoff

## Current State

PointZerver v0.4.0 - Headless Rust server for remote PC control. Receives commands from PointZ (Flutter client).

**Platforms:** Linux, macOS, Windows

### Recent Changes (Jan 2026)
- **Fix: Cursor stuttering on macOS** - Offloaded rdev::simulate() to background thread to bypass 60Hz throttle
- Debug: Added timing instrumentation to identify macOS 60Hz rate-limiting bottleneck
- Attempted fix: Server-side EMA smoothing - **caused lag, removed**

### What Works
- UDP-based discovery (broadcast on port 45454)
- UDP command protocol (mouse, keyboard on port 45455)
- HTTP status API (port 45460)
- Mouse control (move, click, drag, scroll)
- Keyboard control (keys, modifiers)
- Platform-specific input simulation (Linux, macOS, Windows)

### Architecture

```
src/
├── main.rs                       # Entry point, spawns services
├── domain/
│   ├── models/
│   │   ├── command.rs           # Command enum (MouseMove, MouseClick, KeyPress, etc.)
│   │   └── discovery.rs         # DiscoveryResponse
│   └── config/
│       └── server_config.rs     # Port constants, delays
├── features/
│   ├── discovery/
│   │   └── discovery_service.rs # UDP broadcast discovery (port 45454)
│   └── command/
│       └── command_service.rs   # Command listener and router (port 45455)
├── input/                        # Platform-specific input handlers
│   ├── mod.rs                   # InputHandler abstraction layer
│   ├── linux.rs                 # rdev + X11 XQueryPointer
│   ├── macos.rs                 # Direct CGEvent API + background thread for simulation
│   └── windows.rs               # SendInput API + Win32
├── status_server.rs              # HTTP status API (port 45460, Axum)
└── utils/
    └── mod.rs                   # Utility functions
```

### Protocol

**Discovery (UDP port 45454):**
```
Client → Broadcast: "DISCOVER"
Server → Response: {"hostname": "my-computer"}
```

**Commands (UDP port 45455):**
```json
{"type": "MouseMove", "x": 10.5, "y": 20.5}
{"type": "MouseClick", "button": 1}
{"type": "KeyPress", "key": "a", "modifiers": {"ctrl": true}}
```

**Status API (HTTP port 45460):**
- `GET /health` → "ok"
- `GET /status` → JSON with hostname, IP, ports

### Server Configuration

**Constants (server_config.rs):**
- `MOUSE_CLICK_DELAY_MS` - 10ms
- `DOUBLE_CLICK_TIMEOUT_MS` - 350ms
- `DRAG_BATCH_INTERVAL_MS` - 16ms (macOS drag smoothing)

### Development Workflow

**Building:**
```bash
cargo build --release
```

**Running:**
```bash
cargo run --release
```

**Testing:**
```bash
cargo test
```

**Installing:**
```bash
cargo build --release
sudo cp target/release/pointzerver /usr/local/bin/
```

### Platform-Specific Implementation

**Linux (input/linux.rs):**
- Uses `rdev` crate for mouse/keyboard simulation
- Uses X11 `XQueryPointer` for cursor position queries
- Straightforward event simulation, no rate limiting

**macOS (input/macos.rs):**
- Uses CoreGraphics `CGEvent` API directly for mouse movements
- Uses `rdev` for keyboard simulation
- **Critical:** Offloads `rdev::simulate()` to background thread with channel queue
- macOS WindowServer rate-limits event simulation to 60Hz
- Background thread architecture prevents UDP receive loop from blocking
- UDP loop can process at 100+ fps while simulation happens independently

**Windows (input/windows.rs):**
- Uses Win32 `SendInput` API for mouse/keyboard simulation
- Uses Win32 APIs for cursor position queries
- Direct API access, no rate limiting issues

### Known Issues / TODO

1. **macOS cursor stuttering** - **FIXED (Jan 10, 2026)**
   - **Root cause:** `rdev::simulate()` was being rate-limited by macOS to 60fps, blocking UDP receive loop
   - **Solution:** Offloaded simulation to background thread with channel-based queue
   - UDP receive loop now queues events without blocking
   - Mouse movements processed asynchronously at macOS's allowed rate
   - Result: UDP loop receives at full speed while simulation happens independently

   **What was tried (unsuccessful):**
   - Server-side EMA smoothing (0.3 factor) - Added lag, made it worse, removed
   - Direct CGEvent API instead of rdev - No improvement in throughput
   - Batching + delayed flush - Added lag

   **If issues persist:**
   - Try CGDisplayMoveCursorToPoint (deprecated but might not be throttled)
   - Try IOKit HID APIs for lower-level cursor control
   - Implement event coalescing: only process latest position every 16ms

### Key Components

**discovery_service.rs:**
- Listens for "DISCOVER" UDP broadcasts on port 45454
- Responds with JSON containing hostname
- Uses `if-addrs` crate to get network interface information

**command_service.rs:**
- Listens for JSON command messages on UDP port 45455
- Deserializes commands and routes to appropriate handler
- Spawns platform-specific InputHandler

**input/mod.rs:**
- Platform abstraction layer
- Defines InputHandler trait
- Conditionally compiles platform-specific implementations

**input/macos.rs:**
- Implements InputHandler for macOS
- Uses mpsc channel to queue events for background thread
- Background thread processes simulation calls asynchronously
- Prevents blocking of main UDP receive loop

**status_server.rs:**
- HTTP server using Axum framework
- `/health` endpoint for liveness checks
- `/status` endpoint returns server info (hostname, IPs, ports)

### Dependencies

**Key Crates:**
- `tokio` - Async runtime
- `serde` + `serde_json` - Serialization
- `if-addrs` - Network interface information
- `axum` - HTTP server framework
- `rdev` - Cross-platform input simulation (keyboard, some mouse on macOS)

**Platform-specific:**
- `windows` - Windows API bindings (conditionally compiled)
- `x11` - X11 bindings for Linux (conditionally compiled)
- `cocoa` + `objc` - macOS Cocoa APIs (conditionally compiled)

### File Locations

**Binary Output:**
- `target/release/pointzerver`

**Source:**
- `src/` - Main source code
