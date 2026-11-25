# Radio, Day 6: Frost

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 6: Frost** (Cold, clear)

**Beats:** Cove tin (tape 5, Tom's log) and buoy service hatch (tape 6, Clara); the confrontation in three trust tiers.

**Where the story is:** Evening splits by trust: >=12 Clara tells everything; >=3 some; otherwise she stonewalls (unless Arthur holds tape 6, which gets the partial route).

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d6

### VARIANT 1 of 3: morning_d6 #0
- **Plays when (LOCKED):** trust>=12
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Cold one. Arthur, I owe you a straight conversation. Tonight, when the lamp's lit. I wanted you to hear it from me first, so you'd know I mean it.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: I'll be listening.
> - Clara replies: Good.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: I think I already know.
> - Clara replies: Then you know why it's hard.

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

<!-- END morning_d6 #0 -->

### VARIANT 2 of 3: morning_d6 #1
- **Plays when (LOCKED):** trust>=3
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Cold one. I'll try to answer what you ask tonight. I can't promise more than that.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: That's enough.
> - Clara replies: ...Thank you.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: I'd like more than trying.
> - Clara replies: I know you would.

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

<!-- END morning_d6 #1 -->

### VARIANT 3 of 3: morning_d6 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Cold. Don't expect much of me tonight. You've given me reasons not to.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: I know. I'm sorry.
> - Clara replies: ...Mm.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: You've given me reasons too.
> - Clara replies: Fair.

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

<!-- END morning_d6 #2 -->

---

## ITEM: evening_d6
**Note:** THE CONFRONTATION. Three variants by trust tier. Most important dialogue in the game.

### VARIANT 1 of 3: evening_d6 #0
- **Plays when (LOCKED):** trust>=12
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** All right. My father piloted the boat that took June Haskell to the reef. He told the Navy the table said one hour. They said two. He held off the bar with his engine running and watched the water come over it. I've kept that buoy alive ever since. I tell myself the ping is her recorder.
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets clara_admitted)
> - Arthur says: That was never duty, Clara. That's grief. I know it when I see it.
> - Clara replies: ...Yes. It is.
>
> **ARTHUR option 2** (LOCKED effects: trust +0; sets clara_admitted)
> - Arthur says: You could have told me on day one.
> - Clara replies: I know. I couldn't. I didn't know you yet.

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

<!-- END evening_d6 #0 -->

### VARIANT 2 of 3: evening_d6 #1
- **Plays when (LOCKED):** trust>=3
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** I can tell you some of it. My father was on the boats. There was an accident in '74 and the Navy buried it. I keep the buoy running because... I can't stop. That's as far as I can go tonight.
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets clara_partial)
> - Arthur says: Who was June, Clara?
> - Clara replies: ...June Haskell. Walt's wife. Read the tapes. You'll hear the rest.
>
> **ARTHUR option 2** (LOCKED effects: trust +0; sets clara_partial)
> - Arthur says: That's not the whole story.
> - Clara replies: No. It isn't.

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

<!-- END evening_d6 #1 -->

### VARIANT 3 of 3: evening_d6 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** I don't have anything to say tonight, Arthur. You've kept things from me. I'll keep a few from you.
>
> **ARTHUR option 1** (LOCKED effects: trust +1; sets clara_partial; shown only if has:tape_6)
> - Arthur says: I found your tape in the west buoy, Clara. Your voice. I've heard it.
> - Clara replies: ...That wasn't yours to find. Fine. My father piloted the boat. That's all I'll say.
>
> **ARTHUR option 2** (LOCKED effects: trust -1; sets clara_stonewalled)
> - Arthur says: Then we're done talking tonight.
> - Clara replies: Goodnight.

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

<!-- END evening_d6 #2 -->
