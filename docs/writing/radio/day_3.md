# Radio, Day 3: Wool

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 3: Wool** (Dense fog)

**Beats:** Bell buoys; north cove cable; tape 3 under the floorboard (Walt, 1977; the Navy's offer; Ruth).

**Where the story is:** Visibility is poor. Clara teaches the bell code (1 north, 2 east, 3 south, 4 west).

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d3

### VARIANT 1 of 2: morning_d3 #0
- **Plays when (LOCKED):** trust>=3
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Fog's down to the waterline. Listen, don't look. One strike is the north bell, two east, three south, four west. Say it back to me.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Nineteen years of school bells. I can manage four.
> - Clara replies: Good. Don't trust the beam in this. Trust your ears.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: You worry a good deal, for a dispatcher.
> - Clara replies: It's the job. And... other things.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END morning_d3 #0 -->

### VARIANT 2 of 2: morning_d3 #1
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Dense fog. One strike north, two east, three south, four west. Don't go out blind.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Understood. North one, east two.
> - Clara replies: Good.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: I've been told what to do by a great many people lately.
> - Clara replies: Then go carefully.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END morning_d3 #1 -->

---

## ITEM: react_fog_bells

### VARIANT 1 of 1: react_fog_bells #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** In this soup, find the bell before you trust your feet. Two strikes is the east buoy. That's the way you'd be crossing.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_fog_bells #0 -->

---

## ITEM: react_north_cove_first

### VARIANT 1 of 1: react_north_cove_first #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** North cove. Careful on the shingle; it's slick, and the water floods that bar before the others.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_north_cove_first #0 -->

---

## ITEM: cable
**Note:** Played at the north cove cable. SECRET: Clara knows about the splice already.

### VARIANT 1 of 1: cable #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** North cove? That's the old cable landing. The charts show a line coming ashore there. What's it look like?
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets reported_cable)
> - Arthur says: An armored cable running straight into the sea. Brass tag: PELAGIC, ARRAY 2, USN.
> - Clara replies: ...Then the charts weren't wrong. Leave the hut alone, Arthur, and don't touch the splice.
>
> **ARTHUR option 2** (LOCKED effects: trust -1; sets withheld_cable)
> - Arthur says: Rocks and kelp, mostly.
> - Clara replies: All right. Mind the tide on the way back.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END cable #0 -->

---

## ITEM: evening_d3

### VARIANT 1 of 3: evening_d3 #0
- **Plays when (LOCKED):** has:cable_tag AND flag:reported_cable
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You found the north landing and you told me. I won't forget that, Arthur.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: What was Array 2? The tag was Navy issue.
> - Clara replies: ...Another night. I promise.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: Just doing the job.
> - Clara replies: Then the job's in good hands.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END evening_d3 #0 -->

### VARIANT 2 of 3: evening_d3 #1
- **Plays when (LOCKED):** has:cable_tag AND flag:withheld_cable
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You were in the north cove a long time. Is there something you'd like to say?
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets reported_cable; clears withheld_cable)
> - Arthur says: There's a cable, and a brass tag. PELAGIC ARRAY 2. I should have said.
> - Clara replies: Yes. You should have. Thank you.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: No. I'm tired, Clara.
> - Clara replies: All right.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END evening_d3 #1 -->

### VARIANT 3 of 3: evening_d3 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Found anything in the north cove? The old charts show a cable there.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Haven't made it up there yet.
> - Clara replies: Fog's thick today. Wait for a clear low.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: Nothing worth reporting.
> - Clara replies: All right, Arthur.

**OWNER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

**WRITER DRAFT**
```text
LINE:
ARTHUR_1:
CLARA_REPLY_1:
ARTHUR_2:
CLARA_REPLY_2:
```

<!-- END evening_d3 #2 -->
