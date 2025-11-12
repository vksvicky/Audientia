#!/bin/bash
# docker-entrypoint.sh for Audientia
# 
# Entrypoint script for Docker/Podman containers
# Provides commands for building, testing, and development
#
# Copyright © 2025 CycleRunCode Club. All rights reserved.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print usage
usage() {
    cat << EOF
Audientia Container Commands

Usage: docker-entrypoint.sh [command] [options]

Commands:
    help              Show this help message
    test              Run pre-commit checks and tests
    build             Generate Xcode project (requires macOS/Xcode)
    setup             Install dependencies and setup environment
    shell             Start interactive shell
    ffmpeg            Check FFmpeg installation and version
    xcodegen          Check XcodeGen installation

Examples:
    # Show help
    docker-entrypoint.sh help

    # Run tests
    docker-entrypoint.sh test

    # Start interactive shell
    docker-entrypoint.sh shell

    # Check FFmpeg
    docker-entrypoint.sh ffmpeg

Note: Actual macOS app builds require macOS and Xcode.
This container provides tooling and test environment.

EOF
}

# Check FFmpeg
check_ffmpeg() {
    echo -e "${GREEN}Checking FFmpeg installation...${NC}"
    if command -v ffmpeg &> /dev/null; then
        echo -e "${GREEN}✓ FFmpeg is installed${NC}"
        ffmpeg -version | head -n 1
        echo ""
        echo "Available codecs:"
        ffmpeg -codecs 2>/dev/null | grep -E "(flac|vorbis|opus|alac|ape|wavpack|ac3|dts)" || echo "  (codec list truncated)"
    else
        echo -e "${RED}✗ FFmpeg is not installed${NC}"
        return 1
    fi
}

# Check XcodeGen
check_xcodegen() {
    echo -e "${GREEN}Checking XcodeGen installation...${NC}"
    if command -v xcodegen &> /dev/null; then
        echo -e "${GREEN}✓ XcodeGen is installed${NC}"
        xcodegen --version
    else
        echo -e "${RED}✗ XcodeGen is not installed${NC}"
        return 1
    fi
}

# Setup environment
setup() {
    echo -e "${GREEN}Setting up Audientia development environment...${NC}"
    
    # Check prerequisites
    check_ffmpeg || echo -e "${YELLOW}Warning: FFmpeg not found${NC}"
    check_xcodegen || echo -e "${YELLOW}Warning: XcodeGen not found${NC}"
    
    echo -e "${GREEN}Environment setup complete${NC}"
}

# Run tests
run_tests() {
    echo -e "${GREEN}Running Audientia tests...${NC}"
    
    # Run pre-commit checks if script exists
    if [ -f "/workspace/Scripts/pre_commit_checks.sh" ]; then
        echo -e "${YELLOW}Running pre-commit checks...${NC}"
        bash /workspace/Scripts/pre_commit_checks.sh || {
            echo -e "${RED}Pre-commit checks failed${NC}"
            return 1
        }
    fi
    
    echo -e "${GREEN}Note: Full test suite requires macOS and Xcode${NC}"
    echo -e "${GREEN}This container provides tooling and environment checks${NC}"
}

# Generate Xcode project (requires macOS/Xcode)
generate_project() {
    echo -e "${GREEN}Generating Xcode project...${NC}"
    
    if ! check_xcodegen; then
        echo -e "${RED}Error: XcodeGen is required to generate project${NC}"
        return 1
    fi
    
    if [ ! -f "/workspace/project.yml" ]; then
        echo -e "${RED}Error: project.yml not found${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Note: Xcode project generation requires macOS${NC}"
    echo -e "${YELLOW}This command will work if running on macOS host${NC}"
    
    cd /workspace
    xcodegen generate || {
        echo -e "${RED}Error: Failed to generate Xcode project${NC}"
        return 1
    }
    
    echo -e "${GREEN}✓ Xcode project generated${NC}"
}

# Main command handler
main() {
    case "${1:-help}" in
        help|--help|-h)
            usage
            ;;
        test)
            run_tests
            ;;
        build)
            generate_project
            ;;
        setup)
            setup
            ;;
        shell|bash)
            exec /bin/bash
            ;;
        ffmpeg)
            check_ffmpeg
            ;;
        xcodegen)
            check_xcodegen
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            echo ""
            usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"

