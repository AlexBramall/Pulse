# Pulse

A lightweight, native macOS menu bar app that keeps you informed of your system's health in real time — before Chrome crashes, before you run out of disk space, before the fans spin up.

![macOS](https://img.shields.io/badge/macOS-13%2B-blue?style=flat-square)
![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange?style=flat-square)
![SwiftUI](https://img.shields.io/badge/SwiftUI-✓-green?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-lightgrey?style=flat-square)

---

## Overview

Pulse lives in your menu bar and polls your Mac's CPU, RAM, GPU, and disk every 3 seconds. Click the icon for a clean popover with per-metric detail and a list of your top memory-hungry processes. No Dock icon, no background windows, no noise — just the signal you need.

```
RAM 71%  CPU 18%  GPU 22%   ← always visible in menu bar; each turns orange or red on its own

┌─────────────────────────────────┐
│  ♥ Pulse  ·  System Health      │
├─────────────────────────────────┤
│  MEMORY                         │
│  ████████████░░░  11.2 / 16 GB  │
│  ● Pressure: Normal             │
│  Chrome 3.8GB  ·  Xcode 2.1GB   │
├─────────────────────────────────┤
│  CPU                            │
│  ██████░░░░░░░░░  38%           │
├─────────────────────────────────┤
│  GPU                            │
│  ███░░░░░░░░░░░░  22%           │
│  ● Status: Normal  1.4 GB in use│
├─────────────────────────────────┤
│  STORAGE                        │
│  ████████████░░░  241 / 512 GB  │
├─────────────────────────────────┤
│  Full Detail          Settings  │
└─────────────────────────────────┘
```

---

## Features

- **Always-on menu bar readout** — RAM, CPU, and GPU at a glance without opening anything
- **Danger-zone colours in the menu bar** — each metric turns orange when it is under strain and red when the Mac is at risk of freezing (see the table below)
- **Live memory pressure** — reads the kernel's own Normal / Elevated / Critical pressure level
- **Top memory consumers** — shows the top 3 processes by resident memory so you know what's eating your RAM
- **CPU monitoring** — overall utilisation with a sustained high-load warning after 60 seconds above 85%
- **GPU health** — utilization, GPU memory in use, and a Normal / Busy / Overworked status that accounts for sustained load and thermal state
- **Disk space warnings** — highlights low storage before macOS prompts you to delete files
- **Colour-coded health** — green → orange → red across all metrics, consistently applied
- **Zero Dock presence** — runs entirely as a menu bar accessory
- **Minimal overhead** — targets < 0.5% CPU and < 50 MB RAM at idle

---

## Requirements

| Requirement | Version |
|---|---|
| macOS | 13 Ventura or later |
| Xcode | 15+ (for building) |
| Swift | 5.9+ |

Tested on MacBook Pro (Apple Silicon, M-series). Intel Macs are supported but not regularly tested.

---

## Installation

### Build from source

```bash
git clone https://github.com/AlexBramall/Pulse.git
cd Pulse
swift build -c release
```

The compiled binary will be at `.build/release/Pulse`. You can copy it anywhere and run it directly.

### Run in development

```bash
swift run
```

### Open in Xcode

```bash
open Package.swift
```

Xcode will resolve the package and let you run, debug, and iterate from the IDE.

---

## Usage

Launch the app and it will appear in your menu bar immediately — no setup required.

| Action | Result |
|---|---|
| Glance at menu bar | See RAM %, CPU %, and GPU % at all times |
| Click menu bar icon | Open the detail popover |
| Click **Full Detail** | Opens the extended window with history graphs *(coming in M7)* |
| Click **Settings** | Configure thresholds, polling interval, launch at login *(coming in M6)* |
| Quit | Right-click the menu bar icon → Quit Pulse |

### Menu bar colours

| Metric | Orange (warning) | Red (danger) |
|---|---|---|
| RAM | Kernel memory pressure is Elevated | Kernel memory pressure is Critical |
| CPU | Above 85% right now | Above 85% for more than 60 seconds |
| GPU | Above 85% right now | Above 85% for more than 60 seconds, or macOS reports serious or critical thermal state |

RAM is coloured by pressure, not by percent used: macOS keeps RAM full on purpose, so a high percentage alone is normal.

---

## Project Structure

```
Pulse/
├── Package.swift
└── Sources/
    └── Pulse/
        ├── PulseApp.swift           # @main entry point
        ├── AppDelegate.swift        # Status item, popover, right-click menu
        ├── Models/
        │   └── SystemMetrics.swift  # Data models: CPU, Memory, GPU, Disk
        ├── Services/
        │   ├── MetricsService.swift # ObservableObject, 3s polling loop
        │   ├── CPUMonitor.swift     # host_processor_info delta-based CPU %
        │   ├── MemoryMonitor.swift  # host_statistics64, swap via sysctl
        │   ├── ProcessMonitor.swift # proc_listallpids + proc_pidinfo
        │   ├── GPUMonitor.swift     # IOKit IOAccelerator PerformanceStatistics
        │   ├── SustainedLoadTracker.swift # >85% for 60s detection (CPU, GPU)
        │   └── DiskMonitor.swift    # FileManager attributesOfFileSystem
        └── Views/
            ├── MenuBarLabel.swift      # Per-metric coloured menu bar title
            ├── PopoverView.swift       # Main popover content
            ├── MetricSectionView.swift # Reusable section header wrapper
            └── ProgressBarView.swift   # Animated progress bar component
```

---

## Architecture

Pulse follows a simple unidirectional data flow:

```
System APIs
    │
    ▼
[XxxMonitor]  ──────────────────────────────┐
(pure reads,                                │
 no state)                                  │
    │                                       │
    ▼                                       │
[MetricsService]  (@MainActor ObservableObject)
  - Owns all monitors                       │
  - 3s async polling loop                   │
  - Publishes `current: SystemMetrics`      │
    │                                       │
    ▼                                       │
[AppDelegate]  (NSStatusItem + NSPopover)   │
  - title: MenuBarLabel, one colour per metric
  - popover: PopoverView                    │
    │                                       │
    ▼                                       │
[PopoverView]  (reads via @EnvironmentObject)
  - Renders all metric sections
  - Bar and dot colours
```

Each `XxxMonitor` is a plain Swift class with no state dependencies — they only read from system APIs and return values. `MetricsService` owns them, calls them on a background-safe `Task`, and publishes the result to the UI on the main actor.

---

## Roadmap

| Milestone | Status | Description |
|---|---|---|
| M1 — Skeleton | ✅ Done | Menu bar app, popover opens/closes, placeholder data |
| M2 — Live data | ✅ Done | Real CPU, RAM, GPU, disk, top processes |
| M3 — Thermals | 🔲 Planned | CPU/GPU temperature and fan speed via SMC/IOKit |
| M4 — CPU per-process | 🔲 Planned | Per-process CPU % with delta-based tracking |
| M5 — Smart alerts | 🔲 Planned | Push notifications for memory pressure, low disk, high CPU |
| M6 — Settings | 🔲 Planned | Configurable thresholds, polling interval, launch at login |
| M7 — Full Detail window | 🔲 Planned | 60-min sparkline graphs, full process table |
| M8 — Polish | 🔲 Planned | App icon, animations, edge cases, graceful degradation |

---

## Known Limitations

- **No temperatures yet** — CPU/GPU temperature readings require SMC access, which works differently on Apple Silicon vs Intel. This will be added in M3 using IOKit SMC calls.
- **CPU per-process** — The top-processes list currently sorts by memory (resident size). Per-process CPU % with accurate delta tracking is planned for M4.
- **No App Store distribution** — The app intentionally runs outside the macOS sandbox to allow direct access to `host_processor_info`, IOKit, and `proc_pidinfo`. Distribution is local-build only.

---

## Technical Notes

**CPU measurement** uses `host_processor_info` with a tick-delta approach — two consecutive samples are diffed to compute the actual percentage of time each core spent in user/system/nice vs idle states. The first sample always returns 0% (no baseline).

**Memory pressure** reads `kern.memorystatus_vm_pressure_level` (1 normal, 2 warning, 4 critical), the same level Activity Monitor graphs. Swap size is shown but not used to judge pressure, because macOS can hold several GB of swap at normal pressure.

**Menu bar colours** need an AppKit `NSStatusItem` with an attributed title. SwiftUI's `MenuBarExtra` renders its label as a template image and drops any colour.

**GPU health** reads the `PerformanceStatistics` dictionary of each `IOAccelerator` service in the IOKit registry: `Device Utilization %` for load and `In use system memory` for GPU memory. With several GPUs, the highest utilization wins and memory is summed. The status is Overworked after 60 seconds above 85% or when macOS reports a serious or critical thermal state, and Busy above 60% or at a fair thermal state.

**Disk free space** uses `FileManager.attributesOfFileSystem(forPath:)` which returns `systemFreeSize` — the purgeable+truly-free space. This matches what Finder reports.

---

## License

MIT License — see [LICENSE](LICENSE) for details.
