# Logging and Observability Patterns

## Swift - Unified Logging System

### Overview
Use Apple's [Unified Logging System](https://developer.apple.com/documentation/os/logging) (OSLog) for efficient, structured logging.

### Setup

```swift
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let metadata = Logger(subsystem: subsystem, category: "metadata")
    static let dataLayer = Logger(subsystem: subsystem, category: "datalayer")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let plugin = Logger(subsystem: subsystem, category: "plugin")
}
```

### Usage Patterns

```swift
// Info level - general flow
Logger.audio.info("Starting playback: \(track.title, privacy: .public)")

// Debug level - detailed information
Logger.audio.debug("Audio format: \(format, privacy: .private)")

// Error level - errors with context
Logger.audio.error("Playback failed: \(error.localizedDescription, privacy: .public)")

// Fault level - critical errors
Logger.audio.fault("Audio engine initialization failed")

// Structured logging with metadata
Logger.metadata.info(
    "Tag parsed",
    metadata: [
        "track_id": "\(trackId)",
        "format": format,
        "duration_ms": "\(duration)"
    ]
)
```

### Best Practices
- Use appropriate log levels (debug, info, notice, error, fault)
- Mark sensitive data with `privacy: .private`
- Use structured metadata for filtering
- Use `os_signpost` for performance measurement
- Avoid logging in tight loops

### Performance Measurement

```swift
import os.signpost

let signposter = OSSignposter(logger: Logger.audio)

func scanLibrary() {
    let state = signposter.beginInterval("library_scan")
    defer { signposter.endInterval("library_scan", state) }

    // Scanning code...
}
```

---

## C++ - spdlog

### Overview
Use [spdlog](https://github.com/gabime/spdlog) for high-performance, feature-rich logging.

### Setup

```cpp
#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>
#include <spdlog/sinks/rotating_file_sink.h>

void setupLogging() {
    // Console sink
    auto console = spdlog::stdout_color_mt("console");

    // Rotating file sink (5MB files, 3 rotated files)
    auto file = spdlog::rotating_logger_mt(
        "file_logger",
        "logs/audientia.log",
        1024 * 1024 * 5,  // 5MB
        3
    );

    // Set default logger
    spdlog::set_default_logger(console);
    spdlog::set_level(spdlog::level::debug);

    // Set pattern
    spdlog::set_pattern("[%Y-%m-%d %H:%M:%S.%e] [%^%l%$] [%n] %v");
}
```

### Usage Patterns

```cpp
// Different log levels
spdlog::debug("Audio buffer size: {}", bufferSize);
spdlog::info("Playback started: {}", trackTitle);
spdlog::warn("Low audio buffer, may cause stuttering");
spdlog::error("Failed to decode audio: {}", errorMessage);
spdlog::critical("Audio engine crashed");

// Structured logging
spdlog::info(
    "Tag parsed: track_id={}, format={}, duration={}ms",
    trackId, format, duration
);

// Logger-specific instances
auto audioLogger = spdlog::get("audio");
audioLogger->info("Audio operation completed");
```

### Best Practices
- Use appropriate log levels
- Use structured format strings (avoid string concatenation)
- Create logger instances per module
- Use async logging for performance-critical paths
- Rotate log files to prevent disk fill

### Async Logging

```cpp
#include <spdlog/async.h>

void setupAsyncLogging() {
    spdlog::init_thread_pool(8192, 1);
    auto async_file = spdlog::basic_logger_mt<spdlog::async_factory>(
        "async_file_logger",
        "logs/async.log"
    );
    spdlog::set_default_logger(async_file);
}
```

---

## Rust - tracing

### Overview
Use [tracing](https://github.com/tokio-rs/tracing) for structured, context-aware logging.

### Setup

```rust
use tracing::{info, debug, error, warn};
use tracing_subscriber::{fmt, EnvFilter};

fn setup_logging() {
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .with_target(false)
        .with_thread_ids(true)
        .init();
}
```

### Usage Patterns

```rust
// Basic logging
debug!("Audio buffer size: {}", buffer_size);
info!("Playback started: {}", track_title);
warn!("Low audio buffer, may cause stuttering");
error!("Failed to decode audio: {}", error_message);

// Structured fields
info!(
    track_id = %track_id,
    format = %format,
    duration_ms = duration,
    "Tag parsed"
);

// Spans for context
use tracing::{span, Level};

let span = span!(Level::INFO, "library_scan", library_path = %path);
let _enter = span.enter();
info!("Starting library scan");
// ... scanning code ...
```

### Best Practices
- Use spans for operation context
- Use structured fields for filtering
- Use appropriate levels
- Use `tracing-error` for error context
- Use `tracing-opentelemetry` for distributed tracing

### Error Context

```rust
use tracing_error::ErrorLayer;
use tracing_subscriber::prelude::*;

tracing_subscriber::registry()
    .with(ErrorLayer::default())
    .with(fmt::layer())
    .init();

// Errors automatically include span context
```

---

## JavaScript - Console API (for Plugins)

### Overview
Plugins use JavaScriptCore's console API, bridged to Swift logging.

### Usage Patterns

```javascript
// Different log levels
console.debug('Plugin initialized');
console.info('Metadata fetched:', { trackId, title });
console.warn('API rate limit approaching');
console.error('Failed to fetch metadata:', error);

// Structured logging (as objects)
console.log({
    level: 'info',
    message: 'Tag updated',
    trackId: trackId,
    changes: changes
});
```

### Swift Bridge Implementation

```swift
import JavaScriptCore

class PluginLogger {
    let logger = Logger.plugin

    func setupConsole(for context: JSContext) {
        let logFunction: @convention(block) (String, String) -> Void = { [weak self] level, message in
            switch level {
            case "debug":
                self?.logger.debug("\(message)")
            case "info":
                self?.logger.info("\(message)")
            case "warn":
                self?.logger.warning("\(message)")
            case "error":
                self?.logger.error("\(message)")
            default:
                self?.logger.info("\(message)")
            }
        }

        context.setObject(logFunction, forKeyedSubscript: "consoleLog" as NSString)

        // Inject console object
        let consoleScript = """
        console = {
            debug: function(msg) { consoleLog('debug', msg); },
            info: function(msg) { consoleLog('info', msg); },
            warn: function(msg) { consoleLog('warn', msg); },
            error: function(msg) { consoleLog('error', msg); }
        };
        """
        context.evaluateScript(consoleScript)
    }
}
```

---

## Observability Patterns

### Metrics Collection

```swift
import MetricKit

class MetricsCollector {
    static let shared = MetricsCollector()

    func recordPlaybackDuration(_ duration: TimeInterval) {
        let metric = MXMetricPayload()
        // Record custom metric
    }

    func recordError(_ error: Error, context: [String: Any]) {
        // Record error metrics
    }
}
```

### Performance Monitoring

```swift
import os.signpost

class PerformanceMonitor {
    let signposter = OSSignposter(logger: Logger.shared)

    func measure<T>(_ operation: String, _ block: () throws -> T) rethrows -> T {
        let state = signposter.beginInterval(operation)
        defer { signposter.endInterval(operation, state) }
        return try block()
    }
}

// Usage
let result = PerformanceMonitor.shared.measure("library_scan") {
    try library.scan()
}
```

### Distributed Tracing

For future server integration, use OpenTelemetry:

```swift
// Future: OpenTelemetry Swift integration
// For now, use correlation IDs in logs
struct TraceContext {
    let traceId: String
    let spanId: String

    func inject(into logger: Logger) {
        // Add trace context to log metadata
    }
}
```

---

## Log Levels Guide

| Level | When to Use | Example |
|-------|-------------|---------|
| **Debug** | Detailed diagnostic information | "Audio buffer filled: 4096 bytes" |
| **Info** | General informational messages | "Playback started: Song Title" |
| **Notice** | Normal but significant events | "Library scan completed: 1000 tracks" |
| **Warning** | Warning messages | "Low disk space: 500MB remaining" |
| **Error** | Error events | "Failed to decode audio file: invalid format" |
| **Fault** | Critical errors | "Audio engine crashed: segmentation fault" |

---

## Log Rotation and Retention

### Swift (OSLog)
- Managed by system
- Use Console.app for viewing
- Export logs for analysis

### C++ (spdlog)
- Configure rotating file sink
- Set max file size and count
- Archive old logs

### Rust (tracing)
- Use `tracing-appender` for file rotation
- Configure retention policy

---

## Privacy Considerations

- Mark sensitive data as private in OSLog
- Sanitize user data in logs
- Don't log passwords, API keys, or personal information
- Use correlation IDs instead of user IDs where possible
- Comply with privacy regulations (GDPR, etc.)

---

## Log Analysis Tools

- **Console.app**: Native macOS log viewer
- **log show**: Command-line tool for querying logs
- **Custom scripts**: Parse structured logs for metrics
- **Future**: Integration with observability platforms (Datadog, New Relic, etc.)

---

## Example: Complete Logging Setup

### Swift Main App

```swift
import os.log

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!

    static let audio = Logger(subsystem: subsystem, category: "audio")
    static let metadata = Logger(subsystem: subsystem, category: "metadata")
    static let dataLayer = Logger(subsystem: subsystem, category: "datalayer")
    static let ui = Logger(subsystem: subsystem, category: "ui")
    static let plugin = Logger(subsystem: subsystem, category: "plugin")
}

// Usage in AudioEngine
class AudioEngine {
    func play(_ track: Track) {
        Logger.audio.info("Starting playback: \(track.title, privacy: .public)")

        do {
            try startPlayback(track)
            Logger.audio.debug("Playback started successfully")
        } catch {
            Logger.audio.error("Playback failed: \(error.localizedDescription, privacy: .public)")
        }
    }
}
```

### C++ Audio Core

```cpp
#include <spdlog/spdlog.h>

class AudioEngine {
private:
    std::shared_ptr<spdlog::logger> logger_;

public:
    AudioEngine() {
        logger_ = spdlog::get("audio");
        if (!logger_) {
            logger_ = spdlog::stdout_color_mt("audio");
        }
    }

    void play(const std::string& trackPath) {
        logger_->info("Starting playback: {}", trackPath);
        // Playback logic...
    }
};
```

### Rust Metadata Engine

```rust
use tracing::{info, error};

pub fn parse_tags(path: &Path) -> Result<Tags, TagError> {
    info!(path = %path.display(), "Parsing tags");

    match parse_impl(path) {
        Ok(tags) => {
            info!(path = %path.display(), "Tags parsed successfully");
            Ok(tags)
        }
        Err(e) => {
            error!(path = %path.display(), error = %e, "Failed to parse tags");
            Err(e)
        }
    }
}
```
