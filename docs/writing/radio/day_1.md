# Radio, Day 1: First Watch

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 1: First Watch** (Fog)

**Beats:** Rituals; east bar; the canister (report or withhold). First contact with Clara.

**Where the story is:** Arthur has just arrived and is still a stranger to Clara. The player is learning the island. Nothing about 1974 is known yet.

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d1
**Note:** First ever radio call. Radio check; Clara is still in procedural mode.

### VARIANT 1 of 1: morning_d1 #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Gannet Rock, this is Station Penobscot, radio check. Tide's dropping fast. If you want the outer stacks before noon, now's your window. Say something, Arthur, so I know the set works.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Penobscot, Gannet Rock. Lamp's steady, weights wound. I've also located the coffee, which seemed the main thing.
> - Clara replies: Copy, that is the main thing. Give me a shout if anything strange washed up in last night's squall.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Copy. I'll look around and radio if there's anything worth your time.
> - Clara replies: Worth my time is a low bar at this hour, Arthur. Anything you find, I'd like to hear about.

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

<!-- END morning_d1 #0 -->

---

## ITEM: react_east_bar_first
**Note:** Fires automatically the first time Arthur steps on the east bar.

### VARIANT 1 of 1: react_east_bar_first #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** East bar. Watch in your hand, Arthur, not in your pocket. It's a long walk back when the water turns.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_east_bar_first #0 -->

---

## ITEM: react_west_bar_first
**Note:** Fires the first time Arthur steps on the west bar.

### VARIANT 1 of 1: react_west_bar_first #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** West bar's narrower than the east, and it floods first. Mind the gullies.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_west_bar_first #0 -->

---

## ITEM: shipwreck
**Note:** Played when Arthur reaches the east stack wreck. Option 1 reports the canister; option 2 withholds it.

### VARIANT 1 of 1: shipwreck #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You've been out on the East Stack a while. What's in the hull?
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets reported_canister)
> - Arthur says: An orange canister, stamped PROJECT PELAGIC, 1974. It's in the satchel.
> - Clara replies: ...Keep it dry and bring it back before the bar floods. Don't open it out in the salt spray.
>
> **ARTHUR option 2** (LOCKED effects: trust -1; sets withheld_canister)
> - Arthur says: An old trawler. Rust and rope. Nothing to report.
> - Clara replies: Mm. Mind the water behind you. That bar goes fast.

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

<!-- END shipwreck #0 -->

---

## ITEM: seacave
**Note:** Played at the west echo cave. Option 1 reports the warm buoy; option 2 withholds it. SECRET: Clara services this buoy herself.

### VARIANT 1 of 1: seacave #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Echo Cave? Your signal's bouncing off the walls. What's sitting in the arch?
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets reported_buoy)
> - Arthur says: A rusted acoustic buoy. The casing's warm, and there's a cassette taped inside the hatch.
> - Clara replies: Warm. ...That'll be the cold, probably. Metal does odd things. Bring the tape home, Arthur, and head for high ground.
>
> **ARTHUR option 2** (LOCKED effects: trust -1; sets withheld_buoy)
> - Arthur says: Kelp and barnacles. It's eerie in here, that's all.
> - Clara replies: Don't linger. The Atlantic doesn't wait for anyone enjoying the acoustics.

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

<!-- END seacave #0 -->

---

## ITEM: react_west_withheld
**Note:** A prompt if Arthur is on the west stack having withheld the canister.

### VARIANT 1 of 1: react_west_withheld #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You're on the west stack now. Anything from the east stack you'd like to put on the record?
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets reported_canister; clears withheld_canister)
> - Arthur says: There was a canister in the hull. PROJECT PELAGIC, 1974. I should have said.
> - Clara replies: Yes. You should have. Thank you for saying it now.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: Not yet. I'd like to understand it first.
> - Clara replies: I know that one. All right, Arthur. Whenever you're ready.

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

<!-- END react_west_withheld #0 -->

---

## ITEM: evening_d1
**Note:** Three variants: reported canister / withheld canister / nothing found.

### VARIANT 1 of 3: evening_d1 #0
- **Plays when (LOCKED):** has:canister AND flag:reported_canister
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Beam looks beautiful from here. Thank you for telling me about that canister, Arthur. People don't always, when it's something odd.
>
> **ARTHUR option 1** (LOCKED effects: trust +0; sets asked_pelagic)
> - Arthur says: It said PROJECT PELAGIC on the side. Does that mean anything to you?
> - Clara replies: ...Not tonight. I'll tell you what I can, when I can.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: Just doing the job.
> - Clara replies: Then you're better at it than the last three keepers.

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

<!-- END evening_d1 #0 -->

### VARIANT 2 of 3: evening_d1 #1
- **Plays when (LOCKED):** has:canister AND flag:withheld_canister
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Lamp's turning well. You were out on the east stack a long time today. Anything you'd care to tell me?
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets reported_canister; clears withheld_canister)
> - Arthur says: There was a canister in the hull. PROJECT PELAGIC, 1974. I should have said.
> - Clara replies: Yes. You should have. Thank you for saying it now.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: Nothing worth a radio call.
> - Clara replies: All right. Goodnight, Arthur.

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

<!-- END evening_d1 #1 -->

### VARIANT 3 of 3: evening_d1 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Beam's turning pretty from here. How was your first day on the rock, really?
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Quieter than I expected. I'm still deciding what I think about that.
> - Clara replies: That's honest. Most keepers say it takes three days to stop listening for company.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Busy. A great deal to log.
> - Clara replies: All business. Fine. Get some sleep.

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

<!-- END evening_d1 #2 -->
