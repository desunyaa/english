#!/usr/bin/env bash
set -euo pipefail

echo "Publishing english-core..."
cargo publish -p english-core
sleep 30  # wait for crates.io to index

echo "Publishing english..."
cargo publish -p english

echo "Done!"
