<div align="center">
  <a href="https://github.com/qol-tools/pointzerver">
    <img
      src="assets/pz-banner.svg"
      alt="PointZerver"
      width="442"
      height="159"
    />
  </a>
</div>

<br>

<p align="center">Headless server for remote PC control from mobile devices</p>

## Overview

PointZerver is a Rust daemon that enables remote control of your PC from mobile devices. Works with [PointZ](https://github.com/qol-tools/pointz) mobile app.

**Platforms:** Linux, macOS, Windows

## Installation

### As a qol-tray plugin

Install via the [qol-tray](https://github.com/qol-tools/qol-tray) Plugin Store, or manually:

```bash
git clone https://github.com/qol-tools/plugin-pointz ~/.config/qol-tray/plugins/plugin-pointz
```

### Standalone

```bash
make install
```

## Usage

When running standalone:
1. Start the server: `pointzerver`
2. Launch [PointZ](https://github.com/qol-tools/pointz) on your phone
3. The app auto-discovers and connects to the server

## Building

```bash
make build    # Debug build
make release  # Release build
make run      # Build and run
make test     # Run tests
```

## Ports

| Port  | Protocol | Purpose           |
|-------|----------|-------------------|
| 45454 | UDP      | Discovery         |
| 45455 | UDP      | Command/Control   |
| 45460 | HTTP     | Status API        |
