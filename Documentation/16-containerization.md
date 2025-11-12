# Containerization Guide for Audientia

This document describes how to use Docker and Podman containers with Audientia for build, test, and development environments.

## Overview

Audientia provides containerized environments for:
- **Build tooling**: Consistent development environment with required tools
- **Testing**: Automated test execution environment
- **CI/CD**: Reproducible build and test pipelines

**Important Note**: Audientia is a macOS application that requires macOS and Xcode to build and run. The containers provided here are primarily for:
- Development tooling (FFmpeg, XcodeGen, etc.)
- Test fixture generation
- CI/CD automation on macOS runners
- Consistent development environment setup

## Prerequisites

### Docker
- **Docker**: Version 25.0.0 or later (latest stable as of 2025)
- **Docker Desktop for Mac** (or Docker Engine on Linux)
- **Docker Compose**: Version 3.9 file format (usually included with Docker Desktop)

### Podman
- **Podman**: Version 5.6.2 or later (latest stable as of 2025)
- Podman installed: `brew install podman` (macOS) or `dnf install podman` (Linux)
- Podman Compose: `pip install podman-compose` or use `podman-compose`

### Container Base Image
- **Ubuntu 24.04 LTS (Noble)**: Latest LTS release as of 2025

## Quick Start

### Docker

1. **Build the container:**
   ```bash
   docker build -t audientia:latest .
   ```

2. **Run a command:**
   ```bash
   docker run --rm -v $(pwd):/workspace audientia:latest help
   ```

3. **Start interactive shell:**
   ```bash
   docker run --rm -it -v $(pwd):/workspace audientia:latest shell
   ```

4. **Using docker-compose:**
   ```bash
   # Build and start build container
   docker-compose up audientia-build

   # Run tests
   docker-compose --profile test up audientia-test

   # Start development environment
   docker-compose --profile dev up audientia-dev
   ```

### Podman

1. **Build the container:**
   ```bash
   podman build -f Containerfile -t audientia:latest .
   ```

2. **Run a command:**
   ```bash
   podman run --rm -v $(pwd):/workspace audientia:latest help
   ```

3. **Start interactive shell:**
   ```bash
   podman run --rm -it -v $(pwd):/workspace audientia:latest shell
   ```

4. **Using podman-compose:**
   ```bash
   # Build and start build container
   podman-compose -f podman-compose.yml up audientia-build

   # Run tests
   podman-compose -f podman-compose.yml --profile test up audientia-test

   # Start development environment
   podman-compose -f podman-compose.yml --profile dev up audientia-dev
   ```

## Container Commands

The container provides several commands via the entrypoint script:

### `help`
Show help message with available commands.

```bash
docker run --rm -v $(pwd):/workspace audientia:latest help
```

### `test`
Run pre-commit checks and tests.

```bash
docker run --rm -v $(pwd):/workspace audientia:latest test
```

### `build`
Generate Xcode project (requires XcodeGen and macOS).

```bash
docker run --rm -v $(pwd):/workspace audientia:latest build
```

### `setup`
Install dependencies and setup environment.

```bash
docker run --rm -v $(pwd):/workspace audientia:latest setup
```

### `shell` or `bash`
Start interactive shell.

```bash
docker run --rm -it -v $(pwd):/workspace audientia:latest shell
```

### `ffmpeg`
Check FFmpeg installation and version.

```bash
docker run --rm -v $(pwd):/workspace audientia:latest ffmpeg
```

### `xcodegen`
Check XcodeGen installation.

```bash
docker run --rm -v $(pwd):/workspace audientia:latest xcodegen
```

## Container Services

### audientia-build
Main build container with all tools.

```bash
docker-compose up audientia-build
```

### audientia-test
Test execution container.

```bash
docker-compose --profile test up audientia-test
```

### audientia-dev
Development environment with interactive shell.

```bash
docker-compose --profile dev up audientia-dev
```

## Container Contents

The container includes:

- **Base Image**: Ubuntu 24.04 LTS (Noble) - latest LTS as of 2025
- **Build Tools**: `build-essential`, `cmake`, `pkg-config`
- **Version Control**: `git`
- **FFmpeg**: Latest version from Ubuntu repositories (for test fixtures)
- **XcodeGen**: Latest version via RubyGems (project generation tool)
- **Ruby**: Required for XcodeGen
- **Python3**: Python 3.12+ with pip and venv support
- **Development Libraries**: SSL, curl, XML libraries

## Volume Mounts

The containers mount:
- **Source code**: `.:/workspace` - Your project directory
- **Build directory**: `./build:/workspace/build` - Build artifacts (optional)

## Environment Variables

- `LANG=en_US.UTF-8`
- `LC_ALL=en_US.UTF-8`
- `SWIFT_VERSION=5.9` (build arg)

## Limitations

### macOS App Development
- **Cannot build macOS apps**: Docker/Podman containers run Linux, not macOS
- **Requires macOS host**: For actual app builds, use macOS with Xcode
- **CI/CD**: Use macOS runners (GitHub Actions, etc.) for builds

### What Containers Are Good For
- ✅ Development tooling setup
- ✅ Test fixture generation (FFmpeg)
- ✅ Pre-commit checks
- ✅ Environment consistency
- ✅ CI/CD automation (on macOS runners)

### What Containers Cannot Do
- ❌ Build macOS applications (requires Xcode on macOS)
- ❌ Run macOS GUI applications
- ❌ Execute Xcode build commands (requires macOS)

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v3
      
      - name: Build container
        run: docker build -t audientia:latest .
      
      - name: Run tests
        run: docker run --rm -v $(pwd):/workspace audientia:latest test
      
      - name: Build project
        run: |
          xcodegen generate
          xcodebuild test -project Audientia.xcodeproj -scheme Audientia
```

## Troubleshooting

### Container won't start
- Check Docker/Podman is running: `docker ps` or `podman ps`
- Verify image is built: `docker images | grep audientia`

### Permission errors
- On Linux, may need to adjust volume mount permissions
- Use `:Z` suffix for SELinux: `-v $(pwd):/workspace:Z`

### FFmpeg not found
- Container includes FFmpeg, but verify with: `docker run --rm audientia:latest ffmpeg`

### Xcode project generation fails
- Requires XcodeGen: `docker run --rm audientia:latest xcodegen`
- Project generation requires macOS host

## Best Practices

1. **Use volumes for source code**: Mount your project directory
2. **Persist build artifacts**: Mount build directory if needed
3. **Use profiles**: Separate dev, test, and build environments
4. **Keep containers updated**: Rebuild periodically for security updates
5. **Use .dockerignore**: Exclude unnecessary files from build context

## Related Documentation

- [`README.md`](../README.md) - Project overview
- [`Configuration/SETUP.md`](../Configuration/SETUP.md) - Development setup
- [`Documentation/13-ffmpeg-integration.md`](13-ffmpeg-integration.md) - FFmpeg details

## Support

For issues or questions about containerization:
- **Email**: support@cycleruncode.club
- **GitHub Issues**: [Create an issue](https://github.com/vksvicky/Audientia/issues)

