#!/bin/bash

# Generate Test Audio Fixtures
# This script generates valid, invalid, and error sample files for all supported audio formats

set -e

FIXTURES_DIR="Tests/AudioCoreTests/Fixtures/Audio"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper function to convert to uppercase (portable across bash and zsh)
to_upper() {
    echo "$1" | tr '[:lower:]' '[:upper:]'
}

echo -e "${BLUE}🎵 Generating Audio Test Fixtures${NC}\n"

# Create directory structure if it doesn't exist
mkdir -p "${FIXTURES_DIR}"/{mp3,flac,aac,wav,m4a,ogg,opus,alac,ape,aiff,caf,mp4,wma,webm,flv,ac3,dts,dsf,dff,wv}

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}⚠️  ffmpeg not found. Please install ffmpeg to generate valid audio files.${NC}"
    echo "Install with: brew install ffmpeg"
    exit 1
fi

# Function to generate valid audio file with specific sample rate
generate_valid() {
    local format=$1
    local codec=$2
    local extension=$3
    local sample_rate=$4
    local sample_rate_label=$5
    local output="${FIXTURES_DIR}/${format}/valid_${sample_rate_label}${extension}"
    
    echo -e "${GREEN}✓ Generating valid $(to_upper "$format") file at ${sample_rate}Hz...${NC}" >&2
    
    case $format in
        mp3)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -b:a 128k -y "$output" 2>/dev/null
            ;;
        flac)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        aac)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        m4a)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        wav)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        aiff)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        caf)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        mp4)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        ogg)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a libvorbis -y "$output" 2>/dev/null
            ;;
        opus)
            # Opus supports 8-48kHz, clamp to valid range
            local opus_rate=$sample_rate
            if [ "$opus_rate" -lt 8000 ]; then
                opus_rate=8000
            elif [ "$opus_rate" -gt 48000 ]; then
                opus_rate=48000
            fi
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$opus_rate" -ac 2 -c:a libopus -y "$output" 2>/dev/null
            ;;
        alac)
            # ALAC needs ipod format (M4A container) - generate as .m4a then rename if needed
            local temp_output="${output%.alac}.m4a"
            local error_log
            error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
            # Run ffmpeg and check both exit code and file creation
            if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a alac -f ipod -y "$temp_output" 2>"$error_log" && [ -f "$temp_output" ]; then
                # If output is .alac, rename the .m4a file to .alac
                if [ "$temp_output" != "$output" ]; then
                    mv "$temp_output" "$output" 2>/dev/null || cp "$temp_output" "$output" 2>/dev/null || true
                    rm -f "$temp_output" 2>/dev/null || true
                fi
            else
                echo -e "${YELLOW}⚠️  ALAC encoding failed for $(to_upper "$format"), skipping...${NC}" >&2
                # Show last few lines of error for debugging
                if [ -s "$error_log" ]; then
                    tail -2 "$error_log" | sed 's/^/    /' >&2
                fi
            fi
            rm -f "$error_log" 2>/dev/null || true
            ;;
        ape)
            # APE encoder may not be available in all ffmpeg builds
            # Check if APE encoder is available (look for encoder, not just decoder)
            if ffmpeg -encoders 2>/dev/null | grep -qE "^\s*A.*ape" || true; then
                # Try to encode APE - note: APE format support varies by ffmpeg build
                local error_log
                error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
                # Run ffmpeg and check both exit code and file creation
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a ape -y "$output" 2>"$error_log" && [ -f "$output" ]; then
                    # Success - file was created
                    :
                else
                    echo -e "${YELLOW}⚠️  APE encoding failed (format may not be supported), skipping...${NC}" >&2
                    # Show last few lines of error for debugging
                    if [ -s "$error_log" ]; then
                        tail -2 "$error_log" | sed 's/^/    /' >&2
                    fi
                fi
                rm -f "$error_log" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  APE encoder not available in this ffmpeg build, skipping...${NC}" >&2
                echo -e "    ${YELLOW}Note: APE encoding requires ffmpeg built with Monkey's Audio encoder support${NC}" >&2
            fi
            ;;
        wma)
            # WMA encoding may require specific codec
            if ffmpeg -encoders 2>/dev/null | grep -qE "^\s*A.*wmav1\|wmav2" || true; then
                local error_log
                error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a wmav2 -y "$output" 2>"$error_log" && [ -f "$output" ]; then
                    :
                else
                    echo -e "${YELLOW}⚠️  WMA encoding failed, skipping...${NC}" >&2
                    if [ -s "$error_log" ]; then
                        tail -2 "$error_log" | sed 's/^/    /' >&2
                    fi
                fi
                rm -f "$error_log" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  WMA encoder not available, skipping...${NC}" >&2
            fi
            ;;
        webm)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a libopus -y "$output" 2>/dev/null
            ;;
        flv)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        ac3)
            if ffmpeg -encoders 2>/dev/null | grep -qE "^\s*A.*ac3" || true; then
                local error_log
                error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a ac3 -b:a 192k -y "$output" 2>"$error_log" && [ -f "$output" ]; then
                    :
                else
                    echo -e "${YELLOW}⚠️  AC3 encoding failed, skipping...${NC}" >&2
                    if [ -s "$error_log" ]; then
                        tail -2 "$error_log" | sed 's/^/    /' >&2
                    fi
                fi
                rm -f "$error_log" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  AC3 encoder not available, skipping...${NC}" >&2
            fi
            ;;
        dts)
            if ffmpeg -encoders 2>/dev/null | grep -qE "^\s*A.*dca" || true; then
                local error_log
                error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a dca -b:a 1536k -y "$output" 2>"$error_log" && [ -f "$output" ]; then
                    :
                else
                    echo -e "${YELLOW}⚠️  DTS encoding failed, skipping...${NC}" >&2
                    if [ -s "$error_log" ]; then
                        tail -2 "$error_log" | sed 's/^/    /' >&2
                    fi
                fi
                rm -f "$error_log" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  DTS encoder not available, skipping...${NC}" >&2
            fi
            ;;
        dsf)
            # DSD Stream File (DSF) - very high sample rates (2.8224MHz, 5.6448MHz)
            # DSD uses 1-bit encoding, sample rates are in Hz: 2822400 (DSD64), 5644800 (DSD128)
            # ffmpeg doesn't support DSF output, so we create a minimal valid DSF file with proper header
            # DSF format: "DSD " (4 bytes) + file size + "fmt " chunk + "data" chunk
            echo -e "${GREEN}✓ Creating minimal valid DSF file at ${sample_rate}Hz...${NC}" >&2
            
            # Calculate some basic values
            local channels=2
            local bits_per_sample=1  # DSD is 1-bit
            local block_size=4096
            local data_size=8192  # Minimal data size for testing
            
            # DSF header structure:
            # - "DSD " (4 bytes) - magic
            # - File size - 8 (8 bytes, little-endian)
            # - "fmt " chunk (28 bytes)
            # - "data" chunk header + data
            
            {
                # DSF header: "DSD " + file size
                printf 'DSD '
                # File size will be calculated: header (12) + fmt (28) + data header (12) + data
                local total_size=$((12 + 28 + 12 + data_size))
                # Write file size as 64-bit little-endian
                printf "\\$(printf '%02x' $((total_size & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 32) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 40) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 48) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 56) & 0xFF)))"
                
                # fmt chunk: "fmt " + size (28) + format data
                printf 'fmt '
                printf "\\x1C\\x00\\x00\\x00\\x00\\x00\\x00\\x00"  # fmt chunk size (28, little-endian)
                printf "\\x01\\x00\\x00\\x00"  # Format version (1)
                printf "\\x00\\x00\\x00\\x00"  # Format ID (0 = DSD raw)
                # Channel type (0 = stereo)
                printf "\\x02\\x00\\x00\\x00"  # Channels (2)
                # Sample rate (little-endian)
                printf "\\$(printf '%02x' $((sample_rate & 0xFF)))"
                printf "\\$(printf '%02x' $(((sample_rate >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $(((sample_rate >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((sample_rate >> 24) & 0xFF)))"
                printf "\\x00\\x00\\x00\\x00"  # Bits per sample (1, but stored as 0 in some implementations)
                printf "\\x00\\x00\\x00\\x00"  # Sample count (can be 0 for minimal file)
                
                # data chunk: "data" + size + data
                printf 'data'
                # Data chunk size (little-endian)
                printf "\\$(printf '%02x' $((data_size & 0xFF)))"
                printf "\\$(printf '%02x' $(((data_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $(((data_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((data_size >> 24) & 0xFF)))"
                printf "\\x00\\x00\\x00\\x00"
                # Minimal DSD data (alternating bits pattern for testing)
                # DSD data is packed: 8 samples per byte, LSB first
                for i in $(seq 1 $((data_size / 8))); do
                    printf "\\xAA"  # 10101010 pattern
                done
            } > "$output" 2>/dev/null || {
                echo -e "${YELLOW}⚠️  DSF file creation failed, creating minimal header...${NC}" >&2
                # Fallback: minimal valid DSF header
                printf 'DSD \x00\x00\x00\x00\x00\x00\x00\x00fmt \x1C\x00\x00\x00\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            }
            ;;
        dff)
            # DSDIFF (DFF) format - similar to DSF but different container
            # DSD uses 1-bit encoding, sample rates are in Hz: 2822400 (DSD64), 5644800 (DSD128)
            # ffmpeg doesn't support DFF output, so we create a minimal valid DFF file with proper header
            # DFF format: "FRM8" (4 bytes) + file size + "DSD " chunk + "FVER" chunk + "PROP" chunk + "DSD " data chunk
            echo -e "${GREEN}✓ Creating minimal valid DFF file at ${sample_rate}Hz...${NC}" >&2
            
            local channels=2
            local data_size=8192  # Minimal data size for testing
            
            {
                # DFF header: "FRM8" + file size
                printf 'FRM8'
                # File size will be calculated
                local total_size=$((12 + 16 + 12 + 12 + 12 + data_size))  # Approximate
                # Write file size as 64-bit big-endian (DFF uses big-endian)
                printf "\\$(printf '%02x' $(((total_size >> 56) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 48) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 40) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 32) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((total_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $((total_size & 0xFF)))"
                
                # DSD chunk: "DSD " + size (big-endian)
                printf 'DSD '
                local dsd_size=$((8 + 12 + 12 + 12 + data_size))
                printf "\\$(printf '%02x' $(((dsd_size >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((dsd_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((dsd_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $((dsd_size & 0xFF)))"
                
                # FVER chunk: "FVER" + size (4) + version (4 bytes, big-endian)
                printf 'FVER'
                printf "\\x00\\x00\\x00\\x04"  # Size (4)
                printf "\\x00\\x00\\x00\\x01"  # Version 1
                
                # PROP chunk: "PROP" + size + "SND " + format info
                printf 'PROP'
                local prop_size=36
                printf "\\$(printf '%02x' $(((prop_size >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((prop_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((prop_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $((prop_size & 0xFF)))"
                printf 'SND '
                # Sample rate (big-endian)
                printf "\\$(printf '%02x' $(((sample_rate >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((sample_rate >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((sample_rate >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $((sample_rate & 0xFF)))"
                # Channels (big-endian)
                printf "\\x00\\x00\\x00\\x02"  # 2 channels
                # Sample count (big-endian, can be 0)
                printf "\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00"
                # Block size (big-endian)
                printf "\\x00\\x00\\x10\\x00"  # 4096
                # Reserved
                printf "\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00\\x00"
                
                # DSD data chunk: "DSD " + size (big-endian) + data
                printf 'DSD '
                printf "\\$(printf '%02x' $(((data_size >> 24) & 0xFF)))"
                printf "\\$(printf '%02x' $(((data_size >> 16) & 0xFF)))"
                printf "\\$(printf '%02x' $(((data_size >> 8) & 0xFF)))"
                printf "\\$(printf '%02x' $((data_size & 0xFF)))"
                # Minimal DSD data (alternating bits pattern)
                for i in $(seq 1 $((data_size / 8))); do
                    printf "\\xAA"  # 10101010 pattern
                done
            } > "$output" 2>/dev/null || {
                echo -e "${YELLOW}⚠️  DFF file creation failed, creating minimal header...${NC}" >&2
                # Fallback: minimal valid DFF header
                printf 'FRM8\x00\x00\x00\x00\x00\x00\x00\x00DSD ' > "$output" 2>/dev/null || true
            }
            ;;
        wv)
            # WavPack encoding
            if ffmpeg -encoders 2>/dev/null | grep -qE "^\s*A.*wavpack" || true; then
                local error_log
                error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar "$sample_rate" -ac 2 -c:a wavpack -y "$output" 2>"$error_log" && [ -f "$output" ]; then
                    :
                else
                    echo -e "${YELLOW}⚠️  WavPack encoding failed, skipping...${NC}" >&2
                    if [ -s "$error_log" ]; then
                        tail -2 "$error_log" | sed 's/^/    /' >&2
                    fi
                fi
                rm -f "$error_log" 2>/dev/null || true
            else
                echo -e "${YELLOW}⚠️  WavPack encoder not available, skipping...${NC}" >&2
            fi
            ;;
    esac
}

# Function to generate invalid/corrupt file (empty file)
generate_invalid_empty() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_empty${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (empty) $(to_upper "$format") file...${NC}" >&2
    touch "$output" 2>/dev/null || true
    # Ensure it's truly empty
    : > "$output" 2>/dev/null || true
}

# Function to generate invalid/corrupt file (wrong header)
generate_invalid_header() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_header${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (wrong header) $(to_upper "$format") file...${NC}" >&2
    # Create file with garbage data that looks nothing like the format
    echo "INVALID_HEADER_DATA_12345" > "$output" 2>/dev/null || printf 'INVALID_HEADER_DATA_12345' > "$output" 2>/dev/null || true
}

# Helper function to find first valid file for a format
find_first_valid_file() {
    local format=$1
    local extension=$2
    # Look for any valid file with any sample rate
    for file in "${FIXTURES_DIR}/${format}"/valid_*"${extension}"; do
        if [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    # Fallback: look for just "valid" without sample rate (backward compatibility)
    local fallback="${FIXTURES_DIR}/${format}/valid${extension}"
    if [ -f "$fallback" ]; then
        echo "$fallback"
        return 0
    fi
    return 1
}

# Function to generate corrupt file (valid header but corrupted payload)
generate_corrupt_payload() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_payload${extension}"
    local valid_file
    valid_file=$(find_first_valid_file "$format" "$extension") || valid_file=""
    
    echo -e "${YELLOW}⚠️  Generating corrupt (valid header, bad payload) $(to_upper "$format") file...${NC}" >&2
    
    if [ -f "$valid_file" ] && [ -s "$valid_file" ]; then
        # Copy first 512 bytes (header) then add corrupted data
        head -c 512 "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=512 of="$output" 2>/dev/null || true
        # Append corrupted/random data
        dd if=/dev/urandom bs=1024 count=1 >> "$output" 2>/dev/null || head -c 1024 /dev/urandom >> "$output" 2>/dev/null || printf 'CORRUPTED_DATA' >> "$output"
    else
        # Create file with correct magic bytes but corrupted rest (fallback for all formats)
        case $format in
            mp3)
                printf '\xFF\xFB\x90\x00' > "$output" 2>/dev/null || true  # Valid MP3 sync word
                ;;
            flac)
                printf 'fLaC' > "$output" 2>/dev/null || true  # Valid FLAC magic
                ;;
            wav)
                printf 'RIFF\x24\x00\x00\x00WAVE' > "$output" 2>/dev/null || true  # Valid RIFF header start
                ;;
            aiff)
                printf 'FORM\x00\x00\x00\x00AIFF' > "$output" 2>/dev/null || true  # Valid AIFF header
                ;;
            m4a|mp4)
                printf '\x00\x00\x00\x20ftypmp4 ' > "$output" 2>/dev/null || true  # Valid ftyp atom start
                ;;
            ogg)
                printf 'OggS\x00\x02' > "$output" 2>/dev/null || true  # Valid OggS magic
                ;;
            opus)
                printf 'OggS\x00\x02' > "$output" 2>/dev/null || true  # Opus uses Ogg container
                ;;
            alac)
                printf '\x00\x00\x00\x20ftypM4A ' > "$output" 2>/dev/null || true  # ALAC uses M4A container
                ;;
            ape)
                printf 'MAC ' > "$output" 2>/dev/null || true  # APE magic
                ;;
            aac)
                printf '\xFF\xF1' > "$output" 2>/dev/null || true  # AAC ADTS header start
                ;;
            wma)
                printf '\x30\x26\xB2\x75\x8E\x66\xCF\x11' > "$output" 2>/dev/null || true  # WMA GUID
                ;;
            webm)
                printf '\x1A\x45\xDF\xA3' > "$output" 2>/dev/null || true  # WebM EBML header
                ;;
            flv)
                printf 'FLV\x01' > "$output" 2>/dev/null || true  # FLV header
                ;;
            ac3)
                printf '\x0B\x77' > "$output" 2>/dev/null || true  # AC3 sync word
                ;;
            dts)
                printf '\x7F\xFE\x80\x01' > "$output" 2>/dev/null || true  # DTS sync word
                ;;
            dsf|dff)
                printf 'DSD ' > "$output" 2>/dev/null || true  # DSD magic
                ;;
            wv)
                printf 'wvpk' > "$output" 2>/dev/null || true  # WavPack magic
                ;;
            caf)
                printf 'caff' > "$output" 2>/dev/null || true  # CAF magic
                ;;
            *)
                printf 'VALID_MAGIC' > "$output" 2>/dev/null || true
                ;;
        esac
        # Append corrupted data
        dd if=/dev/urandom bs=1024 count=1 >> "$output" 2>/dev/null || head -c 1024 /dev/urandom >> "$output" 2>/dev/null || printf 'CORRUPTED_DATA' >> "$output"
    fi
}

# Function to generate file with corrupted magic bytes
generate_corrupt_magic() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_magic${extension}"
    local valid_file
    valid_file=$(find_first_valid_file "$format" "$extension") || valid_file=""
    
    echo -e "${YELLOW}⚠️  Generating corrupt (wrong magic bytes) $(to_upper "$format") file...${NC}" >&2
    
    if [ -f "$valid_file" ] && [ -s "$valid_file" ]; then
        # Copy the file but corrupt the first few bytes (magic bytes)
        cp "$valid_file" "$output" 2>/dev/null || true
        # Corrupt first 4-8 bytes depending on format
        case $format in
            mp3)
                # Corrupt MP3 sync word
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null || printf '\x00\x00\x00\x00' > "$output"
                ;;
            flac)
                # Corrupt FLAC magic
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null || printf '\x00\x00\x00\x00' > "$output"
                ;;
            wav|aiff)
                # Corrupt RIFF header
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null || printf '\x00\x00\x00\x00' > "$output"
                ;;
            *)
                # Corrupt first 4 bytes
                printf '\xFF\xFF\xFF\xFF' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null || printf '\xFF\xFF\xFF\xFF' > "$output"
                ;;
        esac
    else
        # Create file with wrong magic bytes (fallback for all formats)
        case $format in
            mp3)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of MP3 sync
                ;;
            flac)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'fLaC'
                ;;
            wav)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'RIFF'
                ;;
            aiff)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'FORM'
                ;;
            m4a|mp4)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            ogg|opus)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'OggS'
                ;;
            alac)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            ape)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'MAC '
                ;;
            aac)
                printf '\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            wma)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            webm)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of EBML
                ;;
            flv)
                printf '\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'FLV'
                ;;
            ac3)
                printf '\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            dts)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic
                ;;
            dsf|dff)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'DSD '
                ;;
            wv)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'wvpk'
                ;;
            caf)
                printf '\x00\x00\x00\x00' > "$output" 2>/dev/null || true  # Wrong magic instead of 'caff'
                ;;
            *)
                printf '\xFF\xFF\xFF\xFF\x00\x00\x00\x00CORRUPT_MAGIC' > "$output" 2>/dev/null || true
                ;;
        esac
    fi
}

# Function to generate file with valid header but no audio data
generate_no_audio_data() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_no_audio_data${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (header only, no audio) $(to_upper "$format") file...${NC}" >&2
    
    # Create minimal valid header with no actual audio data (support all formats)
    case $format in
        mp3)
            # Minimal MP3 header (ID3v2 + frame sync)
            printf 'ID3\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            printf '\xFF\xFB\x90\x00' >> "$output" 2>/dev/null || true
            ;;
        flac)
            # FLAC header only
            printf 'fLaC\x01\x00\x00\x00' > "$output" 2>/dev/null || true
            ;;
        wav)
            # Minimal WAV header
            printf 'RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x02\x00' > "$output" 2>/dev/null || true
            printf '\x44\xAC\x00\x00\x10\xB1\x02\x00\x04\x00\x10\x00data\x00\x00\x00\x00' >> "$output" 2>/dev/null || true
            ;;
        aiff)
            # Minimal AIFF header
            printf 'FORM\x00\x00\x00\x00AIFFCOMM\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            ;;
        m4a|mp4)
            # Minimal MP4/M4A header
            printf '\x00\x00\x00\x20ftypmp4 \x00\x00\x00\x00mp4 ' > "$output" 2>/dev/null || true
            ;;
        ogg)
            # Minimal Ogg header
            printf 'OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            ;;
        opus)
            # Opus uses Ogg container
            printf 'OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            ;;
        alac)
            # ALAC uses M4A container
            printf '\x00\x00\x00\x20ftypM4A \x00\x00\x00\x00M4A ' > "$output" 2>/dev/null || true
            ;;
        ape)
            # APE header
            printf 'MAC ' > "$output" 2>/dev/null || true
            ;;
        aac)
            # AAC ADTS header
            printf '\xFF\xF1' > "$output" 2>/dev/null || true
            ;;
        wma)
            # WMA GUID header
            printf '\x30\x26\xB2\x75\x8E\x66\xCF\x11' > "$output" 2>/dev/null || true
            ;;
        webm)
            # WebM EBML header
            printf '\x1A\x45\xDF\xA3' > "$output" 2>/dev/null || true
            ;;
        flv)
            # FLV header
            printf 'FLV\x01\x00\x00\x00\x00' > "$output" 2>/dev/null || true
            ;;
        ac3)
            # AC3 sync word
            printf '\x0B\x77' > "$output" 2>/dev/null || true
            ;;
        dts)
            # DTS sync word
            printf '\x7F\xFE\x80\x01' > "$output" 2>/dev/null || true
            ;;
        dsf|dff)
            # DSD header
            printf 'DSD ' > "$output" 2>/dev/null || true
            ;;
        wv)
            # WavPack header
            printf 'wvpk' > "$output" 2>/dev/null || true
            ;;
        caf)
            # CAF header
            printf 'caff' > "$output" 2>/dev/null || true
            ;;
        *)
            printf 'HEADER_ONLY_NO_DATA' > "$output" 2>/dev/null || true
            ;;
    esac
}

# Function to generate file with byte corruption in middle
generate_corrupt_middle() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_middle${extension}"
    local valid_file
    valid_file=$(find_first_valid_file "$format" "$extension") || valid_file=""
    
    echo -e "${YELLOW}⚠️  Generating corrupt (byte corruption in middle) $(to_upper "$format") file...${NC}" >&2
    
    if [ -f "$valid_file" ] && [ -s "$valid_file" ]; then
        # Get file size
        local file_size=$(stat -f%z "$valid_file" 2>/dev/null || stat -c%s "$valid_file" 2>/dev/null || wc -c < "$valid_file" 2>/dev/null || echo 1000)
        local middle_pos=$((file_size / 2))
        local corrupt_size=100
        local end_pos=$((middle_pos + corrupt_size))
        
        # Corrupt bytes in the middle using head/tail approach (more portable)
        if [ "$middle_pos" -gt 0 ] && [ "$end_pos" -lt "$file_size" ]; then
            # Take first part, add corruption, then append rest
            head -c $middle_pos "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=$middle_pos of="$output" 2>/dev/null || true
            # Add corrupted bytes
            dd if=/dev/zero bs=1 count=$corrupt_size >> "$output" 2>/dev/null || head -c $corrupt_size /dev/zero >> "$output" 2>/dev/null || printf '\x00%.0s' {1..100} >> "$output"
            # Calculate remaining bytes
            local remaining=$((file_size - end_pos))
            if [ "$remaining" -gt 0 ]; then
                # Skip to end_pos and take remaining
                tail -c +$((end_pos + 1)) "$valid_file" >> "$output" 2>/dev/null || {
                    # Fallback: use dd to skip and copy
                    dd if="$valid_file" bs=1 skip=$end_pos >> "$output" 2>/dev/null || true
                }
            fi
        else
            # File too small, just corrupt what we can
            cp "$valid_file" "$output" 2>/dev/null || true
            # Corrupt from start if file is very small
            if [ "$file_size" -lt 200 ]; then
                printf '\x00' | dd of="$output" bs=1 count=$((file_size / 2)) conv=notrunc 2>/dev/null || true
            fi
        fi
    else
        # Create a file with some valid structure but corruption in middle (fallback)
        # Create header
        case $format in
            mp3)
                printf '\xFF\xFB\x90\x00' > "$output"
                ;;
            flac)
                printf 'fLaC' > "$output"
                ;;
            wav)
                printf 'RIFF\x24\x00\x00\x00WAVE' > "$output"
                ;;
            *)
                printf 'VALID_HEADER' > "$output"
                ;;
        esac
        # Add some valid data
        printf 'VALID_DATA' >> "$output"
        # Add corruption in middle
        dd if=/dev/zero bs=1 count=100 >> "$output" 2>/dev/null || head -c 100 /dev/zero >> "$output" 2>/dev/null || printf '\x00%.0s' {1..100} >> "$output"
        # Add more valid data
        printf 'VALID_END' >> "$output"
    fi
}

# Function to generate truncated file
generate_truncated() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_truncated${extension}"
    local valid_file
    valid_file=$(find_first_valid_file "$format" "$extension") || valid_file=""
    
    echo -e "${YELLOW}⚠️  Generating truncated $(to_upper "$format") file...${NC}" >&2
    
    if [ -f "$valid_file" ] && [ -s "$valid_file" ]; then
        # Take only first 100 bytes of valid file
        head -c 100 "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=100 of="$output" 2>/dev/null || true
    else
        # Create minimal file with partial header (fallback for all formats)
        case $format in
            mp3)
                printf '\xFF\xFB' > "$output" 2>/dev/null || true  # Partial MP3 header
                ;;
            flac)
                printf 'fLaC' > "$output" 2>/dev/null || true  # FLAC magic but incomplete
                ;;
            wav)
                printf 'RIFF' > "$output" 2>/dev/null || true  # Partial WAV header
                ;;
            aiff)
                printf 'FORM' > "$output" 2>/dev/null || true  # Partial AIFF header
                ;;
            m4a|mp4)
                printf '\x00\x00\x00' > "$output" 2>/dev/null || true  # Partial MP4 header
                ;;
            ogg|opus)
                printf 'OggS' > "$output" 2>/dev/null || true  # Partial Ogg header
                ;;
            alac)
                printf '\x00\x00\x00' > "$output" 2>/dev/null || true  # Partial ALAC header
                ;;
            ape)
                printf 'MAC' > "$output" 2>/dev/null || true  # Partial APE header
                ;;
            aac)
                printf '\xFF' > "$output" 2>/dev/null || true  # Partial AAC header
                ;;
            wma)
                printf '\x30\x26' > "$output" 2>/dev/null || true  # Partial WMA header
                ;;
            webm)
                printf '\x1A\x45' > "$output" 2>/dev/null || true  # Partial WebM header
                ;;
            flv)
                printf 'FLV' > "$output" 2>/dev/null || true  # Partial FLV header
                ;;
            ac3)
                printf '\x0B' > "$output" 2>/dev/null || true  # Partial AC3 header
                ;;
            dts)
                printf '\x7F' > "$output" 2>/dev/null || true  # Partial DTS header
                ;;
            dsf|dff)
                printf 'DSD' > "$output" 2>/dev/null || true  # Partial DSD header
                ;;
            wv)
                printf 'wvp' > "$output" 2>/dev/null || true  # Partial WavPack header
                ;;
            caf)
                printf 'caf' > "$output" 2>/dev/null || true  # Partial CAF header
                ;;
            *)
                printf 'INCOMPLETE' > "$output" 2>/dev/null || true
                ;;
        esac
    fi
}

# Function to generate zero-size file
generate_zero_size() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_zero_size${extension}"
    
    echo -e "${YELLOW}⚠️  Generating zero-size $(to_upper "$format") file...${NC}" >&2
    touch "$output" 2>/dev/null || true
    # Ensure it's truly empty
    : > "$output" 2>/dev/null || true
    # Verify it's zero size
    if [ -f "$output" ]; then
        local size=$(stat -f%z "$output" 2>/dev/null || stat -c%s "$output" 2>/dev/null || wc -c < "$output" 2>/dev/null || echo 0)
        if [ "$size" -gt 0 ]; then
            truncate -s 0 "$output" 2>/dev/null || : > "$output" 2>/dev/null || true
        fi
    fi
}

# Format definitions with their supported sample rates
# Format:codec:extension:sample_rates (comma-separated)
formats=(
    "mp3:libmp3lame:.mp3:44100"
    "flac:flac:.flac:44100,48000,88200,96000,176400,192000"
    "aac:aac:.aac:44100,48000"
    "m4a:aac:.m4a:44100,48000"
    "wav:pcm_s16le:.wav:44100,48000,88200,96000,176400,192000"
    "aiff:pcm_s16be:.aiff:44100,48000,88200,96000,176400,192000"
    "caf:pcm_s16le:.caf:44100"
    "mp4:aac:.mp4:44100,48000"
    "ogg:libvorbis:.ogg:44100,48000"
    "opus:libopus:.opus:8000,16000,24000,32000,44100,48000"
    "alac:alac:.alac:44100,48000,88200,96000,192000"
    "ape:ape:.ape:44100,48000,88200,96000,192000"
    "wma:wmav2:.wma:44100"
    "webm:libopus:.webm:48000"
    "flv:aac:.flv:44100"
    "ac3:ac3:.ac3:48000"
    "dts:dca:.dts:48000,96000"
    "dsf:dsd:.dsf:2822400,5644800"
    "dff:dsd:.dff:2822400,5644800"
    "wv:wavpack:.wv:44100,48000,88200,96000,192000"
)

# Helper function to convert sample rate to label (e.g., 44100 -> 44.1k, 48000 -> 48k)
sample_rate_to_label() {
    local rate=$1
    if [ "$rate" -ge 1000000 ]; then
        # For MHz rates (DSD), convert to MHz
        local mhz=$((rate / 1000000))
        local remainder=$((rate % 1000000))
        local khz=$((remainder / 1000))
        if [ "$khz" -gt 0 ]; then
            # Format as X.YMHz (e.g., 2.822MHz)
            local khz_decimal=$((khz * 10 / 1000))
            if [ "$khz_decimal" -gt 0 ]; then
                echo "${mhz}.${khz_decimal}MHz"
            else
                echo "${mhz}MHz"
            fi
        else
            echo "${mhz}MHz"
        fi
    elif [ "$rate" -ge 1000 ]; then
        # For kHz rates, convert to kHz with decimal
        local khz=$((rate / 1000))
        local hz=$((rate % 1000))
        if [ "$hz" -gt 0 ]; then
            # Convert remainder to decimal (e.g., 100Hz -> 0.1k, 200Hz -> 0.2k)
            # Common cases: 100->0.1, 200->0.2, 400->0.4, 800->0.8
            local decimal=$((hz / 100))
            if [ "$decimal" -gt 0 ] && [ "$decimal" -lt 10 ]; then
                echo "${khz}.${decimal}k"
            else
                # For other values, show as is (e.g., 88200 -> 88.2k)
                local decimal_tenths=$((hz / 10))
                if [ "$decimal_tenths" -lt 100 ]; then
                    echo "${khz}.${decimal_tenths}k"
                else
                    echo "${khz}k"
                fi
            fi
        else
            echo "${khz}k"
        fi
    else
        # For Hz rates
        echo "${rate}Hz"
    fi
}

echo -e "${BLUE}📁 Generating valid sample files...${NC}\n"
for format_info in "${formats[@]}"; do
    IFS=':' read -r format codec extension sample_rates <<< "$format_info"
    IFS=',' read -ra rates_array <<< "$sample_rates"
    
    # Generate files for each sample rate
    for rate in "${rates_array[@]}"; do
        rate_label=$(sample_rate_to_label "$rate")
        # Temporarily disable errexit for formats that might fail
        if [ "$format" = "alac" ] || [ "$format" = "ape" ] || [ "$format" = "wma" ] || [ "$format" = "ac3" ] || [ "$format" = "dts" ] || [ "$format" = "wv" ] || [ "$format" = "dsf" ] || [ "$format" = "dff" ]; then
            set +e
            generate_valid "$format" "$codec" "$extension" "$rate" "$rate_label" || true
            set -e
        else
            generate_valid "$format" "$codec" "$extension" "$rate" "$rate_label" || {
                echo -e "${YELLOW}⚠️  Failed to generate $(to_upper "$format") at ${rate}Hz, continuing...${NC}" >&2
            }
        fi
    done
done

echo -e "\n${BLUE}📁 Generating invalid/error sample files...${NC}\n"
for format_info in "${formats[@]}"; do
    IFS=':' read -r format codec extension sample_rates <<< "$format_info"
    # Generate invalid files (one set per format, not per sample rate)
    # Always generate these, even if valid files failed
    set +e
    generate_invalid_empty "$format" "$codec" "$extension" || true
    generate_invalid_header "$format" "$codec" "$extension" || true
    generate_truncated "$format" "$codec" "$extension" || true
    generate_zero_size "$format" "$codec" "$extension" || true
    generate_corrupt_payload "$format" "$codec" "$extension" || true
    generate_corrupt_magic "$format" "$codec" "$extension" || true
    generate_no_audio_data "$format" "$codec" "$extension" || true
    generate_corrupt_middle "$format" "$codec" "$extension" || true
    set -e
done

# Verification: Check what was actually generated
echo -e "\n${BLUE}📊 Verifying generated files...${NC}\n"
missing_formats=()
for format_info in "${formats[@]}"; do
    IFS=':' read -r format codec extension sample_rates <<< "$format_info"
    format_dir="${FIXTURES_DIR}/${format}"
    
    if [ ! -d "$format_dir" ]; then
        missing_formats+=("$format (directory missing)")
        continue
    fi
    
    # Check for required files
    required_files=(
        "invalid_empty${extension}"
        "invalid_header${extension}"
        "invalid_truncated${extension}"
        "invalid_zero_size${extension}"
        "invalid_no_audio_data${extension}"
        "corrupt_payload${extension}"
        "corrupt_magic${extension}"
        "corrupt_middle${extension}"
    )
    
    missing_for_format=()
    for req_file in "${required_files[@]}"; do
        if [ ! -f "${format_dir}/${req_file}" ]; then
            missing_for_format+=("$req_file")
        fi
    done
    
    # Check for at least one valid file
    valid_count=$(find "$format_dir" -name "valid_*${extension}" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$valid_count" -eq 0 ]; then
        missing_for_format+=("valid_*${extension} (no valid files)")
    fi
    
    if [ ${#missing_for_format[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  $format: Missing ${#missing_for_format[@]} file(s)${NC}" >&2
        for missing in "${missing_for_format[@]}"; do
            echo -e "    ${YELLOW}- $missing${NC}" >&2
        done
        missing_formats+=("$format (${#missing_for_format[@]} files missing)")
    else
        echo -e "${GREEN}✓ $format: All required files present (${valid_count} valid file(s))${NC}"
    fi
done

if [ ${#missing_formats[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  Summary: ${#missing_formats[@]} format(s) have missing files${NC}" >&2
    for missing in "${missing_formats[@]}"; do
        echo -e "  ${YELLOW}- $missing${NC}" >&2
    done
    echo -e "\n${YELLOW}Note: Some formats may require specific ffmpeg encoders or may not be supported on this system.${NC}" >&2
    echo -e "${YELLOW}Invalid/corrupt files should still be generated even if valid files fail.${NC}" >&2
else
    echo -e "\n${GREEN}✅ All formats have all required files!${NC}"
fi

echo -e "\n${GREEN}✅ Test fixtures generation complete!${NC}\n"
echo -e "${BLUE}Generated files:${NC}"
echo "  ✅ Valid files: valid_{sample_rate}{ext} in each format directory"
echo "    Examples: valid_44.1k.mp3, valid_48k.flac, valid_96k.wav"
echo ""
echo "  ❌ Invalid/Error files:"
echo "    • Invalid (empty): invalid_empty{ext}"
echo "    • Invalid (header): invalid_header{ext}"
echo "    • Invalid (truncated): invalid_truncated{ext}"
echo "    • Invalid (zero-size): invalid_zero_size{ext}"
echo "    • Invalid (no audio data): invalid_no_audio_data{ext} - header only, no audio"
echo ""
echo "  🔴 Corrupt files:"
echo "    • Corrupt (payload): corrupt_payload{ext} - valid header, corrupted data"
echo "    • Corrupt (magic): corrupt_magic{ext} - corrupted magic bytes"
echo "    • Corrupt (middle): corrupt_middle{ext} - byte corruption in middle"
echo ""
echo -e "${BLUE}Location: ${FIXTURES_DIR}${NC}"

