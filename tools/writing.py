#!/usr/bin/env python3
"""Writer's workspace for Low Tide.

  python3 tools/writing.py export   # create docs/writing/*.md (never overwrites an existing file)
  python3 tools/writing.py import   # fold OWNER and WRITER drafts back into dialogue/dialogue.json
  python3 tools/writing.py status   # print what is AI / owner / writer, per item

Precedence per field: WRITER draft > OWNER draft > AI draft (whatever is in dialogue.json).
The game data stays in dialogue/dialogue.json; docs/writing/status.json records who wrote what.
"""
import json, os, re, sys, subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DLG = os.path.join(ROOT, 'dialogue', 'dialogue.json')
WDIR = os.path.join(ROOT, 'docs', 'writing')
STATUS = os.path.join(WDIR, 'status.json')

# ---------------------------------------------------------------- briefs
TAPES = {
 'tape_1': dict(
  found="Day 2. Taped inside the hatch of the warm acoustic buoy, west echo cave. The player plays it on the cottage cassette player.",
  who="Walt Haskell, keeper, speaking to his dead wife June. January 1976, about 14 months after she died.",
  facts=[
   "Addressed to June. The word 'June' must appear (a test checks for it).",
   "Recorded at the buoy; he leaves the tape in the hatch.",
   "The Navy's letter says June was never on the manifest and no cable work was scheduled. That is a lie. Walt does not believe it.",
   "The Navy has left. The buoy is still warm, though they said it would die.",
   "The buoy hears a ping from the reef every 14 seconds. The Navy says it is a 'test tone'.",
   "Walt is not a talker. He is tender, wry and embarrassed to be talking to a machine."]),
 'tape_2': dict(
  found="Day 5. A field recorder wedged behind the ladder in the south reef cable vault, initials J.H.",
  who="June Haskell, acoustician, on the morning she died. 4 November 1974. Her only voice in the game.",
  facts=[
   "Recorded in the vault, at splice number 2, which has been dropping signal for a week.",
   "The tide table gives her one hour of low water. The Navy schedule gives two. She goes with the table.",
   "The water comes earlier than the table said.",
   "'Tell Walt, the left pocket. He'll know.' (This must stay unexplained by June.)",
   "The tape ends with the hatch clanging and static. Her death is NOT on the tape.",
   "She is brisk, dry and professional. She is not frightened on tape."]),
 'tape_3': dict(
  found="Day 3. Under a loose floorboard beneath the bed in the keeper's cottage.",
  who="Walt, October 1977, about three years after June died.",
  facts=[
   "A Navy commander visits with a settlement: a pension, a letter of regret, and a line about not discussing the matter.",
   "Walt asks what he'd be not discussing. The commander says 'the schedule'. This is how Walt learns there was a Navy schedule.",
   "The commander says Tom Dunmore (who ferried June out) was mistaken. Tom said one hour.",
   "Walt does not sign.",
   "June's sister Ruth writes to him. The name 'Ruth' must appear (a test checks for it).",
   "Walt has not answered Ruth yet."]),
 'tape_4': dict(
  found="Day 4 (the storm). In the lantern-room locker. The player has been stuck indoors all day.",
  who="Walt, March 1979, the night before he leaves the rock for good. He is addressing whoever comes next.",
  facts=[
   "Addressed to the next keeper, not to June.",
   "Lamp advice (a light tutorial wink): wind the weights before coffee.",
   "He has left tapes. Listen in order.",
   "June's sister: Ruth Whitcomb, Wickenden Street, Providence. 'Wickenden' must appear (a test checks for it). If the next keeper can, he should take the tapes to her.",
   "Tom Dunmore left a tin in the cove hut years ago. Walt never played it.",
   "The buoy in the cave is still ticking. He doesn't know who feeds it. 'Leave it be. Maybe someone needs it more than I did.'"]),
 'tape_5': dict(
  found="Day 6. A biscuit tin on a crate in the north cove hut. Only opens after Walt's last tape has been heard.",
  who="Boatswain Tom Dunmore, Coast Guard, Clara's father. A boat log, dictated on 4 November 1974.",
  facts=[
   "Landed the Pelagic party at the south reef causeway at about 05:40: Mrs. Haskell, one technician, Lieutenant Hayes.",
   "Tom said the tide table gave one hour. Hayes said the Navy's schedule gave two.",
   "The technician came off the reef at about 06:50. Mrs. Haskell stayed to finish the splice.",
   "At about 07:10 the water comes over the bar. Tom is offshore with the engine running and cannot get in.",
   "'This isn't going in the report.' Tom says the sentence 'I said one hour.' (A test checks for that exact phrase.)",
   "It is a log: clipped, procedural, with one break."]),
 'tape_6': dict(
  found="Day 6. Under the service hatch of the west buoy, beside a fresh Coast Guard-issue battery. Day 6 is also the day Clara is confronted.",
  who="Clara, October 1997, speaking to her dead father, Tom. She is alone in the cave, servicing the buoy.",
  facts=[
   "Addressed to her father: the word 'Dad' must appear (a test checks for it).",
   "She has swapped the battery. It is good for another winter.",
   "The hydrophone picks up a ping every 14 seconds from the reef. She tells herself it is June's recorder. It is not; the recorder is dead. It is the splice transponder.",
   "'If I stop listening, then nobody is. Somebody has to be listening.'",
   "She is not on the radio here. This is the only time we hear her without her dispatcher's voice."]),
}

DAYS = {
 1: ("First Watch", "Fog", "Rituals; east bar; the canister (report or withhold). First contact with Clara.",
     "Arthur has just arrived and is still a stranger to Clara. The player is learning the island. Nothing about 1974 is known yet."),
 2: ("Grey Water", "Overcast", "West cave; warm buoy; tape 1 (Walt, 1976); first honesty test about the tape.",
     "The player has found the Pelagic canister (or hidden it). Tape 1 introduces June."),
 3: ("Wool", "Dense fog", "Bell buoys; north cove cable; tape 3 under the floorboard (Walt, 1977; the Navy's offer; Ruth).",
     "Visibility is poor. Clara teaches the bell code (1 north, 2 east, 3 south, 4 west)."),
 4: ("The Blow", "Storm", "Indoor day; tape 4 in the lantern locker; Clara's midday call; 'My father worked the Pelagic boats'; Arthur's wife.",
     "The emotional centre. Trade: Clara tells Arthur about her father; Arthur tells Clara about his wife, Maren. Both reveals should be short and clumsy."),
 5: ("Spring Low", "Clear", "South causeway opens for about two hours; the vault; tape 2 (June, 1974).",
     "The lowest water of the winter. Clara is visibly anxious about the reef."),
 6: ("Frost", "Cold, clear", "Cove tin (tape 5, Tom's log) and buoy service hatch (tape 6, Clara); the confrontation in three trust tiers.",
     "Evening splits by trust: >=12 Clara tells everything; >=3 some; otherwise she stonewalls (unless Arthur holds tape 6, which gets the partial route)."),
 7: ("Last Light", "Still", "The final decision and dawn.",
     "A: send the tapes to Ruth Whitcomb. B: let the buoy die (only if Clara admitted everything). C: report Clara (not offered if she admitted). Relief boat at first light."),
}

CONV_DAY = {
 1: ['morning_d1', 'react_east_bar_first', 'react_west_bar_first', 'shipwreck', 'seacave', 'react_west_withheld', 'evening_d1'],
 2: ['morning_d2', 'evening_d2'],
 3: ['morning_d3', 'react_fog_bells', 'react_north_cove_first', 'cable', 'evening_d3'],
 4: ['morning_d4', 'midday_d4', 'evening_d4', 'd4_why_post'],
 5: ['morning_d5', 'react_south_reef_first', 'react_reef_closing', 'vault', 'evening_d5'],
 6: ['morning_d6', 'evening_d6'],
 7: ['morning_d7', 'evening_d7', 'end_a_high', 'end_a_mid', 'end_a_low', 'end_b', 'end_c',
     'ending_a_radio', 'ending_b_radio', 'ending_c_radio'],
}
GENERAL = ['react_bar_rising', 'react_bar_closing', 'react_cottage_curious', 'lighthouse', 'cottage',
           'sandbar_warning', 'swept', 'dusk_nudge', 'forced_home']

CONV_NOTES = {
 'morning_d1': "First ever radio call. Radio check; Clara is still in procedural mode.",
 'react_east_bar_first': "Fires automatically the first time Arthur steps on the east bar.",
 'react_west_bar_first': "Fires the first time Arthur steps on the west bar.",
 'shipwreck': "Played when Arthur reaches the east stack wreck. Option 1 reports the canister; option 2 withholds it.",
 'seacave': "Played at the west echo cave. Option 1 reports the warm buoy; option 2 withholds it. SECRET: Clara services this buoy herself.",
 'react_west_withheld': "A prompt if Arthur is on the west stack having withheld the canister.",
 'evening_d1': "Three variants: reported canister / withheld canister / nothing found.",
 'morning_d2': "Three variants: trusting / withheld the canister / neutral.",
 'evening_d2': "Three variants: has heard tape 1 / has the tape but hasn't played it / nothing.",
 'cable': "Played at the north cove cable. SECRET: Clara knows about the splice already.",
 'vault': "Played at the south reef vault. SECRET: Clara cannot bring herself to go down there.",
 'evening_d4': "Three variants by trust (>=6, >=1, otherwise). The trade of reveals happens here, with d4_why_post.",
 'd4_why_post': "Clara asks why Arthur took the post. Option 1 gives Maren's death.",
 'evening_d6': "THE CONFRONTATION. Three variants by trust tier. Most important dialogue in the game.",
 'evening_d7': "The final choice. Option text sets which ending plays (A/B/C). Do not change what each option MEANS.",
 'end_a_high': "Clara's last line if ending A and trust is high.",
 'end_b': "Clara's last line, ending B: 'Left Quiet'.",
 'end_c': "Clara's last line, ending C: 'On the Record'.",
 'ending_a_radio': "Heard over the radio as the relief boat arrives.",
 'ending_b_radio': "Heard over the radio as the relief boat arrives, after the buoy has gone quiet.",
 'ending_c_radio': "Arthur's own line: no one answers on sixteen.",
}

# ---------------------------------------------------------------- helpers
LEGEND = """\
> **How to use this file**
> - **AI DRAFT** is reference only. Do not edit it. It is here so you can see what the current game text says. The current wording is a placeholder written by an AI, and a human writer is welcome to throw it away.
> - **OWNER DRAFT** is for the project owner's rough words and ideas. It is not final. The writer should treat it as the owner's intent.
> - **WRITER DRAFT** is for the professional writer. If it is filled in, it wins.
> - Leave any field blank to keep the level below it. Fill in only what you want to change.
> - Do not change anything marked **LOCKED**. The game code depends on it.
"""

def load():
    return json.load(open(DLG))

def save(d):
    open(DLG, 'w').write(json.dumps(d, indent=1))

def load_status():
    if os.path.exists(STATUS):
        return json.load(open(STATUS))
    return {}

def save_status(s):
    os.makedirs(WDIR, exist_ok=True)
    open(STATUS, 'w').write(json.dumps(s, indent=1, sort_keys=True) + '\n')

def cond_text(w):
    return 'always (fallback)' if not w else ' AND '.join(w)

def tape_timing(lines):
    """lines: list of (text, explicit_gap|None) -> [{'t','text'}]"""
    out, t = [], 0.0
    for text, gap in lines:
        out.append({'t': int(round(t)), 'text': text})
        if gap is None:
            gap = 3.5 if (text.startswith('[') and text.endswith(']')) else max(3.0, len(text) / 14.0 + 1.0)
        t += gap
    return out

# ---------------------------------------------------------------- export
def tape_md(tid, tape):
    b = TAPES[tid]
    lines = '\n'.join(l['text'] for l in tape['lines'])
    facts = '\n'.join('- ' + f for f in b['facts'])
    return f"""# {tape['title']}

{LEGEND}
**Where the player finds it:** {b['found']}
**Who is speaking:** {b['who']}

## LOCKED: facts the story needs
{facts}

Everything not on this list is up to the writer: wording, rhythm, order, small details, jokes, what is left unsaid.

## ID: {tid}

### AI DRAFT (reference only)
```text
{lines}
```

### OWNER DRAFT
Format: one subtitle line per line. Stage directions in [square brackets]. Optional: end a line with `{{6}}` to wait 6 seconds before the next line. First line may be `TITLE: ...` to rename.
```text

```

### WRITER DRAFT
```text

```
"""

def conv_md_item(cid, variants):
    out = [f"## ITEM: {cid}"]
    if cid in CONV_NOTES:
        out.append(f"**Note:** {CONV_NOTES[cid]}")
    for vi, v in enumerate(variants):
        out.append(f"\n### VARIANT {vi + 1} of {len(variants)}: {cid} #{vi}")
        out.append(f"- **Plays when (LOCKED):** {cond_text(v.get('when', []))}")
        out.append(f"- **Opens with:** {v['speaker'].capitalize()}")
        opts = v.get('options', [])
        out.append("\n**AI DRAFT (reference only)**\n")
        out.append(f"> **{v['speaker'].upper()}:** {v['text']}")
        for oi, o in enumerate(opts):
            mech = [f"trust {o.get('trust', 0):+d}"]
            if o.get('set'): mech.append('sets ' + ', '.join(o['set']))
            if o.get('clear'): mech.append('clears ' + ', '.join(o['clear']))
            if o.get('next'): mech.append('then plays ' + o['next'])
            if o.get('when'): mech.append('shown only if ' + ', '.join(o['when']))
            out.append(f">\n> **ARTHUR option {oi + 1}** (LOCKED effects: {'; '.join(mech)})")
            out.append(f"> - Arthur says: {o['text']}")
            out.append(f"> - Clara replies: {o['reply']}")
        keys = ['LINE:']
        for oi in range(len(opts)):
            keys += [f'ARTHUR_{oi + 1}:', f'CLARA_REPLY_{oi + 1}:']
        blank = '\n'.join(keys)
        out.append(f"\n**OWNER DRAFT**\n```text\n{blank}\n```")
        out.append(f"\n**WRITER DRAFT**\n```text\n{blank}\n```")
        out.append(f"\n<!-- END {cid} #{vi} -->")
    return '\n'.join(out)

def conv_file(title, intro, ids, d):
    body = '\n\n---\n\n'.join(conv_md_item(c, d['convs'][c]) for c in ids)
    return f"# {title}\n\n{LEGEND}\n{intro}\n\n---\n\n{body}\n"

def export(force=False):
    d = load()
    os.makedirs(os.path.join(WDIR, 'tapes'), exist_ok=True)
    os.makedirs(os.path.join(WDIR, 'radio'), exist_ok=True)
    made = []
    def write(path, text):
        if os.path.exists(path) and not force:
            return
        open(path, 'w').write(text)
        made.append(os.path.relpath(path, ROOT))
    for tid, tape in d['tapes'].items():
        write(os.path.join(WDIR, 'tapes', tid + '.md'), tape_md(tid, tape))
    seen = set()
    for day, ids in CONV_DAY.items():
        title, weather, beats, know = DAYS[day]
        intro = (f"**Day {day}: {title}** ({weather})\n\n**Beats:** {beats}\n\n**Where the story is:** {know}\n\n"
                 f"**Voices:** see `docs/characters.md` for Arthur and Clara.")
        write(os.path.join(WDIR, 'radio', f'day_{day}.md'), conv_file(f'Radio, Day {day}: {title}', intro, ids, d))
        seen.update(ids)
    write(os.path.join(WDIR, 'radio', 'general.md'),
          conv_file('Radio: general chatter', "Short lines that fire at any time on any day (weather, tide, location). They are the texture of the voice, so keep them small and human.", GENERAL, d))
    seen.update(GENERAL)
    missing = set(d['convs']) - seen
    if missing:
        print('WARNING: conversations not assigned to any file:', sorted(missing))
    print('created:' if made else 'nothing new to create (existing files are never overwritten).')
    for m in made: print('  ', m)

# ---------------------------------------------------------------- import
def fence(block):
    """Text of the first ```text fence in block, with comments stripped."""
    m = re.search(r"```text\n(.*?)\n?```", block, re.S)
    return m.group(1) if m else ''

def parse_keys(txt):
    keys, cur = {}, None
    for line in txt.split('\n'):
        m = re.match(r'^(LINE|ARTHUR_\d|CLARA_REPLY_\d):\s?(.*)$', line)
        if m:
            cur = m.group(1); keys[cur] = m.group(2).strip()
        elif cur and line.strip():
            keys[cur] += ' ' + line.strip()
    return {k: v for k, v in keys.items() if v}

def parse_tape_draft(txt):
    title, lines = None, []
    for raw in txt.split('\n'):
        s = raw.strip()
        if not s: continue
        if s.upper().startswith('TITLE:'):
            title = s[6:].strip(); continue
        gap = None
        m = re.search(r'\{(\d+(?:\.\d+)?)\}\s*$', s)
        if m:
            gap = float(m.group(1)); s = s[:m.start()].rstrip()
        lines.append((s, gap))
    return title, lines

def import_all():
    d = load(); st = load_status(); changed = 0
    # tapes
    for tid in list(d['tapes']):
        p = os.path.join(WDIR, 'tapes', tid + '.md')
        if not os.path.exists(p): continue
        txt = open(p).read()
        owner = re.search(r"### OWNER DRAFT(.*?)### WRITER DRAFT", txt, re.S)
        writer = re.search(r"### WRITER DRAFT(.*)$", txt, re.S)
        for who, m in (('owner', owner), ('writer', writer)):
            if not m: continue
            title, lines = parse_tape_draft(fence(m.group(1)))
            if lines:
                d['tapes'][tid]['lines'] = tape_timing(lines)
                if title: d['tapes'][tid]['title'] = title
                st[tid] = who; changed += 1
    # conversations
    for fn in sorted(os.listdir(os.path.join(WDIR, 'radio'))) if os.path.isdir(os.path.join(WDIR, 'radio')) else []:
        if not fn.endswith('.md'): continue
        txt = open(os.path.join(WDIR, 'radio', fn)).read()
        for m in re.finditer(r"### VARIANT \d+ of \d+: (\S+) #(\d+)(.*?)<!-- END \S+ #\d+ -->", txt, re.S):
            cid, vi, body = m.group(1), int(m.group(2)), m.group(3)
            if cid not in d['convs']: continue
            v = d['convs'][cid][vi]
            parts = re.split(r"\*\*OWNER DRAFT\*\*|\*\*WRITER DRAFT\*\*", body)
            if len(parts) < 3: continue
            owner, writer = parse_keys(fence(parts[1])), parse_keys(fence(parts[2]))
            level = None
            for who, keys in (('owner', owner), ('writer', writer)):
                for k, val in keys.items():
                    if k == 'LINE': v['text'] = val
                    else:
                        n = int(k[-1]) - 1
                        if n >= len(v.get('options', [])): continue
                        v['options'][n]['text' if k.startswith('ARTHUR') else 'reply'] = val
                    level = who; changed += 1
            if level: st[f'{cid}#{vi}'] = level
    save(d); save_status(st)
    subprocess.run(['bash', os.path.join(ROOT, 'tools', 'sync_unity_data.sh')], check=True)
    print(f'applied {changed} field(s) from owner/writer drafts')

def status():
    d = load(); st = load_status()
    rows = [(k, 'ai-draft') for k in d['tapes']] + [(f'{c}#{i}', 'ai-draft') for c, vs in d['convs'].items() for i in range(len(vs))]
    n = {'ai-draft': 0, 'owner': 0, 'writer': 0}
    for k, _ in rows:
        n[st.get(k, 'ai-draft')] += 1
    print('items by author:', n)
    for k, _ in rows:
        s = st.get(k, 'ai-draft')
        if s != 'ai-draft': print(f'  {s:7} {k}')

if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else ''
    if cmd == 'export': export('--force' in sys.argv)
    elif cmd == 'import': import_all()
    elif cmd == 'status': status()
    else: print(__doc__)
