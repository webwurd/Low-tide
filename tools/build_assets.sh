#!/usr/bin/env bash
# Rebuild every generated asset (textures, materials, meshes, scenes, looks).
#   tools/build_assets.sh            # everything
#   tools/build_assets.sh assets     # skip texture painting (fast iteration)
# Output under assets/, scenes/ and art/looks/ is committed. Hand-made art can
# replace any generated model: drop assets/models/<name>.glb next to <name>.res.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-godot}"
# Every stage gets a hard timeout: a script parse error leaves Godot idling forever.
run() { timeout "${STAGE_TIMEOUT:-900}" "$@"; }
if [[ "${1:-all}" == all || "${1:-}" == textures ]]; then
  run "$G" --headless -s tools/build_assets.gd -- textures
  run "$G" --headless --import >/dev/null 2>&1 || true
  run "$G" --headless -s tools/build_assets.gd -- import
  run "$G" --headless --import >/dev/null 2>&1 || true
fi
if [[ "${1:-all}" != textures ]]; then
  # The asset stage bakes VoxelGI for the interiors, which needs a renderer.
  if [[ -f /opt/lavapipe/lvp_icd.json && "${LAVAPIPE:-1}" == 1 ]]; then
    unset VK_DRIVER_FILES; export VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
  fi
  run xvfb-run -a -s "-screen 0 640x360x24" "$G" --rendering-driver vulkan -s tools/build_assets.gd -- assets
  run "$G" --headless --import >/dev/null 2>&1 || true
fi
echo "assets built"
