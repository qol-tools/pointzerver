# PointZerver

Headless Rust server for remote PC control. Receives commands from PointZ (Flutter mobile client) and simulates mouse/keyboard input.

**Platforms:** Linux, macOS, Windows

## Features

- UDP-based server discovery
- UDP command protocol for mouse and keyboard control
- HTTP status API for health checks
- Platform-specific input simulation
- Optimized event handling (background thread on macOS to avoid rate-limiting)
- Multi-threaded async architecture with Tokio

## Prerequisites

- Rust 1.70+
- Platform-specific dependencies:
  - **Linux:** X11 development libraries (`libx11-dev`)
  - **macOS:** Xcode Command Line Tools
  - **Windows:** Visual Studio Build Tools

## Quick Start

```bash
cargo build --release
cargo run --release
```

The server will start listening on:
- UDP port 45454 (discovery)
- UDP port 45455 (commands)
- HTTP port 45460 (status API)

## Installation

```bash
cargo build --release
sudo cp target/release/pointzerver /usr/local/bin/
```

Or use the Makefile:

```bash
make build
make install
```

## Usage

1. Start the server: `pointzerver`
2. Server broadcasts presence on the network
3. Connect with PointZ mobile app
4. App discovers and connects to the server automatically

## Protocol

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
- `GET /status` → JSON with hostname, IP addresses, and port info

## Architecture

```
src/
├── main.rs                 # Entry point, spawns services
├── features/
│   ├── discovery/          # UDP broadcast discovery
│   └── command/            # Command listener and router
├── input/                  # Platform-specific input handlers
│   ├── linux.rs           # X11 + rdev
│   ├── macos.rs           # CoreGraphics + background thread
│   └── windows.rs         # Win32 SendInput API
├── domain/                 # Data models and config
└── status_server.rs        # HTTP API
```

## Platform-Specific Notes

**macOS:**
- Uses background thread for event simulation to avoid 60Hz rate-limiting
- Direct CoreGraphics API for mouse movements
- rdev crate for keyboard simulation

**Linux:**
- Uses rdev crate for input simulation
- X11 XQueryPointer for cursor position queries
- Requires X11 development libraries

**Windows:**
- Win32 SendInput API for mouse/keyboard simulation
- No special threading required

## Configuration

Server constants defined in `src/domain/config/server_config.rs`:
- `MOUSE_CLICK_DELAY_MS` - Delay between mouse button actions (10ms)
- `DOUBLE_CLICK_TIMEOUT_MS` - Double-click detection window (350ms)
- `DRAG_BATCH_INTERVAL_MS` - Drag event batching interval (16ms)

## Development

**Building:**
```bash
cargo build
```

**Running:**
```bash
cargo run
```

**Testing:**
```bash
cargo test
```

**Release build:**
```bash
cargo build --release
```

## Troubleshooting

**Connection refused:**
- Check firewall settings (UDP ports 45454-45455, HTTP port 45460)
- Ensure client and server are on same network

**Mouse stuttering on macOS:**
- Fixed in v0.4.0 by offloading simulation to background thread
- If issues persist, check HANDOFF.md for alternative approaches

**Linux: X11 errors:**
- Ensure X11 development libraries are installed
- Run `sudo apt-get install libx11-dev` on Debian/Ubuntu

## License

See LICENSE file for details.
