#!/usr/bin/env bash
# Copies shared data into the Unity project. dialogue/dialogue.json is the single source of truth.
set -eu
cd "$(dirname "$0")/.."
mkdir -p unity/Assets/StreamingAssets
cp dialogue/dialogue.json unity/Assets/StreamingAssets/dialogue.json
echo "synced dialogue.json -> unity/Assets/StreamingAssets/"
