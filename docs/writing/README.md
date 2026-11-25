# Writing workspace

This folder is where the game's words get written. It is built for three kinds of author, and every piece of text shows which one wrote it.

| Label | Who | Role |
|---|---|---|
| **AI DRAFT** | An AI | The current placeholder text in the game. Reference only. It is the weakest layer and is expected to be replaced. |
| **OWNER DRAFT** | The project owner | Rough words, intent and ideas. Not final. A professional writer should treat it as "this is what I mean." |
| **WRITER DRAFT** | The professional writer | The real text. If it is filled in, it wins. |

**Precedence, field by field:** WRITER > OWNER > AI. Leave a field blank to keep the layer below.

## What's here
- `tapes/tape_1.md` ... `tape_6.md`: the six cassette tapes, one file each.
- `radio/day_1.md` ... `day_7.md`: every radio conversation, grouped by the day it plays.
- `radio/general.md`: short lines that can fire on any day.
- `ai_inventions.md`: details the AI added that were NOT in the original design. The writer can keep or drop any of them.
- `status.json`: who wrote what (maintained by the tool; do not edit).

Not yet covered by the tool: the **ending epilogues** (`story/endings.gd`) and the **logbook lines** (`story/log_entries.gd`). Those are plain text inside code files. Write them in a new file under this folder, then a developer moves them in.

Also useful: `docs/characters.md` (voices of Arthur and Clara), `docs/narrative_outline.md` (the truth timeline and the endings), `docs/design_bible.md` (tone).

## How to write
1. Open a file. Read the **LOCKED** facts at the top. Those must survive; everything else is yours.
2. Read the AI DRAFT to see what's there now, or ignore it.
3. Write in **OWNER DRAFT** if you are the owner, or **WRITER DRAFT** if you are the writer. Use the layout shown in the file:
   - **Tapes:** one subtitle line per line. Stage directions in `[square brackets]`. End a line with `{6}` to leave a 6-second silence after it. First line `TITLE: ...` renames the tape.
   - **Radio:** fill in `LINE:` (what the speaker says first), then `ARTHUR_1:` / `CLARA_REPLY_1:` and `ARTHUR_2:` / `CLARA_REPLY_2:` (what Arthur may answer and how Clara responds). Fill in only the keys you want to change.
4. Do **not** edit anything labelled LOCKED, the AI DRAFT, or the HTML comments. The tool relies on them.
5. Read your lines aloud. If you stumble, the player will.

## How a draft reaches the game
```bash
python3 tools/writing.py status    # who wrote what
python3 tools/writing.py import    # apply owner/writer drafts to dialogue/dialogue.json and sync the Unity copy
```
`import` can be run any number of times. `export` only creates files that do not exist yet; it never overwrites your writing.

## Rules about length (so lines fit the game)
- A radio line should usually be one to three short sentences. The channel is shared and half-public.
- Each radio exchange has at most two Arthur options.
- A tape subtitle line should stay under about 190 characters. Break longer thoughts across lines.
- The tape player runs about 14 characters per second.
