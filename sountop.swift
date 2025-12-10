#!/usr/bin/env swift

import Foundation
import CoreAudio

// MARK: - Core Audio Helpers

func getAudioObjectProperty<T>(
    objectID: AudioObjectID,
    selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
) -> T? {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: scope,
        mElement: element
    )

    var size: UInt32 = UInt32(MemoryLayout<T>.size)
    let value = UnsafeMutablePointer<T>.allocate(capacity: 1)
    defer { value.deallocate() }

    let status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, value)
    guard status == noErr else { return nil }

    return value.pointee
}

func getAudioObjectIDArray(
    objectID: AudioObjectID,
    selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
) -> [AudioObjectID]? {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: scope,
        mElement: element
    )

    var size: UInt32 = 0
    var status = AudioObjectGetPropertyDataSize(objectID, &address, 0, nil, &size)
    guard status == noErr, size > 0 else { return nil }

    let count = Int(size) / MemoryLayout<AudioObjectID>.size
    let buffer = UnsafeMutablePointer<AudioObjectID>.allocate(capacity: count)
    defer { buffer.deallocate() }

    status = AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, buffer)
    guard status == noErr else { return nil }

    return Array(UnsafeBufferPointer(start: buffer, count: count))
}

func getCFStringProperty(
    objectID: AudioObjectID,
    selector: AudioObjectPropertySelector
) -> String? {
    var address = AudioObjectPropertyAddress(
        mSelector: selector,
        mScope: kAudioObjectPropertyScopeGlobal,
        mElement: kAudioObjectPropertyElementMain
    )

    var size: UInt32 = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
    var unmanagedString: Unmanaged<CFString>? = nil

    let status = withUnsafeMutablePointer(to: &unmanagedString) { ptr in
        AudioObjectGetPropertyData(objectID, &address, 0, nil, &size, ptr)
    }
    guard status == noErr, let unmanaged = unmanagedString else { return nil }

    return unmanaged.takeRetainedValue() as String
}

// MARK: - Process Info

struct AudioProcess {
    let objectID: AudioObjectID
    let pid: pid_t
    let bundleID: String?
    let processName: String
    let isRunning: Bool
    let isRunningInput: Bool
    let isRunningOutput: Bool
}

func getProcessName(pid: pid_t) -> String {
    let bufferSize = Int(MAXPATHLEN)
    var buffer = [CChar](repeating: 0, count: bufferSize)
    proc_name(pid, &buffer, UInt32(bufferSize))
    let name = String(cString: buffer)
    return name.isEmpty ? "Unknown (PID: \(pid))" : name
}

func getAudioProcesses() -> [AudioProcess] {
    // Get list of all audio process objects
    guard let processIDs = getAudioObjectIDArray(
        objectID: AudioObjectID(kAudioObjectSystemObject),
        selector: AudioObjectPropertySelector(kAudioHardwarePropertyProcessObjectList)
    ) else {
        return []
    }

    return processIDs.compactMap { objectID -> AudioProcess? in
        // Get PID
        guard let pid: pid_t = getAudioObjectProperty(
            objectID: objectID,
            selector: AudioObjectPropertySelector(kAudioProcessPropertyPID)
        ) else {
            return nil
        }

        // Get Bundle ID
        let bundleID = getCFStringProperty(
            objectID: objectID,
            selector: AudioObjectPropertySelector(kAudioProcessPropertyBundleID)
        )

        // Get process name from system
        let processName = getProcessName(pid: pid)

        // Check if running audio
        let isRunning: UInt32 = getAudioObjectProperty(
            objectID: objectID,
            selector: AudioObjectPropertySelector(kAudioProcessPropertyIsRunning)
        ) ?? 0

        let isRunningInput: UInt32 = getAudioObjectProperty(
            objectID: objectID,
            selector: AudioObjectPropertySelector(kAudioProcessPropertyIsRunningInput)
        ) ?? 0

        let isRunningOutput: UInt32 = getAudioObjectProperty(
            objectID: objectID,
            selector: AudioObjectPropertySelector(kAudioProcessPropertyIsRunningOutput)
        ) ?? 0

        return AudioProcess(
            objectID: objectID,
            pid: pid,
            bundleID: bundleID,
            processName: processName,
            isRunning: isRunning != 0,
            isRunningInput: isRunningInput != 0,
            isRunningOutput: isRunningOutput != 0
        )
    }
}

// MARK: - ANSI Colors (htop-style)

struct Color {
    static let reset = "\u{1B}[0m"
    static let bold = "\u{1B}[1m"
    static let dim = "\u{1B}[2m"

    // Foreground colors
    static let black = "\u{1B}[30m"
    static let red = "\u{1B}[31m"
    static let green = "\u{1B}[32m"
    static let yellow = "\u{1B}[33m"
    static let blue = "\u{1B}[34m"
    static let magenta = "\u{1B}[35m"
    static let cyan = "\u{1B}[36m"
    static let white = "\u{1B}[37m"

    // Bright foreground colors
    static let brightBlack = "\u{1B}[90m"
    static let brightRed = "\u{1B}[91m"
    static let brightGreen = "\u{1B}[92m"
    static let brightYellow = "\u{1B}[93m"
    static let brightBlue = "\u{1B}[94m"
    static let brightMagenta = "\u{1B}[95m"
    static let brightCyan = "\u{1B}[96m"
    static let brightWhite = "\u{1B}[97m"

    // Background colors
    static let bgBlack = "\u{1B}[40m"
    static let bgBlue = "\u{1B}[44m"
    static let bgCyan = "\u{1B}[46m"
    static let bgWhite = "\u{1B}[47m"
}

var useColors = true

func colored(_ text: String, _ codes: String...) -> String {
    guard useColors else { return text }
    return codes.joined() + text + Color.reset
}

// MARK: - Display

func clearScreen() {
    print("\u{1B}[2J\u{1B}[H", terminator: "")
}

func hideCursor() {
    print("\u{1B}[?25l", terminator: "")
}

func showCursor() {
    print("\u{1B}[?25h", terminator: "")
}

func formatTimestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: Date())
}

func padRight(_ s: String, _ width: Int) -> String {
    if s.count >= width { return String(s.prefix(width)) }
    return s + String(repeating: " ", count: width - s.count)
}

func getTerminalWidth() -> Int {
    var size = winsize()
    if ioctl(STDOUT_FILENO, TIOCGWINSZ, &size) == 0 {
        return Int(size.ws_col)
    }
    return 80
}

func displayProcesses(processes: [AudioProcess], showAll: Bool, logMode: Bool) {
    let filtered = showAll ? processes : processes.filter { $0.isRunningOutput || $0.isRunningInput }
    let termWidth = getTerminalWidth()
    let headerLine = String(repeating: "─", count: termWidth)

    if !logMode {
        clearScreen()
        hideCursor()

        // Title bar (htop-style blue background)
        let title = " sountop - Audio Process Monitor "
        let timestamp = "[\(formatTimestamp())]"
        let padding = termWidth - title.count - timestamp.count
        let titleBar = title + String(repeating: " ", count: max(0, padding)) + timestamp
        print(colored(padRight(titleBar, termWidth), Color.bold, Color.white, Color.bgBlue))

        // Stats bar
        let activeCount = processes.filter { $0.isRunningOutput || $0.isRunningInput }.count
        let outputCount = processes.filter { $0.isRunningOutput }.count
        let inputCount = processes.filter { $0.isRunningInput }.count

        let statsLine = " Clients: \(colored("\(processes.count)", Color.bold, Color.cyan)) | " +
                       "Active: \(colored("\(activeCount)", Color.bold, Color.green)) | " +
                       "Output: \(colored("\(outputCount)", Color.bold, Color.yellow)) | " +
                       "Input: \(colored("\(inputCount)", Color.bold, Color.magenta))"
        print(statsLine)
        print(colored(headerLine, Color.brightBlack))

        // Column headers
        let pidHeader = colored(padRight("PID", 8), Color.bold, Color.white)
        let nameHeader = colored(padRight("PROCESS", 30), Color.bold, Color.white)
        let audioHeader = colored(padRight("AUDIO", 8), Color.bold, Color.white)
        let inputHeader = colored(padRight("INPUT", 8), Color.bold, Color.white)
        let outputHeader = colored(padRight("OUTPUT", 8), Color.bold, Color.white)
        print("\(pidHeader)\(nameHeader)\(audioHeader)\(inputHeader)\(outputHeader)")
        print(colored(headerLine, Color.brightBlack))
    }

    if filtered.isEmpty {
        if logMode {
            let ts = colored("[\(formatTimestamp())]", Color.brightBlack)
            print("\(ts) \(colored("No processes with active audio", Color.dim))")
        } else {
            print(colored("  No processes with active audio streams", Color.dim))
        }
    } else {
        for process in filtered.sorted(by: {
            // Sort: active output first, then active input, then by name
            if $0.isRunningOutput != $1.isRunningOutput { return $0.isRunningOutput }
            if $0.isRunningInput != $1.isRunningInput { return $0.isRunningInput }
            return $0.processName < $1.processName
        }) {
            if logMode {
                if process.isRunningOutput || process.isRunningInput {
                    let ts = colored("[\(formatTimestamp())]", Color.brightBlack)
                    let dirColor = process.isRunningOutput ? Color.green : Color.magenta
                    let direction = process.isRunningOutput && process.isRunningInput ? "IN+OUT" :
                                    process.isRunningOutput ? "OUTPUT" : "INPUT"
                    let name = colored(process.processName, Color.bold, Color.cyan)
                    let pid = colored("(PID: \(process.pid))", Color.dim)
                    let dir = colored(direction, Color.bold, dirColor)
                    print("\(ts) \(name) \(pid) - \(dir)")
                }
            } else {
                // PID column
                let pidStr = colored(padRight("\(process.pid)", 8), Color.cyan)

                // Process name - highlight active processes
                let nameColor = (process.isRunningOutput || process.isRunningInput) ? Color.bold : Color.dim
                let nameStr = colored(padRight(String(process.processName.prefix(29)), 30), nameColor)

                // Audio status
                let audioStatus: String
                if process.isRunning {
                    audioStatus = colored(padRight("yes", 8), Color.green)
                } else {
                    audioStatus = colored(padRight("-", 8), Color.dim)
                }

                // Input status
                let inputStatus: String
                if process.isRunningInput {
                    inputStatus = colored(padRight("YES", 8), Color.bold, Color.magenta)
                } else {
                    inputStatus = colored(padRight("-", 8), Color.dim)
                }

                // Output status - most important, bright green
                let outputStatus: String
                if process.isRunningOutput {
                    outputStatus = colored(padRight("YES", 8), Color.bold, Color.brightGreen)
                } else {
                    outputStatus = colored(padRight("-", 8), Color.dim)
                }

                print("\(pidStr)\(nameStr)\(audioStatus)\(inputStatus)\(outputStatus)")
            }
        }
    }

    if !logMode {
        print(colored(headerLine, Color.brightBlack))
        let helpText = " Press " + colored("Ctrl+C", Color.bold, Color.yellow) + " to exit"
        print(helpText)
    }
}

// MARK: - Main

func printUsage() {
    print("""
    sountop - Monitor audio output by process on macOS

    USAGE:
        sountop [OPTIONS]

    OPTIONS:
        -i, --interval <seconds>   Polling interval in seconds (default: 1.0)
        -a, --all                  Show all audio clients, not just active ones
        -l, --log                  Log mode: simple timestamped output (no TUI)
        -1, --once                 Run once and exit (no continuous monitoring)
        -n, --no-color             Disable colored output
        -h, --help                 Show this help message

    EXAMPLES:
        sountop                    # Monitor with 1 second interval
        sountop -i 0.5             # Monitor every 500ms
        sountop -l -i 2            # Log mode, every 2 seconds
        sountop -1                 # Single snapshot
        sountop -a -n              # Show all, no colors
    """)
}

// Parse arguments
var interval: Double = 1.0
var showAll = false
var logMode = false
var runOnce = false

var args = CommandLine.arguments.dropFirst()
while let arg = args.first {
    args = args.dropFirst()
    switch arg {
    case "-i", "--interval":
        if let next = args.first, let val = Double(next) {
            interval = max(0.1, val)
            args = args.dropFirst()
        }
    case "-a", "--all":
        showAll = true
    case "-l", "--log":
        logMode = true
    case "-1", "--once":
        runOnce = true
    case "-n", "--no-color":
        useColors = false
    case "-h", "--help":
        printUsage()
        exit(0)
    default:
        if arg.hasPrefix("-") {
            print("Unknown option: \(arg)")
            printUsage()
            exit(1)
        }
    }
}

// Handle Ctrl+C gracefully - restore cursor
func cleanup() {
    showCursor()
    print(Color.reset, terminator: "")
}

signal(SIGINT) { _ in
    cleanup()
    print("\n")
    exit(0)
}

signal(SIGTERM) { _ in
    cleanup()
    exit(0)
}

// Main loop
if runOnce {
    let processes = getAudioProcesses()
    displayProcesses(processes: processes, showAll: showAll, logMode: logMode)
    if !logMode { showCursor() }
} else {
    defer { cleanup() }
    while true {
        let processes = getAudioProcesses()
        displayProcesses(processes: processes, showAll: showAll, logMode: logMode)
        Thread.sleep(forTimeInterval: interval)
    }
}
