# Radio, Day 2: Grey Water

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 2: Grey Water** (Overcast)

**Beats:** West cave; warm buoy; tape 1 (Walt, 1976); first honesty test about the tape.

**Where the story is:** The player has found the Pelagic canister (or hidden it). Tape 1 introduces June.

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d2
**Note:** Three variants: trusting / withheld the canister / neutral.

### VARIANT 1 of 3: morning_d2 #0
- **Plays when (LOCKED):** flag:reported_canister AND trust>=2
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Slept better than I have in weeks. Funny what one straight answer does. How's the rock?
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Quiet night. Where do you want me today?
> - Clara replies: West stack, if the water allows. The old echo cave. Mind the tide table.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: That canister's still on my mind.
> - Clara replies: Leave it dry and don't pry at it. I mean that kindly.

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

<!-- END morning_d2 #0 -->

### VARIANT 2 of 3: morning_d2 #1
- **Plays when (LOCKED):** flag:withheld_canister
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Morning. Fog's lifting. I'll say this once, Arthur: I'd rather you were straight with me about what's out there.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: I'll do better. I'm out of practice at being asked.
> - Clara replies: That's all I ask.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: I'm doing my job, Clara.
> - Clara replies: Then do it well.

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

<!-- END morning_d2 #1 -->

### VARIANT 3 of 3: morning_d2 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Morning, Arthur. Flat calm and grey out here. Anything strange wash up overnight?
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Quiet night. Lamp held.
> - Clara replies: Good. Keep it that way.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: That canister's still bothering me.
> - Clara replies: Leave it dry and don't pry at it. I mean that kindly.

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

<!-- END morning_d2 #2 -->

---

## ITEM: evening_d2
**Note:** Three variants: has heard tape 1 / has the tape but hasn't played it / nothing.

### VARIANT 1 of 3: evening_d2 #0
- **Plays when (LOCKED):** flag:heard_tape_1
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You've been quiet all evening. Did you play the tape?
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets told_clara_june)
> - Arthur says: It's a man talking to his wife. June. He says the Navy lied about the cable job. He says it very politely.
> - Clara replies: ...Yes. I know the name. Another night, Arthur. I'll tell you another night.
>
> **ARTHUR option 2** (LOCKED effects: trust -2; sets lied_about_tape)
> - Arthur says: Just static and wind.
> - Clara replies: Static and wind. Of course. Goodnight.

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

<!-- END evening_d2 #0 -->

### VARIANT 2 of 3: evening_d2 #1
- **Plays when (LOCKED):** has:tape_1 AND !flag:heard_tape_1
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Did you find a tape out there? You've got a cassette player in the cottage.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: I'll play it tonight.
> - Clara replies: Do. And tell me what's on it.
>
> **ARTHUR option 2** (LOCKED effects: trust -1; sets lied_about_tape)
> - Arthur says: No tape, Clara.
> - Clara replies: ...All right.

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

<!-- END evening_d2 #1 -->

### VARIANT 3 of 3: evening_d2 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** How was the day, Arthur? You sound far away.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Tired. I'd forgotten how long a day is when nobody's asking you questions.
> - Clara replies: It does that. Sleep.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Fine. Nothing to report.
> - Clara replies: Goodnight, then.

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

<!-- END evening_d2 #2 -->
