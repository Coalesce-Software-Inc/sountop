# soundmon

A command-line audio process monitor for macOS, similar to `htop` but for audio output.

![soundmon screenshot](https://via.placeholder.com/800x400?text=soundmon+TUI+screenshot)

## Features

- Real-time monitoring of which processes are producing audio
- Uses native Core Audio HAL APIs for accurate detection
- htop-style colored terminal interface
- Shows both input (microphone) and output (speakers) activity
- Log mode for scripting and continuous logging
- Configurable polling interval

## Requirements

- macOS 10.15+ (Catalina or later)
- Swift 5.0+ (included with Xcode Command Line Tools)

## Installation

### Homebrew (recommended)

```bash
brew tap mmccune/tap
brew install soundmon
```

### From source

```bash
# Clone the repository
git clone https://github.com/mmccune/soundmon.git
cd soundmon

# Build and install
make
sudo make install
```

### Manual compilation

```bash
swiftc -O -o soundmon soundmon.swift
sudo cp soundmon /usr/local/bin/
```

### Run directly with Swift (no compilation)

```bash
swift soundmon.swift
```

## Usage

```
soundmon [OPTIONS]

OPTIONS:
    -i, --interval <seconds>   Polling interval in seconds (default: 1.0)
    -a, --all                  Show all audio clients, not just active ones
    -l, --log                  Log mode: simple timestamped output (no TUI)
    -1, --once                 Run once and exit (no continuous monitoring)
    -n, --no-color             Disable colored output
    -h, --help                 Show help message
```

## Examples

```bash
# Monitor with default 1-second refresh
soundmon

# Faster refresh (500ms)
soundmon -i 0.5

# Show all audio clients, not just active ones
soundmon -a

# Single snapshot
soundmon -1

# Log mode for scripting (appends to file)
soundmon -l -i 5 >> ~/audio.log

# Pipe-friendly output (no colors)
soundmon -1 -n | grep "OUTPUT"
```

## Output

### TUI Mode (default)

```
 soundmon - Audio Process Monitor                              [14:32:15]
 Clients: 45 | Active: 2 | Output: 2 | Input: 0
────────────────────────────────────────────────────────────────────────
PID     PROCESS                       AUDIO   INPUT   OUTPUT
────────────────────────────────────────────────────────────────────────
75115   Pandora                       yes     -       YES
88924   zoom.us                       yes     YES     YES
────────────────────────────────────────────────────────────────────────
 Press Ctrl+C to exit
```

### Log Mode (`-l`)

```
[14:32:15] Pandora (PID: 75115) - OUTPUT
[14:32:15] zoom.us (PID: 88924) - IN+OUT
```

## How It Works

soundmon uses the macOS Core Audio Hardware Abstraction Layer (HAL) APIs:

- `kAudioHardwarePropertyProcessObjectList` - enumerate all audio client processes
- `kAudioProcessPropertyPID` - get process ID
- `kAudioProcessPropertyBundleID` - get app bundle identifier
- `kAudioProcessPropertyIsRunning` - check if process has active audio
- `kAudioProcessPropertyIsRunningInput` - check for active input streams
- `kAudioProcessPropertyIsRunningOutput` - check for active output streams

This provides accurate, real-time detection of which processes are actually producing or consuming audio, not just which processes have audio libraries loaded.

## Color Scheme

| Element | Color |
|---------|-------|
| Title bar | White on Blue |
| PIDs | Cyan |
| Active processes | Bold |
| Inactive processes | Dim |
| Audio output active | Bright Green |
| Audio input active | Magenta |
| Stats | Cyan/Green/Yellow/Magenta |

## License

MIT License - feel free to use and modify.

## Contributing

Contributions welcome! Some ideas for enhancements:

- [ ] Show audio device being used per process
- [ ] Volume/level metering per process
- [ ] Filter by process name
- [ ] JSON output mode
- [ ] Historical tracking/graphing
