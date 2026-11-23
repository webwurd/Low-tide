# Narrative outline (canon: the tape text in `dialogue/dialogue.json` wins over this summary)

## Truth timeline
- **1974, Project Pelagic**: a Navy + university hydrophone array run from Gannet Rock. Keeper **Walt Haskell** hosts; his wife **June Haskell**, an acoustician, services the cable splices.
- **4 Nov 1974**: June goes to splice 2 in the south reef cable vault. **Lt. Hayes** says the Navy schedule gives two hours of low water; the tide table (and Coast Guard boatswain **Tom Dunmore**, Clara's father) say one. Tom waits offshore with his engine running and watches the water come over the bar. June does not come out. Her field recorder stays in the vault. The Navy report says "lost at sea, weather" and that June was never on the manifest.
- **1976-1979**: Walt records cassette letters to June (tapes 1, 3, 4). In 1977 the Navy offers a settlement with a non-disclosure line; he refuses. In March 1979 he leaves the rock, leaving his tapes in the lantern-room locker "for whoever's next", and names June's sister **Ruth Whitcomb** (Wickenden Street, Providence) as the person who should have them.
- **After**: Tom Dunmore stops going out and leaves a boat-log cassette in a biscuit tin at the cove hut (tape 5). His daughter **Clara** becomes a Coast Guard dispatcher and, for years, quietly services the west cave buoy's battery (tape 6): its hydrophone hears a ping every 14 seconds from the reef. She tells herself it is June's recorder. It is the splice transponder. Grief, not fact.
- **1998 (the game)**: **Arthur**, a recently widowed schoolteacher (his wife, **Maren**, died in the autumn), takes the winter post alone. The only voice he speaks to is Clara's, on channel 16 from **Station Penobscot** (fictional).

## The seven days
| Day | Weather | Beats |
|---|---|---|
| 1 First Watch | Fog | Rituals; east bar; canister (report / withhold) |
| 2 Grey Water | Overcast | West cave; warm buoy; tape 1 (Walt, 1976); first honesty test about the tape |
| 3 Wool | Dense fog | Bell buoys; north cove cable; tape 3 under the floorboard (Walt, 1977; the Navy's offer; Ruth) |
| 4 The Blow | Storm | Indoor day; tape 4 in the lantern locker (Walt, last); Clara's midday call; "My father worked the Pelagic boats"; Arthur's wife |
| 5 Spring Low | Clear | South causeway opens (about 2 hours); vault; tape 2 (June, 1974) |
| 6 Frost | Cold, clear | Cove tin (tape 5: Tom's log) and buoy service hatch (tape 6: Clara); the confrontation in three trust tiers |
| 7 Last Light | Still | The final decision and dawn |

## Trust and the three endings
Trust is a hidden integer moved by honest answers (+) and withholds/lies (-). Over the week it spans roughly **-16 (every withhold) to +23 (every honest answer)**.
- **Day 6 evening confrontation** (by trust at that point): **>= 12** Clara tells everything (`clara_admitted`); **>= 3** she tells some (`clara_partial`); below that she stonewalls (`clara_stonewalled`), unless Arthur holds her own tape (tape 6), which gets him the partial route.
- **Day 7 final choice**: `clara_admitted` offers **A** (send the tapes to Ruth Whitcomb) and **B** (let the buoy die, keep it between us). Otherwise **A** and **C** (report Clara).
- **A, THE RIGHT ADDRESS** / **B, LEFT QUIET**: dawn on the pier; the relief boat's light seen through the binoculars. **C, ON THE RECORD**: the beam and static.
- A reproducible simulation of the whole week (honest / dishonest / two mixed policies) is part of `tests/run_tests.gd`. Re-run it after changing any trust value or threshold.

## Writing status
Placeholder-quality: Day 1-2 convs were drafted in M4 and have been extended; Days 3-7, tapes 3-6 and all endings were drafted in M6. Everything is editable text in `dialogue/dialogue.json`. A polish/read-aloud pass is expected before release.
