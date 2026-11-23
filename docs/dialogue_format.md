# Dialogue format (`dialogue/dialogue.json`)

Writers edit this file; no code changes needed. Top-level keys: `convs`, `reactions`, `tapes`.

## convs
`"conv_id": [ variant, variant, ... ]`: the first variant whose `when` holds is played.
```
{ "when": ["flag:reported_canister", "trust>=2"],   # optional, all must hold
  "speaker": "clara",                               # clara | arthur
  "priority": 2,                                    # 0 idle, 1 reactive, 2 scripted
  "text": "...",
  "options": [ { "text": "...", "reply": "...", "trust": 1,
                 "set": ["flag"], "clear": ["flag"],   # optional
                 "next": "other_conv_id",              # optional follow-up after the reply
                 "when": ["has:tape_1"] } ] }          # optional; max 2 options shown
```
## Conditions
`flag:x  has:item  found:landmark  zone:a,b  loc:cottage  phase:morning|expedition|evening  tide:rising|falling`
`trust>=2  day==3  time>=900  tide>=1.5` (ops `>= <= == > <`), prefix `!` to negate.
Zones: `pier summit shore east_bar west_bar east_stack west_stack`.

## reactions
`{ "id", "when": [...], "conv": "conv_id", "once": true, "cooldown": <game minutes> }`, checked once a second outdoors while the radio is idle; first match plays.

## tapes
`"tape_1": { "title": "...", "lines": [ {"t": <seconds>, "text": "..."} ] }`. Heard tapes set `heard_<id>`.

## Items
Defined in `story/items.gd`. Pickups: set `give_item` on an Interactable.

Note: exported builds must include `*.json` (add to the export filter in M7).
