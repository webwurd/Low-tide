#!/usr/bin/env bash
# Render the art vantages in tests/screenshot.gd to PNGs.
#   tools/shots.sh <outdir> [name-filter]
# Uses the GPU if there is one; set LAVAPIPE=1 to force the software Vulkan driver.
set -euo pipefail
cd "$(dirname "$0")/.."
OUT="${1:?usage: tools/shots.sh <outdir> [filter]}"
mkdir -p "$OUT"
if [[ "${LAVAPIPE:-0}" == 1 && -f /opt/lavapipe/lvp_icd.json ]]; then
  unset VK_DRIVER_FILES
  export VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
fi
exec xvfb-run -a -s "-screen 0 1280x720x24" "${GODOT:-godot}" --rendering-driver vulkan \
  -s tests/screenshot.gd -- "$OUT" "${2:-}"
