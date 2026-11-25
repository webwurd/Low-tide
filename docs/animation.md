# Animation pass

Status: **Phase 0 (proof of concept) done; waiting for the project owner's go on Phase 1.**

## Goal
Make interactions feel physical (pocket watch, radio, doors, and later tools, rituals, body and world motion) without touching game logic. Animations are a cosmetic layer driven by existing signals. The only wait is doors: open, then fade and teleport.

## Design
- **Keyframes in code, played by `AnimationPlayer`.** Clips are `Animation` resources, so they are data, reusable, and testable headless by sampling poses at fixed times. Procedural layers (a hand following a moving latch, sway, flame flicker) sit on top and obey `reduce_motion`.
- **Viewmodel rig:** hands with oilskin sleeves under `player.cam`, plus held props. Phase 1 decides between parenting to the camera and an overlay camera on its own visual layer, after judging wall clipping.
- **Door rig:** `DoorRig.wrap()` inserts a hinge pivot at load time, so it survives asset regeneration.
- **Watch face:** Phase 1 reuses `ui/pocket_watch.gd` through a `SubViewport` texture, so the time stays readable.
- **Accessibility:** `reduce_motion` shortens clips and removes sway but keeps the state change visible. Tests and screenshot tools use an instant mode.

## Phases
0. Proof-of-concept clip (this PR's first commit).
1. Foundation: `anim/` module, factory-built hands, watch and handset assets, instant mode, tests.
2. Pocket watch, radio handset and all doors, properly.
3. Handheld tools: binoculars, lantern, pickups, locker, floorboard, shelf.
4. Daily rituals: stove, barometer, tide table, weights, lamp, log, cassette, journal.
5. Body and camera: sit, sleep, stairs, wading, swept, tired, cold.
6. World motion: buoys, curtains, flame, pendulum, pennant, gulls, tender.

## Phase 0 prototype
`docs/animation/phase0_prototype.mp4` (11 s, 1280x720, 30 fps): a hinge-pivoted cottage door pulled open by a hand on the latch while Arthur steps back, then a pocket watch raised in the left hand, lid popped, hands ticking, lid closed, lowered.

Prototype quality: blocky hands built from boxes, no audio, fake daylight quad behind the door because the real wall is solid, hands drawn 1.5x so they read on screen. Files: `anim/hand_rig.gd`, `anim/door_rig.gd`, `anim/watch_prop.gd`, and the renderer `tests/anim_clip.gd`.

Re-render (needs xvfb and ffmpeg):
```bash
xvfb-run -a -s "-screen 0 1280x720x24" godot --rendering-method gl_compatibility -s tests/anim_clip.gd -- /tmp/frames 30
ffmpeg -framerate 30 -i /tmp/frames/f%04d.png -c:v libx264 -pix_fmt yuv420p clip.mp4
```
The render takes about 8 minutes (software GL); frames are deterministic because the animation is seeked to `t = frame / fps`.

## First-person hands (`HandRig`, `HandPose`)
The prototype's box hands are replaced by a skinned model from the asset factory.

- **Model:** `tools/hand_assets.gd` builds left and right hands, each with an 18-bone `Skeleton3D`:
  - bones: `wrist`, `palm`, `palm_ulnar` (ring and little metacarpals, for cupping), `thumb_1..3` (metacarpal plus two phalanges), and `index|middle|ring|little_1..3`
  - surfaces: skin, a knitted wool cuff, and a yellow oilskin sleeve, about 3k triangles with LODs
  - an optional fingerless wool glove (`gloved = true`)

  Output is `assets/models/hand_*.res` and `scenes/hands/hand_{right,left}.tscn`. The left hand is mirrored by geometry; no node has negative scale. Rebuild with `tools/build_assets.sh hands` (it needs the software Vulkan driver; a pure `--headless` run writes null shader defaults into the materials).
- **Skinning:** each finger, the thumb and the palm is one continuous lofted surface, with weights blended across each joint, so knuckles bend without gaps. The front of the palm follows the nearest finger, the thumb ball follows the thumb metacarpal, and the ring and little side follows `palm_ulnar`. `MeshKit.emit()` now takes 4 bone indices and 4 weights per vertex, and `MeshKit.mirrored_x()` reflects a kit.
- **Poses as data:** `anim/poses/<name>.tres` (`HandPose`). Each pose maps bone names to `Vector3(flex, spread, twist)` in degrees, offsets from the flat rest hand, written for the right hand (the left mirrors it). Flex is a curl toward the palm.
  - Shipped poses: `open`, `relaxed`, `fist`, `grip_handle`, `pinch`, `press`, `press_thumb`, `cup`, `push_open_palm`, `two_hand_binoculars`, `point`.
  - Edit a `.tres` in the Inspector, then run `godot --headless -s tests/hand_report.gd` to check palm penetration and the pinch gap.
- **API (`anim/hand_rig.gd`):**
  ```gdscript
  var h := HandRig.new(1.0)               # -1.0 = left
  h.set_pose(&"grip_handle")              # snap to a pose
  h.set_pose(&"pinch", 0.4)               # 40 % of the way from pose_a toward pinch
  h.blend_poses(&"relaxed", &"fist", t)   # explicit two-pose blend
  h.curl = 0.6; h.thumb = 1.0             # prototype floats, layered on top (toward the fist)
  h.attach(watch, &"palm")                # BoneAttachment3D for held props
  ```
  An AnimationPlayer can key `pose_a`, `pose_b` (discrete StringName), `blend`, `curl`, `thumb` and `gloved`. Blending slerps each bone between the two poses.
- **Conventions:** kept from the prototype. Fingers point -Z, the palm faces +Y, the sleeve trails toward +Z and down, and the rig is drawn at 1.5x life size; the right thumb is on +X. One fix: `curl` now closes the fingers toward the palm (+Y). The prototype bent them toward the back of the hand.
- **Tests:** `tests/hand_tests.gd`, run from the main suite, checks:
  - bone count and hierarchy
  - the rest pose
  - each pose loads and bends the expected joints
  - no finger passes through the palm (CPU-skinned)
  - left and right mirror each other in every pose
  - curl and thumb compatibility, and the pinch contact
- **Contact sheet:** `tests/hand_sheet.gd` renders every pose on both hands, in the cottage (game lighting) or a quick studio stage. Its output is `docs/animation/hand_poses.jpg`.
