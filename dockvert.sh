#!/bin/bash
set -e

# -------------------------------
# HELP
# -------------------------------
show_help() {
  echo "Dockvert - File Converter CLI (Docker-powered)"
  echo ""
  echo "Usage:"
  echo "  $0 [--rebuild] <file> <target_format>"
  echo "  $0 [--rebuild] --batch <dir> <from_ext> <to_ext>"
  echo "  $0 [--rebuild] --interactive"
  echo "  $0 --help"
  echo ""
  echo "Flags:"
  echo "  --rebuild        Force rebuild of Docker images"
  echo ""
  echo "Supported types: images, video, audio, documents, archives, markdown/html/latex via pandoc"
}

# -------------------------------
# File Type Detection
# -------------------------------
detect_type() {
  MIME=$(file --mime-type -b "$1")
  EXT="${1##*.}"

  case "$MIME" in
    image/*) echo "image" ;;
    video/*) echo "video" ;;
    audio/*) echo "audio" ;;
    application/pdf|application/msword|application/vnd.openxmlformats*) echo "document" ;;
    application/zip|application/x-rar|application/x-tar) echo "archive" ;;
    text/markdown|text/x-tex|text/html) echo "markup" ;;
    *) 
      case "$EXT" in
        md|markdown|tex|html|rst|docx) echo "markup" ;;
        *) echo "unknown" ;;
      esac
      ;;
  esac
}

# -------------------------------
# Generate Output Filename
# -------------------------------
generate_output_filename() {
  local input="$1"
  local out_format="$2"
  local filename="${input%.*}.$out_format"

  while [[ -e "$filename" ]]; do
    filename="${input%.*}-${RANDOM}.$out_format";
  done

  echo "$filename"
}

# -------------------------------
# Docker Image Builder
# -------------------------------
ensure_image() {
  local image=$1
  local dockerfile_path="dockerfiles/$2"
  local rebuild="${3:-false}"

  if [[ "$rebuild" == "true" ]]; then
    echo "Forcing rebuild of Docker image: $image"
    docker build --no-cache -t "$image" -f "$dockerfile_path" .
  elif ! docker image inspect "$image" >/dev/null 2>&1; then
    echo "Building Docker image: $image"
    docker build -t "$image" -f "$dockerfile_path" .
  fi
}

# -------------------------------
# Image Conversion
# -------------------------------
convert_image() {
  local input="$1"
  local out_format="$2"
  local output=$(generate_output_filename "$input" "$out_format")

  ensure_image fileconv-imagemagick imagemagick.Dockerfile "$REBUILD_IMAGES"
  docker run --rm -v "$(pwd)":/data fileconv-imagemagick "$input" "$output"
  echo "Image converted: $output"
}

# -------------------------------
# Video/Audio Conversion
# -------------------------------
convert_media() {
  local input="$1"
  local out_format="$2"
  local output=$(generate_output_filename "$input" "$out_format")

  ensure_image fileconv-ffmpeg ffmpeg.Dockerfile "$REBUILD_IMAGES"
  docker run --rm -v "$(pwd)":/data fileconv-ffmpeg -i "$input" "$output"
  echo "Media converted: $output"
}

# -------------------------------
# Document Conversion
# -------------------------------
convert_document() {
  local input="$1"
  local output=$(generate_output_filename "$input" "$out_format")

  ensure_image fileconv-libreoffice libreoffice.Dockerfile "$REBUILD_IMAGES"
  docker run --rm -v "$(pwd)":/data fileconv-libreoffice \
    libreoffice --headless --convert-to "$out_format" "$input"
  echo "Document converted: ${input%.*}.$out_format"
}

# -------------------------------
# Pandoc Conversion (Markdown, HTML, LaTeX, DOCX, PDF, etc.)
# -------------------------------
convert_markup() {
  local input="$1"
  local out_format="$2"
  local output=$(generate_output_filename "$input" "$out_format")

  ensure_image fileconv-pandoc pandoc.Dockerfile "$REBUILD_IMAGES"
  docker run --rm -v "$(pwd)":/data fileconv-pandoc "$input" -o "$output"
  echo "Markup converted: $output"
}

# -------------------------------
# Archive Conversion
# TODO: Use generate_outupt_filename
# -------------------------------
convert_archive() {
  local input="$1"
  local out_format="$2"
  local base="${input%.*}"
  local temp_dir="/tmp/conv_${RANDOM}"

  mkdir -p "$temp_dir"
  ensure_image fileconv-7zip 7zip.Dockerfile "$REBUILD_IMAGES"

  docker run --rm -v "$(pwd)":/data fileconv-7zip x "$input" -o"$temp_dir" -y
  output="$base.$out_format"
  docker run --rm -v "$temp_dir":/data fileconv-7zip a "/data/$output" /data/*
  mv "$temp_dir/$output" .
  rm -rf "$temp_dir"

  echo "Archive converted: $output"
}

# -------------------------------
# Batch Conversion
# -------------------------------
convert_batch() {
  local dir="$1"
  local from_ext="$2"
  local to_ext="$3"

  find "$dir" -type f -name "*.$from_ext" | while read file; do
    "$0" $REBUILD_FLAG "$file" "$to_ext"
  done
}

# -------------------------------
# Interactive Mode
# -------------------------------
interactive_mode() {
  if ! command -v fzf >/dev/null; then
    echo "'fzf' is required for interactive mode (install it via brew/apt)."
    exit 1
  fi

  file=$(find . -type f | fzf --prompt="Select file to convert: ")
  echo "Selected file: $file"

  echo -n "Enter target format (e.g., jpg, mp4, docx, pdf): "
  read target

  "$0" $REBUILD_FLAG "$file" "$target"
}

# -------------------------------
# Main Dispatcher
# -------------------------------

REBUILD_IMAGES="false"
REBUILD_FLAG=""
if [[ "$1" == "--rebuild" ]]; then
  REBUILD_IMAGES="true"
  REBUILD_FLAG="--rebuild"
  shift
fi

if [[ "$1" == "--help" || "$#" -eq 0 ]]; then
  show_help
  exit 0
elif [[ "$1" == "--batch" ]]; then
  convert_batch "$2" "$3" "$4"
  exit 0
elif [[ "$1" == "--interactive" ]]; then
  interactive_mode
  exit 0
fi

input="$1"
target_format="$2"

if [[ ! -f "$input" ]]; then
  echo "File not found: $input"
  exit 1
fi

type=$(detect_type "$input")

case "$type" in
  image) convert_image "$input" "$target_format" ;;
  video|audio) convert_media "$input" "$target_format" ;;
  document) convert_document "$input" "$target_format" ;;
  archive) convert_archive "$input" "$target_format" ;;
  markup) convert_markup "$input" "$target_format" ;;
  *) echo "Unsupported file type: $type"; exit 1 ;;
esac
