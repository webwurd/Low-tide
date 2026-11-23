# *Low Tide* — Core Game Design Principles & Design Bible

**Genre:** First-Person Narrative Exploration / Cozy Atmospheric Mystery  
**Setting:** Gannet Rock Light Station — A remote island off the coast of Maine (Winter, 1998)  
**Core Touchstone:** *Firewatch* (isolated exploration, analog tools, a single unseen voice over a crackling radio, and a grounded human mystery)

---

## 1. The Four Design Pillars

Every feature, line of dialogue, and environment asset in *Low Tide* must serve at least one of these four core pillars:

1. **Tactile Isolation & Cozy Shelter**  
   The world outside is cold, windswept, and vast, making the lighthouse and stone cottage feel genuinely warm and comforting. Contrasting the biting coastal fog with amber lantern light, cast-iron stoves, and creaking floorboards creates the signature "cozy" atmosphere.
2. **Time as Geography (The Tide Loop)**  
   Instead of arbitrary locked doors or skill trees, the ocean itself gates progression. Players learn to read the island like a real mariner—using low tide to explore exposed sandbars, sea caves, and shipwrecks, and retreating to high ground before the Atlantic surges back in.
3. **Diegetic & Analog Navigation**  
   No floating minimaps, glowing quest markers, or cluttered HUDs. Players navigate using sightlines (the towering lighthouse beacon cutting through fog), audio cues (distant foghorns and buoy bells), a brass pocket watch, a tide chart, and `7x50` marine binoculars.
4. **Intimate, Grounded Human Mystery**  
   There are no monsters, jump scares, or supernatural threats. Tension and intrigue come from human history, quiet loneliness, and the evolving bond between two isolated people—Arthur (the winter caretaker) and Clara (the mainland Coast Guard dispatcher)—connected only by a VHF marine radio.

---

## 2. Core Gameplay Loop

*Low Tide* follows a rhythmic, comforting daily structure divided into three distinct phases:

### Phase 1: Morning Rituals (High Tide)
* **Location:** Inside the Keeper’s Cottage and Lighthouse Tower.
* **Actions:** Wake up to rain or fog against the glass; brew coffee on the stove; wind the clockwork weights that rotate the Fresnel lens; check the barometer and tide chart; conduct the morning radio check-in with Clara on Channel 16.
* **Design Purpose:** Grounds the player in a safe, tactile routine before sending them out into the elements.

### Phase 2: Low-Tide Expedition (Falling / Low Water)
* **Location:** Exterior Gannet Rock, exposed sandbars, and outer sea stacks.
* **Actions:** Hike down to the shore as the water recedes; cross newly revealed sandbars to inspect washed-up debris, shipwrecks, and tidal caves; examine clues through binoculars or up close; report discoveries back to Clara in real time.
* **Design Purpose:** Creates gentle, self-directed exploration with natural time pressure—players must watch their pocket watch so they don't get cut off by the rising tide.

### Phase 3: Evening Watch & Reflection (Rising / High Water)
* **Location:** Returning to the lighthouse before dusk/high tide.
* **Actions:** Light the kerosene-vapor lamp; update Arthur's physical logbook with sketches and notes from the day's findings; have a deeper, reflective evening conversation with Clara as the lighthouse beam sweeps through the night fog.
* **Design Purpose:** Rewards exploration with emotional payoff and narrative progression.

---

## 3. Signature Mechanics & Rules

### A. The Dynamic Tide System
* **Water Level Oscillation:** The ocean plane rises and falls smoothly on a predictable 12-hour tidal cycle (`0.2m` at Low Tide to `4.2m` at High Tide).
* **Sandbar Choke Points:** Outer landmarks (such as the East Shipwreck Stack and West Echo Cave) sit across sandbars elevated at `~1.6m`. When water exceeds `2.1m`, these paths submerge.
* **Non-Punitive Hazard Handling:** If a player misjudges the tide and wades too deep, the game fades to black as freezing swells force Arthur back to the safety of the South Landing Dock—triggering contextual radio banter from Clara rather than a harsh "Game Over" screen.

### B. Grounded First-Person Movement
* **Human Pacing:** Walking speed should feel deliberate and weighty (`~2.5–4.0 m/s`), with a short brisk-walk/jog burst (`~6.5 m/s`) governed by a subtle stamina meter.
* **Camera & Optics:** Subtle head-bob synced to footsteps. Holding Right-Click (or `B`) raises heavy binoculars, smoothly narrowing FOV from `65°` to `20°` with a dual-circle vignette and optical rangefinder readout.

### C. Branching VHF Radio System
* **Seamless Integration:** Radio prompts must never freeze player movement. Players can walk, look through binoculars, or inspect props while choosing between two conversational responses (`1` or `2`).
* **Responsive World Awareness:** Clara’s dialogue reacts to *where* Arthur is standing, *what* time of day it is, and *which* clues he chooses to report—or withhold.

---

## 4. Art, Lighting & Audio Direction

### Visual Palette & Sightlines
* **Color Contrast:** Cool slate blues (`#526373`), wet charcoal granite (`#3a434a`), and seafoam greens contrasted sharply against warm golden-amber light (`#ffb84d`) from the lighthouse lantern and cottage windows.
* **Landmark Orientation:** Because coastal fog frequently reduces visibility, the lighthouse tower must remain the highest, unmistakable silhouette on the island, with its rotating volumetric light beam acting as a natural compass.

### Soundscape Principles
* **No Constant Music:** Keep the score minimal—use sparse acoustic guitar, solo cello, or ambient piano only during major emotional turning points.
* **Environmental Storytelling via Audio:**
  * Surface-specific footsteps (hollow wood on the dock, wet crunch on sandbars, sharp grit on granite).
  * Dynamic wind volume tied to elevation (stronger near the lantern gallery).
  * Distant, mournful foghorns and rhythmic wave swells that shift in intensity with the tide.
  * Authentic VHF radio squelch bursts and subtle analog warmth on Clara's voice.

---

## 5. Scope Guardrails (Rules to Stay on Track)

To ensure the game remains finishable by a small team without scope creep, follow these strict constraints:
1. **Single Self-Contained Island:** Do not add boat piloting or mainland travel. Everything happens on Gannet Rock and its tide-linked sea stacks.
2. **Two-Person Cast:** Keep the active speaking cast strictly to Arthur and Clara (with past characters discovered only through cassette tapes and logbooks).
3. **Zero Combat or Inventory Puzzles:** Interactions are binary and tactile (inspect, pick up, wind crank, flip switch, report on radio). Avoid complex key-hunting or crafting menus.
---

## Amendments (see docs/production_plan.md)
- Guardrail 3 now reads: "Satchel holds story items only. No combining, crafting, keys, or weight."
- Water-depth bands (by depth at Arthur's feet): 0-0.3m splash, 0.3-0.7m x0.6 speed, 0.7-0.95m x0.35 speed, >0.95m swept to the South Landing Dock (+45 game-min).
- HUD is diegetic by default (pocket watch, paper tide table, piling marks, logbook). Assist Mode restores a readout.
- Tides follow a per-day tide table, not a fixed sinusoid; lows arrive ~50 min later each day.
