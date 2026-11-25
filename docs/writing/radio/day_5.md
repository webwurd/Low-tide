# Radio, Day 5: Spring Low

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 5: Spring Low** (Clear)

**Beats:** South causeway opens for about two hours; the vault; tape 2 (June, 1974).

**Where the story is:** The lowest water of the winter. Clara is visibly anxious about the reef.

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d5

### VARIANT 1 of 2: morning_d5 #0
- **Plays when (LOCKED):** flag:clara_shared_father
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Clear as glass. The tables say this is the lowest water of the winter, Arthur. My father used to say the reef opens once a decade.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Then the south reef will be open.
> - Clara replies: For a couple of hours at best. Watch the clock like it owes you money.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: You sound nervous.
> - Clara replies: I sound careful. There's a difference.

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

<!-- END morning_d5 #0 -->

### VARIANT 2 of 2: morning_d5 #1
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Clear as glass. Spring low today, the lowest water of the winter. The south reef will uncover.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Then I'll take a look.
> - Clara replies: Watch the clock. Keep between the poles.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Is there a reason you keep warning me?
> - Clara replies: Habit.

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

<!-- END morning_d5 #1 -->

---

## ITEM: react_south_reef_first

### VARIANT 1 of 1: react_south_reef_first #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** The reef. I've never seen it dry. You've got an hour at best, Arthur. One hour. I'm holding you to the table.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_south_reef_first #0 -->

---

## ITEM: react_reef_closing

### VARIANT 1 of 1: react_reef_closing #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Arthur. The water's turned. Off the reef. Now.

**OWNER DRAFT**
```text
LINE:
```

**WRITER DRAFT**
```text
LINE:
```

<!-- END react_reef_closing #0 -->

---

## ITEM: vault
**Note:** Played at the south reef vault. SECRET: Clara cannot bring herself to go down there.

### VARIANT 1 of 1: vault #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** The reef is open? I can hear the water around you. What's down there?
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets reported_vault)
> - Arthur says: A cable vault. Salt-crusted hatch, and a field recorder wedged behind the ladder. Initials: J.H.
> - Clara replies: ...Bring it up. Please. Then get off the reef.
>
> **ARTHUR option 2** (LOCKED effects: trust -2; sets withheld_vault)
> - Arthur says: Nothing. Just flooded concrete.
> - Clara replies: Then come home.

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

<!-- END vault #0 -->

---

## ITEM: evening_d5

### VARIANT 1 of 3: evening_d5 #0
- **Plays when (LOCKED):** has:tape_2 AND flag:reported_vault
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You brought it up. Thank you, Arthur. I couldn't have gone down there.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Whose voice is on it?
> - Clara replies: ...Play it tonight. Then I'll answer anything you ask.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: June was careful. Everything I've heard says so.
> - Clara replies: No. She wasn't careless.

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

<!-- END evening_d5 #0 -->

### VARIANT 2 of 3: evening_d5 #1
- **Plays when (LOCKED):** has:tape_2 AND flag:withheld_vault
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You were on the reef longer than the table allowed. What did you find?
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets reported_vault; clears withheld_vault)
> - Arthur says: A recorder. A cassette, initials J.H. I'm sorry I said nothing.
> - Clara replies: Thank you for telling me now.
>
> **ARTHUR option 2** (LOCKED effects: trust -2)
> - Arthur says: Nothing, Clara.
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

<!-- END evening_d5 #1 -->

### VARIANT 3 of 3: evening_d5 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** You didn't make the reef today? That low won't come again this winter.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: I'll try tomorrow.
> - Clara replies: It will be gone by then.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: It wasn't worth the risk.
> - Clara replies: Maybe not.

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

<!-- END evening_d5 #2 -->
