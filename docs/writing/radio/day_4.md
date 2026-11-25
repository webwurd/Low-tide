# Radio, Day 4: The Blow

> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.

**Day 4: The Blow** (Storm)

**Beats:** Indoor day; tape 4 in the lantern locker; Clara's midday call; 'My father worked the Pelagic boats'; Arthur's wife.

**Where the story is:** The emotional centre. Trade: Clara tells Arthur about her father; Arthur tells Clara about his wife, Maren. Both reveals should be short and clumsy.

**Voices:** see `docs/characters.md` for Arthur and Clara.

---

## ITEM: morning_d4

### VARIANT 1 of 2: morning_d4 #0
- **Plays when (LOCKED):** trust>=4
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Gale warning's up, Arthur, and the bars are done for the day. Stay by the stove. I'll be on sixteen all day. Company's allowed.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Then I'll take the company.
> - Clara replies: Good. I'll call you at noon.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: I could still check the tower.
> - Clara replies: On the summit, in daylight, with a rope. Not otherwise.

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

<!-- END morning_d4 #0 -->

### VARIANT 2 of 2: morning_d4 #1
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Gale warning's up. Bars are done for the day. Stay near the stove and keep the lamp trimmed.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Understood. I'll sit tight.
> - Clara replies: Good.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: I could still check the tower.
> - Clara replies: On the summit, in daylight, with a rope. Not otherwise.

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

<!-- END morning_d4 #1 -->

---

## ITEM: midday_d4

### VARIANT 1 of 1: midday_d4 #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Arthur, you still with me? Line's crackling. Anyone else would be climbing the walls by now.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Snug. Lamp's trimmed, stove's roaring. Have you eaten?
> - Clara replies: ...Toast. Don't say it.
>
> **ARTHUR option 2** (LOCKED effects: trust +1)
> - Arthur says: It's too quiet in here. Tell me something. Anything.
> - Clara replies: ...All right. Ask me anything. I'm not going anywhere in this weather either.

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

<!-- END midday_d4 #0 -->

---

## ITEM: evening_d4
**Note:** Three variants by trust (>=6, >=1, otherwise). The trade of reveals happens here, with d4_why_post.

### VARIANT 1 of 3: evening_d4 #0
- **Plays when (LOCKED):** trust>=6
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Long day. Storms make people talk, don't they? My father worked the Pelagic boats, Arthur. Tom Dunmore. He never said much about 1974. He was about your age that winter.
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets clara_shared_father; then plays d4_why_post)
> - Arthur says: Tell me about him.
> - Clara replies: He'd come home smelling of diesel and salt and sit in the dark with the radio on. After '74 he stopped going out. Said the sea owed him something.
>
> **ARTHUR option 2** (LOCKED effects: trust +1; sets clara_shared_father; then plays d4_why_post)
> - Arthur says: Why are you telling me now?
> - Clara replies: Because it's blowing a gale and I'm tired of carrying it by myself.

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

<!-- END evening_d4 #0 -->

### VARIANT 2 of 3: evening_d4 #1
- **Plays when (LOCKED):** trust>=1
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Long day. Storms make people talk. My father worked the Pelagic boats. That's all I'll say tonight.
>
> **ARTHUR option 1** (LOCKED effects: trust +1)
> - Arthur says: Thank you for telling me.
> - Clara replies: ...Goodnight, Arthur.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: Pelagic. The canister. You knew.
> - Clara replies: Not tonight, Arthur. Please.

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

<!-- END evening_d4 #1 -->

### VARIANT 3 of 3: evening_d4 #2
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** Long day. Get some sleep.
>
> **ARTHUR option 1** (LOCKED effects: trust +0)
> - Arthur says: Goodnight, Clara.
> - Clara replies: Goodnight.
>
> **ARTHUR option 2** (LOCKED effects: trust -1)
> - Arthur says: You're not telling me something.
> - Clara replies: Goodnight, Arthur.

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

<!-- END evening_d4 #2 -->

---

## ITEM: d4_why_post
**Note:** Clara asks why Arthur took the post. Option 1 gives Maren's death.

### VARIANT 1 of 1: d4_why_post #0
- **Plays when (LOCKED):** always (fallback)
- **Opens with:** Clara

**AI DRAFT (reference only)**

> **CLARA:** And you? Nobody takes a winter post at forty-one without a reason.
>
> **ARTHUR option 1** (LOCKED effects: trust +2; sets told_clara_wife)
> - Arthur says: My wife died in the autumn. Maren. I couldn't stay in the house.
> - Clara replies: ...I'm sorry, Arthur. I didn't know. I'm glad you said it.
>
> **ARTHUR option 2** (LOCKED effects: trust +0)
> - Arthur says: I like the quiet.
> - Clara replies: Mm. That's not an answer, but it'll do.

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

<!-- END d4_why_post #0 -->
