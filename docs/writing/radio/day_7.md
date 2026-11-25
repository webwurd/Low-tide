# Radio, Day 7: Last Light

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 7: Last Light** (Still)

**Beats:** The final decision and dawn.

**Where the story is:** A: send the tapes to Ruth Whitcomb. B: let the buoy die (only if Clara admitted everything). C: report Clara (not offered if she admitted). Relief boat at first light.

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d7

### VARIANT 1 of 3: morning_d7 #0
- **Plays when (LOCKED):** flag:clara_admitted
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Last day. Funny. I've talked to you more than I talk to anyone ashore.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Same here. I don't think I've talked this much since the classroom.
> - Clara replies: Then we're square.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Let's finish what we started.
> - Clara replies: Alright. Whatever you decide, I'll abide by it.

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

<!-- END morning_d7 #0 -->

### VARIANT 2 of 3: morning_d7 #1
- **Plays when (LOCKED):** flag:clara_partial
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Last morning. The relief boat is due at first light tomorrow. I hope you've made up your mind.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Nearly.
> - Clara replies: Good.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Not yet.
> - Clara replies: Then think carefully.

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

<!-- END morning_d7 #1 -->

### VARIANT 3 of 3: morning_d7 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Last day. Relief boat's due at first light.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: I know.
> - Clara replies: ...
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Clara, are we all right?
> - Clara replies: I don't know, Arthur.

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

<!-- END morning_d7 #2 -->

---

## ITEM: evening_d7
**Note:** The final choice. Option text sets which ending plays (A/B/C). Do not change what each option MEANS.

### VARIANT 1 of 3: evening_d7 #0
- **Plays when (LOCKED):** flag:clara_admitted
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Light's on. Relief boat's due at first light. You hold June's tapes, and Walt's, and my father's. Whatever you decide, I'll abide by it.
>
> **ARTHUR option 1** (LOCKED effects: trust +0; sets ending_a; then plays end_a_high)
> - Arthur says: I'm sending them to Ruth Whitcomb, in Providence. She's waited twenty-four years to hear her sister.
> - Clara replies: ...Yes. I'll write the cover letter myself.
>
> **ARTHUR option 2** (LOCKED effects: trust +0; sets ending_b; then plays end_b)
> - Arthur says: Let the buoy go quiet, Clara. The tapes go back in the locker. This stays between us.
> - Clara replies: ...Then I'll cut the supply tonight. Thank you, Arthur.

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

<!-- END evening_d7 #0 -->

### VARIANT 2 of 3: evening_d7 #1
- **Plays when (LOCKED):** flag:clara_partial
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Light's on. Relief boat's due at first light. You know enough to decide. What will you do?
>
> **ARTHUR option 1** (LOCKED effects: trust +0; sets ending_a; then plays end_a_mid)
> - Arthur says: I'm sending the tapes to June's family. Ruth Whitcomb, in Providence.
> - Clara replies: Do what you must. I'll sign whatever you need.
>
> **ARTHUR option 2** (LOCKED effects: trust +0; sets ending_c; then plays end_c)
> - Arthur says: I'm filing a report, Clara. The buoy, and 1974. I'm sorry.
> - Clara replies: ...I understand.

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

<!-- END evening_d7 #1 -->

### VARIANT 3 of 3: evening_d7 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Light's on. The relief boat's due at first light. I suppose you've decided.
>
> **ARTHUR option 1** (LOCKED effects: trust +0; sets ending_a; then plays end_a_low)
> - Arthur says: I'm sending the tapes to June's family anyway.
> - Clara replies: Then do it. I won't stop you.
>
> **ARTHUR option 2** (LOCKED effects: trust +0; sets ending_c; then plays end_c)
> - Arthur says: I'm filing a report, Clara.
> - Clara replies: ...

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

<!-- END evening_d7 #2 -->

---

## ITEM: end_a_high
**Note:** Clara's last line if ending A and trust is high.

### VARIANT 1 of 1: end_a_high #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Goodnight, Arthur. Thank you, for all of it. Get some sleep before the boat.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END end_a_high #0 -->

---

## ITEM: end_a_mid

### VARIANT 1 of 1: end_a_mid #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Goodnight, Arthur. I'll be on sixteen at first light.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END end_a_mid #0 -->

---

## ITEM: end_a_low

### VARIANT 1 of 1: end_a_low #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Goodnight.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END end_a_low #0 -->

---

## ITEM: end_b
**Note:** Clara's last line, ending B: 'Left Quiet'.

### VARIANT 1 of 1: end_b #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** I've cut the supply. It'll go quiet by morning. Goodnight, Arthur.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END end_b #0 -->

---

## ITEM: end_c
**Note:** Clara's last line, ending C: 'On the Record'.

### VARIANT 1 of 1: end_c #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Station Penobscot, out.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END end_c #0 -->

---

## ITEM: ending_a_radio
**Note:** Heard over the radio as the relief boat arrives.

### VARIANT 1 of 3: ending_a_radio #0
- **Plays when (LOCKED):** flag:clara_admitted
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** I have the relief boat on my board, Arthur. Wave to them for me. And thank you.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END ending_a_radio #0 -->

### VARIANT 2 of 3: ending_a_radio #1
- **Plays when (LOCKED):** flag:clara_partial
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** The relief boat's on my board. Safe home, Arthur.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END ending_a_radio #1 -->

### VARIANT 3 of 3: ending_a_radio #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Relief boat's on the board. Safe home.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END ending_a_radio #2 -->

---

## ITEM: ending_b_radio
**Note:** Heard over the radio as the relief boat arrives, after the buoy has gone quiet.

### VARIANT 1 of 1: ending_b_radio #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** It's gone quiet, Arthur. I can't hear the ping any more. ...I have the relief boat on my board.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END ending_b_radio #0 -->

---

## ITEM: ending_c_radio
**Note:** Arthur's own line: no one answers on sixteen.

### VARIANT 1 of 1: ending_c_radio #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Arthur

**AI DRAFT (reference only)**

> **ARTHUR:** Penobscot, Gannet Rock. Penobscot, Gannet Rock. ...Only static on sixteen.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END ending_c_radio #0 -->
