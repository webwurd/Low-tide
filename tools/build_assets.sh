#!/usr/bin/env bash
# Rebuild every generated asset (textures, materials, meshes, scenes, looks).
#   tools/build_assets.sh            # everything
#   tools/build_assets.sh assets     # skip texture painting (fast iteration)
# Output under assets/, scenes/ and art/looks/ is committed. Hand-made art can
# replace any generated model: drop assets/models/<name>.glb next to <name>.res.
set -euo pipefail
cd "$(dirname "$0")/.."
G="${GODOT:-godot}"
if [[ "${1:-all}" == all || "${1:-}" == textures ]]; then
  "$G" --headless -s tools/build_assets.gd -- textures
  "$G" --headless --import >/dev/null 2>&1 || true
  "$G" --headless -s tools/build_assets.gd -- import
  "$G" --headless --import >/dev/null 2>&1 || true
fi
if [[ "${1:-all}" != textures ]]; then
  # The asset stage bakes VoxelGI for the interiors, which needs a renderer.
  if [[ -f /opt/lavapipe/lvp_icd.json && "${LAVAPIPE:-1}" == 1 ]]; then
    unset VK_DRIVER_FILES; export VK_ICD_FILENAMES=/opt/lavapipe/lvp_icd.json
  fi
  xvfb-run -a -s "-screen 0 640x360x24" "$G" --rendering-driver vulkan -s tools/build_assets.gd -- assets
  "$G" --headless --import >/dev/null 2>&1 || true
fi
echo "assets built"
