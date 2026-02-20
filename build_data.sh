#!/usr/bin/env bash
set -euo pipefail

# build_data.sh — Full data regeneration pipeline for the english crate
#
# This script downloads the latest Wiktionary JSONL dump, runs the extractor
# to regenerate the TSV data files, and rebuilds + tests the workspace.
#
# Usage:
#   ./build_data.sh                    # Download fresh data and regenerate
#   ./build_data.sh path/to/dump.jsonl # Use an existing JSONL dump file

DATA_DIR="crates/english/data"
DUMP_FILE="${1:-rawwiki.jsonl}"

echo "============================================"
echo "  english — Full Data Regeneration Pipeline"
echo "============================================"
echo ""

# Step 1: Download Wiktionary dump (if no file provided / doesn't exist)
if [ ! -f "$DUMP_FILE" ]; then
    echo "📥 Step 1: Downloading Wiktionary JSONL dump..."
    echo "   This is a large file (~20 GB compressed). This may take a while."
    echo ""

    DUMP_URL="https://kaikki.org/dictionary/raw-wiktextract-data.jsonl.bz2"
    COMPRESSED_FILE="rawwiki.jsonl.bz2"

    if command -v wget &> /dev/null; then
        wget -O "$COMPRESSED_FILE" "$DUMP_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o "$COMPRESSED_FILE" "$DUMP_URL"
    else
        echo "❌ Error: Neither wget nor curl found. Please install one of them."
        exit 1
    fi

    echo "📦 Decompressing..."
    bunzip2 "$COMPRESSED_FILE"
    DUMP_FILE="rawwiki.jsonl"
    echo "✅ Download complete: $DUMP_FILE"
    echo ""
else
    echo "📄 Step 1: Using existing dump file: $DUMP_FILE"
    echo ""
fi

# Step 2: Run the extractor
echo "🔧 Step 2: Running extractor to process Wiktionary data..."
echo "   This parses the JSONL dump and generates intermediate CSV files."
echo ""
cargo run --package extractor --release -- "$DUMP_FILE"
echo ""
echo "✅ Extractor complete."
echo ""

# Step 3: Rebuild workspace (build.rs will regenerate PHF maps from TSV data)
echo "🏗️  Step 3: Rebuilding workspace..."
cargo build --workspace
echo ""
echo "✅ Build complete."
echo ""

# Step 4: Run tests
echo "🧪 Step 4: Running tests..."
cargo test --workspace
echo ""
echo "✅ All tests passed."
echo ""

# Step 5: Run examples to verify
echo "📊 Step 5: Running benchmark example..."
cargo run --example speedmark -p english --release
echo ""

echo "============================================"
echo "  ✅ Data regeneration pipeline complete!"
echo "============================================"
echo ""
echo "The updated data files are in: $DATA_DIR/"
echo "  - noun_data.tsv"
echo "  - verb_data.tsv"
echo "  - adj_data.tsv"
echo ""
echo "Review the changes with: git diff $DATA_DIR/"
