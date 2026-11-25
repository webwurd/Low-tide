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
