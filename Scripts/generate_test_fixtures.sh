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
mkdir -p "${FIXTURES_DIR}"/{mp3,flac,aac,wav,m4a,ogg,opus,alac,ape,aiff,caf,mp4}

# Check if ffmpeg is available
if ! command -v ffmpeg &> /dev/null; then
    echo -e "${YELLOW}⚠️  ffmpeg not found. Please install ffmpeg to generate valid audio files.${NC}"
    echo "Install with: brew install ffmpeg"
    exit 1
fi

# Function to generate valid audio file
generate_valid() {
    local format=$1
    local codec=$2
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/valid${extension}"
    
    echo -e "${GREEN}✓ Generating valid $(to_upper "$format") file...${NC}" >&2
    
    case $format in
        mp3)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -b:a 128k -y "$output" 2>/dev/null
            ;;
        flac)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        aac)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        m4a)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        wav)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        aiff)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        caf)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -sample_fmt s16 -y "$output" 2>/dev/null
            ;;
        mp4)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a aac -b:a 128k -y "$output" 2>/dev/null
            ;;
        ogg)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a libvorbis -y "$output" 2>/dev/null
            ;;
        opus)
            ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a libopus -y "$output" 2>/dev/null
            ;;
        alac)
            # ALAC needs ipod format (M4A container) - generate as .m4a then rename if needed
            local temp_output="${output%.alac}.m4a"
            local error_log
            error_log=$(mktemp 2>/dev/null || echo /tmp/ffmpeg_error_$$)
            # Run ffmpeg and check both exit code and file creation
            if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a alac -f ipod -y "$temp_output" 2>"$error_log" && [ -f "$temp_output" ]; then
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
                if ffmpeg -f lavfi -i "sine=frequency=440:duration=1" -ar 44100 -ac 2 -c:a ape -y "$output" 2>"$error_log" && [ -f "$output" ]; then
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
    esac
}

# Function to generate invalid/corrupt file (empty file)
generate_invalid_empty() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_empty${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (empty) $(to_upper "$format") file...${NC}"
    touch "$output"
}

# Function to generate invalid/corrupt file (wrong header)
generate_invalid_header() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_header${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (wrong header) $(to_upper "$format") file...${NC}"
    # Create file with garbage data that looks nothing like the format
    echo "INVALID_HEADER_DATA_12345" > "$output"
}

# Function to generate corrupt file (valid header but corrupted payload)
generate_corrupt_payload() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_payload${extension}"
    local valid_file="${FIXTURES_DIR}/${format}/valid${extension}"
    
    echo -e "${YELLOW}⚠️  Generating corrupt (valid header, bad payload) $(to_upper "$format") file...${NC}"
    
    if [ -f "$valid_file" ]; then
        # Copy first 512 bytes (header) then add corrupted data
        head -c 512 "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=512 of="$output" 2>/dev/null
        # Append corrupted/random data
        dd if=/dev/urandom bs=1024 count=1 >> "$output" 2>/dev/null || head -c 1024 /dev/urandom >> "$output" 2>/dev/null
    else
        # Create file with correct magic bytes but corrupted rest
        case $format in
            mp3)
                printf '\xFF\xFB\x90\x00' > "$output"  # Valid MP3 sync word
                ;;
            flac)
                printf 'fLaC' > "$output"  # Valid FLAC magic
                ;;
            wav|aiff)
                printf 'RIFF' > "$output"  # Valid RIFF header start
                ;;
            m4a|mp4)
                printf '\x00\x00\x00\x20ftyp' > "$output"  # Valid ftyp atom start
                ;;
            ogg)
                printf 'OggS' > "$output"  # Valid OggS magic
                ;;
            *)
                printf 'VALID_MAGIC' > "$output"
                ;;
        esac
        # Append corrupted data
        dd if=/dev/urandom bs=1024 count=1 >> "$output" 2>/dev/null || head -c 1024 /dev/urandom >> "$output" 2>/dev/null
    fi
}

# Function to generate file with corrupted magic bytes
generate_corrupt_magic() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_magic${extension}"
    local valid_file="${FIXTURES_DIR}/${format}/valid${extension}"
    
    echo -e "${YELLOW}⚠️  Generating corrupt (wrong magic bytes) $(to_upper "$format") file...${NC}"
    
    if [ -f "$valid_file" ]; then
        # Copy the file but corrupt the first few bytes (magic bytes)
        cp "$valid_file" "$output"
        # Corrupt first 4-8 bytes depending on format
        case $format in
            mp3)
                # Corrupt MP3 sync word
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null
                ;;
            flac)
                # Corrupt FLAC magic
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null
                ;;
            wav|aiff)
                # Corrupt RIFF header
                printf '\x00\x00\x00\x00' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null
                ;;
            *)
                # Corrupt first 4 bytes
                printf '\xFF\xFF\xFF\xFF' | dd of="$output" bs=1 count=4 conv=notrunc 2>/dev/null
                ;;
        esac
    else
        # Create file with wrong magic bytes
        printf '\xFF\xFF\xFF\xFF\x00\x00\x00\x00CORRUPT_MAGIC' > "$output"
    fi
}

# Function to generate file with valid header but no audio data
generate_no_audio_data() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_no_audio_data${extension}"
    
    echo -e "${YELLOW}⚠️  Generating invalid (header only, no audio) $(to_upper "$format") file...${NC}"
    
    # Create minimal valid header with no actual audio data
    case $format in
        mp3)
            # Minimal MP3 header (ID3v2 + frame sync)
            printf 'ID3\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00' > "$output"
            printf '\xFF\xFB\x90\x00' >> "$output"
            ;;
        flac)
            # FLAC header only
            printf 'fLaC\x01\x00\x00\x00' > "$output"
            ;;
        wav)
            # Minimal WAV header
            printf 'RIFF\x24\x00\x00\x00WAVEfmt \x10\x00\x00\x00\x01\x00\x02\x00' > "$output"
            printf '\x44\xAC\x00\x00\x10\xB1\x02\x00\x04\x00\x10\x00data\x00\x00\x00\x00' >> "$output"
            ;;
        aiff)
            # Minimal AIFF header
            printf 'FORM\x00\x00\x00\x00AIFFCOMM\x00\x00\x00\x00' > "$output"
            ;;
        m4a|mp4)
            # Minimal MP4/M4A header
            printf '\x00\x00\x00\x20ftypmp4 \x00\x00\x00\x00mp4 ' > "$output"
            ;;
        ogg)
            # Minimal Ogg header
            printf 'OggS\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00' > "$output"
            ;;
        *)
            printf 'HEADER_ONLY_NO_DATA' > "$output"
            ;;
    esac
}

# Function to generate file with byte corruption in middle
generate_corrupt_middle() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/corrupt_middle${extension}"
    local valid_file="${FIXTURES_DIR}/${format}/valid${extension}"
    
    echo -e "${YELLOW}⚠️  Generating corrupt (byte corruption in middle) $(to_upper "$format") file...${NC}"
    
    if [ -f "$valid_file" ]; then
        # Get file size
        local file_size=$(stat -f%z "$valid_file" 2>/dev/null || stat -c%s "$valid_file" 2>/dev/null || wc -c < "$valid_file")
        local middle_pos=$((file_size / 2))
        local corrupt_size=100
        local end_pos=$((middle_pos + corrupt_size))
        
        # Corrupt bytes in the middle using head/tail approach (more portable)
        if [ "$middle_pos" -gt 0 ] && [ "$end_pos" -lt "$file_size" ]; then
            # Take first part, add corruption, then append rest
            head -c $middle_pos "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=$middle_pos of="$output" 2>/dev/null
            # Add corrupted bytes
            dd if=/dev/zero bs=1 count=$corrupt_size >> "$output" 2>/dev/null || head -c $corrupt_size /dev/zero >> "$output" 2>/dev/null
            # Calculate remaining bytes
            local remaining=$((file_size - end_pos))
            if [ "$remaining" -gt 0 ]; then
                # Skip to end_pos and take remaining
                tail -c +$((end_pos + 1)) "$valid_file" >> "$output" 2>/dev/null || {
                    # Fallback: use dd to skip and copy
                    dd if="$valid_file" bs=1 skip=$end_pos >> "$output" 2>/dev/null
                }
            fi
        else
            # File too small, just corrupt what we can
            cp "$valid_file" "$output"
            # Corrupt from start if file is very small
            if [ "$file_size" -lt 200 ]; then
                printf '\x00' | dd of="$output" bs=1 count=$((file_size / 2)) conv=notrunc 2>/dev/null || true
            fi
        fi
    else
        # Create a file with some valid structure but corruption
        printf 'VALID_START' > "$output"
        dd if=/dev/zero bs=1 count=100 >> "$output" 2>/dev/null || head -c 100 /dev/zero >> "$output" 2>/dev/null
        printf 'VALID_END' >> "$output"
    fi
}

# Function to generate truncated file
generate_truncated() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_truncated${extension}"
    local valid_file="${FIXTURES_DIR}/${format}/valid${extension}"
    
    echo -e "${YELLOW}⚠️  Generating truncated $(to_upper "$format") file...${NC}"
    
    if [ -f "$valid_file" ]; then
        # Take only first 100 bytes of valid file
        head -c 100 "$valid_file" > "$output" 2>/dev/null || dd if="$valid_file" bs=1 count=100 of="$output" 2>/dev/null
    else
        # Create minimal file with partial header
        case $format in
            mp3)
                printf '\xFF\xFB' > "$output"  # Partial MP3 header
                ;;
            flac)
                printf 'fLaC' > "$output"  # FLAC magic but incomplete
                ;;
            *)
                printf 'INCOMPLETE' > "$output"
                ;;
        esac
    fi
}

# Function to generate zero-size file
generate_zero_size() {
    local format=$1
    local extension=$3
    local output="${FIXTURES_DIR}/${format}/invalid_zero_size${extension}"
    
    echo -e "${YELLOW}⚠️  Generating zero-size $(to_upper "$format") file...${NC}"
    touch "$output"
    # Ensure it's truly empty
    : > "$output"
}

# Generate files for each format
formats=(
    "mp3:libmp3lame:.mp3"
    "flac:flac:.flac"
    "aac:aac:.aac"
    "m4a:aac:.m4a"
    "wav:pcm_s16le:.wav"
    "aiff:pcm_s16be:.aiff"
    "caf:pcm_s16le:.caf"
    "mp4:aac:.mp4"
    "ogg:libvorbis:.ogg"
    "opus:libopus:.opus"
    "alac:alac:.alac"
    "ape:ape:.ape"
)

echo -e "${BLUE}📁 Generating valid sample files...${NC}\n"
for format_info in "${formats[@]}"; do
    IFS=':' read -r format codec extension <<< "$format_info"
    # Temporarily disable errexit for formats that might fail
    if [ "$format" = "alac" ] || [ "$format" = "ape" ]; then
        set +e
        generate_valid "$format" "$codec" "$extension" || true
        set -e
    else
        generate_valid "$format" "$codec" "$extension" || {
            echo -e "${YELLOW}⚠️  Failed to generate $(to_upper "$format"), continuing...${NC}" >&2
        }
    fi
done

echo -e "\n${BLUE}📁 Generating invalid/error sample files...${NC}\n"
for format_info in "${formats[@]}"; do
    IFS=':' read -r format codec extension <<< "$format_info"
    generate_invalid_empty "$format" "$codec" "$extension"
    generate_invalid_header "$format" "$codec" "$extension"
    generate_truncated "$format" "$codec" "$extension"
    generate_zero_size "$format" "$codec" "$extension"
    generate_corrupt_payload "$format" "$codec" "$extension"
    generate_corrupt_magic "$format" "$codec" "$extension"
    generate_no_audio_data "$format" "$codec" "$extension"
    generate_corrupt_middle "$format" "$codec" "$extension"
done

echo -e "\n${GREEN}✅ Test fixtures generation complete!${NC}\n"
echo -e "${BLUE}Generated files:${NC}"
echo "  ✅ Valid: valid{ext} in each format directory"
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

