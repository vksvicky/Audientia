# Dockerfile for Audientia - Build and Test Environment
# 
# This container provides a consistent environment for building and testing
# the Audientia macOS application. Note: macOS apps require macOS to run,
# so this container is primarily for CI/CD and development tooling.
#
# Copyright © 2025 CycleRunCode Club. All rights reserved.

# Use macOS base image if available, otherwise use Ubuntu for tooling
# Note: For actual macOS app builds, you'll need macOS runners
# Using Ubuntu 24.04 LTS (Noble) - latest LTS as of 2025
FROM ubuntu:24.04

# Metadata
LABEL maintainer="support@cycleruncode.club"
LABEL description="Audientia build and test environment"
LABEL version="1.0"

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install system dependencies
RUN apt-get update && apt-get install -y \
    # Build tools
    build-essential \
    cmake \
    pkg-config \
    git \
    curl \
    wget \
    # Development libraries
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    # FFmpeg and audio codecs (for test fixtures and development)
    ffmpeg \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    # Additional tools
    ruby \
    ruby-dev \
    python3 \
    python3-pip \
    python3-venv \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Install XcodeGen (for project generation)
# Note: XcodeGen requires Ruby, which is installed above
# Install latest version of XcodeGen
RUN gem install xcodegen --no-document

# Note: Swift is not installed in this container
# For macOS app development, use Xcode on macOS
# This container focuses on build tooling and test fixtures

# Create working directory
WORKDIR /workspace

# Copy project files
COPY . /workspace/

# Set up entrypoint script
COPY Scripts/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default command
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["help"]

