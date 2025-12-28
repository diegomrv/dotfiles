# Video Conversion Functions
# ==========================
# FFmpeg-based utilities for video conversion with HDR support.
#
# Requirements:
#   - ffmpeg (with libx265 and zscale filter support)
#   - ffprobe (usually bundled with ffmpeg)
#
# Install on macOS:
#   brew install ffmpeg
#
# Usage:
#   convert_video input.mov           # Auto-detects HDR, outputs input_hdr.mp4
#   convert_video_hdr_aggressive input.mov  # Forces tone-mapping for SDR displays

# convert_video - Smart HDR-aware video conversion
#
# Converts video to H.265/HEVC with automatic HDR detection.
# If HDR metadata is detected, applies appropriate color space settings.
#
# Arguments:
#   $1 - Input video file path
#
# Output:
#   Creates {input_name}_hdr.mp4 in the same directory
#
# Example:
#   convert_video ~/Videos/recording.mov
#   # Creates ~/Videos/recording_hdr.mp4
convert_video() {
    local input_file="$1"
    local output_file="${input_file%.*}_hdr.mp4"

    if [[ -z "$input_file" ]]; then
        echo "Usage: convert_video <input_file>"
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        echo "Error: File not found: $input_file"
        return 1
    fi

    # Detect HDR metadata
    local hdr_info
    hdr_info=$(ffprobe -v error -select_streams v:0 \
        -show_entries stream=color_space,color_transfer,color_primaries \
        -of default=noprint_wrappers=1 "$input_file")

    # Base conversion command
    local ffmpeg_cmd=(
        ffmpeg -i "$input_file"
        -c:v libx265
        -tag:v hvc1
        -preset medium
        -crf 23
        -c:a copy
        -map_metadata 0
        -movflags +faststart
    )

    # HDR-specific parameters
    if echo "$hdr_info" | grep -q "color_transfer=smpte2084\|color_space=bt2020nc\|color_primaries=bt2020"; then
        echo "Detected HDR source. Applying HDR-aware conversion."
        ffmpeg_cmd+=(
            -color_primaries bt2020
            -color_trc smpte2084
            -colorspace bt2020nc
            -vf "zscale=t=linear:npl=100,format=yuv420p,zscale=p=bt709:t=linear:m=bt2020nc:r=tv,format=yuv420p"
        )
    fi

    echo "Converting: $input_file -> $output_file"
    "${ffmpeg_cmd[@]}" "$output_file"
}

# convert_video_hdr_aggressive - HDR to SDR with tone-mapping
#
# Converts HDR video to SDR using Hable tone-mapping algorithm.
# Use this when you need the video to display correctly on SDR screens.
#
# Arguments:
#   $1 - Input video file path
#
# Output:
#   Creates {input_name}_hdr_mapped.mp4 in the same directory
#
# Example:
#   convert_video_hdr_aggressive ~/Videos/hdr_clip.mov
#   # Creates ~/Videos/hdr_clip_hdr_mapped.mp4
convert_video_hdr_aggressive() {
    local input_file="$1"
    local output_file="${input_file%.*}_hdr_mapped.mp4"

    if [[ -z "$input_file" ]]; then
        echo "Usage: convert_video_hdr_aggressive <input_file>"
        return 1
    fi

    if [[ ! -f "$input_file" ]]; then
        echo "Error: File not found: $input_file"
        return 1
    fi

    echo "Converting with aggressive tone-mapping: $input_file -> $output_file"
    ffmpeg -i "$input_file" \
        -c:v libx265 \
        -tag:v hvc1 \
        -preset medium \
        -crf 23 \
        -c:a copy \
        -map_metadata 0 \
        -movflags +faststart \
        -vf "zscale=t=linear:npl=100,tonemap=tonemap=hable:desat=0,zscale=p=bt709:t=linear:m=bt2020nc:r=tv" \
        "$output_file"
}
